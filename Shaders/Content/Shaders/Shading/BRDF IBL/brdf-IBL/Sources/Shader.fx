[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
		float4x4 World			: packoffset(c4); 	[World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}
	
	cbuffer Parameters : register(b2)
	{
		float3 LightPosition	: packoffset(c0.x); [Default(0,0,1)]
		float ambientFactor 	: packoffset(c0.w); [Default(0.02)]
		float Metallic			: packoffset(c1.x);
		float Roughness			: packoffset(c1.y);
		float Reflectance		: packoffset(c1.z); [Default(0.3)]
		float irradiPerp 		: packoffset(c1.w); [Default(10)]
		float mipCount			: packoffset(c2.x); [Default(6)]
	};

	Texture2D BaseTexture				: register(t0);
	Texture2D MetalRoughnessTexture		: register(t1);
	Texture2D NormalTexture				: register(t2);
	Texture2D EmissiveTexture			: register(t3);
	Texture2D RadianceTexture			: register(t4); // Generated with cmftStudio
	Texture2D IrradianceTexture			: register(t5); // Generated with cmftStudio
	Texture2D BRDFIntegrationTexture	: register(t6);
	SamplerState TextureSampler			: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define PI 3.14159265359f
	#define RECIPROCAL_PI2 0.15915494f
	
	struct VS_IN
	{
		float4 Position : POSITION;
		float3 Normal	: NORMAL;
		float2 TexCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 pos : SV_POSITION;
		float3 Nor	: NORMAL;
		float2 Tex : TEXCOORD0;
		float3 posw : TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.pos = mul(input.Position, WorldViewProj);
		
		output.posw = mul(input.Position, World).xyz;
		output.Nor = input.Normal;
		output.Tex = input.TexCoord;

		return output;
	}

	float2 DirectionToEquirectangular(float3 dir)
	{
		float lon = atan2(dir.z, dir.x);
		float lat = acos(dir.y);
		float2 sphereCoords = float2(lon, lat) * RECIPROCAL_PI2 * 2.0;
		float s = sphereCoords.x * 0.5 + 0.5;
		float t = sphereCoords.y;
		
		return float2(s, t);
	}
	
	// https://cdn2.unrealengine.com/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
	float3 SpecularIBL(float3 F0 , float roughness, float3 N, float3 V)
	{
		float NoV = clamp(dot(N, V), 0.0, 1.0);
		float3 R = reflect(-V, N);
		float2 uv = DirectionToEquirectangular(R);
		float3 prefilteredColor = RadianceTexture.SampleLevel(TextureSampler, uv, roughness*float(mipCount)).rgb; 
		float4 brdfIntegration = BRDFIntegrationTexture.Sample(TextureSampler, float2(NoV, roughness));
		return prefilteredColor * ( F0 * brdfIntegration.x + brdfIntegration.y );
	}

	float3 DiffuseIBL(float3 normal)
	{
		float2 uv = DirectionToEquirectangular(normal);
		return IrradianceTexture.Sample(TextureSampler, uv).rgb;
	}
	
	float3 fresnelSchlick(float cosTheta, float3 F0)
	{
  		return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
	} 
	
	float3 BRDFIBL(in float3 L, in float3 V, in float3 N, 
              in float3 baseColor, in float metallicness, in float roughness, in float fresnelReflect) 
  	{
		// F0 for dielectics in range [0.0, 0.16] 
		// default FO is (0.16 * 0.5^2) = 0.04
		float3 f0 = 0.16 * (fresnelReflect * fresnelReflect); 
		// in case of metals, baseColor contains F0
		f0 = lerp(f0, baseColor, metallicness);
		
		// compute diffuse and specular factors
		float NoV = clamp(dot(N, V), 0.0, 1.0);
		float3 F = fresnelSchlick(NoV, f0);
		float3 kS = F;
		float3 kD = 1.0 - kS;
		kD *= 1.0 - Metallic;
		
		float3 specular = SpecularIBL(f0, roughness, N, V); 
    	float3 diffuse = DiffuseIBL(N);
    
		// diffuse
		float3 color = kD * baseColor * diffuse + specular;
		
		return float4(color, 1.0);
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 base = BaseTexture.Sample(TextureSampler, input.Tex).rgb;		
		float2 mrTexture = MetalRoughnessTexture.Sample(TextureSampler, input.Tex).xy;
		float3 emission = EmissiveTexture.Sample(TextureSampler, input.Tex).rgb;
		
		float3 viewDir = normalize(CameraPosition - input.posw);
		float3 lightDir = normalize(LightPosition - input.posw);
		float3 normal = normalize(input.Nor);
		float roughness = Roughness; //mrTexture.x;
		float metallic = Metallic; //mrTexture.y;
		float reflectance = Reflectance;
		
		float3 radiance = base * ambientFactor + emission;		
		float irradiance = max(dot(lightDir, normal), 0.0) * irradiPerp;
		if(irradiance > 0.0) // if receives light
		{
			float3 brdf = BRDFIBL(lightDir, viewDir, normal, base, metallic, roughness, reflectance);
			radiance += brdf * irradiance;
		}
		
		return float4(radiance, 1.0);
	}

[End_Pass]