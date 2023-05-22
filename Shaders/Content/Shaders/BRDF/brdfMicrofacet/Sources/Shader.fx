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
	};

	Texture2D BaseTexture				: register(t0);
	Texture2D MetalRoughnessTexture		: register(t1);
	Texture2D NormalTexture				: register(t2);
	Texture2D EmissiveTexture			: register(t3);
	SamplerState TextureSampler		: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define PI 3.14159265359f
	
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

	/////////////////////////////////
	// Cook-Torrance microfacet BDRF
	/////////////////////////////////
	float3 fresnelSchlick(float cosTheta, float3 F0)
	{
  		return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
	} 
	
	float D_GGX(float NoH, float roughness)
	{
		float alpha = roughness * roughness;
		float alpha2 = alpha * alpha;
		float NoH2 = NoH * NoH;
		float b = (NoH2 * (alpha2 - 1.0) + 1.0);
		return alpha2 / (PI * b * b);
	}
	
	float G1_GGX_Schlick(float NdotV, float roughness)
	{
		//float r = roughness; // original
		float r = 0.5 + 0.5 * roughness; // Disney remapping
		float k = (r * r) / 2.0;
		float denom = NdotV * (1.0 - k) + k;
		return NdotV / denom;
	}
	
	float G_Smith(float NoV, float NoL, float roughness) 
	{
		float g1_l = G1_GGX_Schlick(NoL, roughness);
		float g1_v = G1_GGX_Schlick(NoV, roughness);
		return g1_l * g1_v;
	}

	float3 brdfMicrofacet(in float3 L, in float3 V, in float3 N, 
              in float3 baseColor, in float metallicness, in float roughness, in float fresnelReflect) 
  	{
		float3 H = normalize(V + L); // half vector
		
		// all required dot products
		float NoV = clamp(dot(N, V), 0.0, 1.0);
		float NoL = clamp(dot(N, L), 0.0, 1.0);
		float NoH = clamp(dot(N, H), 0.0, 1.0);
		float VoH = clamp(dot(V, H), 0.0, 1.0);     
		
		// F0 for dielectics in range [0.0, 0.16] 
		// default FO is (0.16 * 0.5^2) = 0.04
		float3 f0 = 0.16 * (fresnelReflect * fresnelReflect); 
		// in case of metals, baseColor contains F0
		f0 = lerp(f0, baseColor, metallicness);
		
		// specular microfacet (cook-torrance) BRDF
		float3 F = fresnelSchlick(VoH, f0);
		float D = D_GGX(NoH, roughness);
		float G = G_Smith(NoV, NoL, roughness);
		float3 spec = (D * G * F) / max(4.0 * NoV * NoL, 0.001);
		
		// diffuse
		float3 rhoD = 1.0 - F; // if not specular, use as diffuse
		rhoD *= 1.0 - metallicness; // no diffuse for metals
		float3 diff = rhoD * baseColor / PI; 
		
		return diff + spec;
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
			float3 brdf = brdfMicrofacet(lightDir, viewDir, normal, base, metallic, roughness, reflectance);
			radiance += brdf * irradiance;// * lightColor.rgb;
		}
		
		return float4(radiance, 1.0);
	}

[End_Pass]