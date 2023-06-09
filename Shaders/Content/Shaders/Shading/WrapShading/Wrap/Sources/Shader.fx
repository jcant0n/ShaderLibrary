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
		float3 LightPosition		: packoffset(c0.x); [Default(0,0,1)]
		float ambientFactor 		: packoffset(c0.w); [Default(0.02)]
		float Metallic				: packoffset(c1.x);
		float Roughness				: packoffset(c1.y);
		float Reflectance			: packoffset(c1.z); [Default(0.3)]
		float irradiPerp 			: packoffset(c1.w); [Default(10)]
		float fLTDistortion			: packoffset(c2.x); [Default(1)]
		float iLTPower				: packoffset(c2.y); [Default(1)]
		float fLTScale				: packoffset(c2.z); [Default(1)]
		float fLTAmbient			: packoffset(c2.w); [Default(0.02)]
		float3 SSColor				: packoffset(c3.x); [Default(0.9, 0.26, 0.23)]
		float SubsurfaceScattering	: packoffset(c3.w); [Default(0.5)]
		float3 baseColor			: packoffset(c4.x); [Default(0.5, 0.19, 0.13)]
		float SubsurfaceRadius		: packoffset(c4.w); [Default(0.25)]
	};

	Texture2D BaseTexture				: register(t0);
	Texture2D MetalRoughnessTexture		: register(t1);
	Texture2D NormalTexture				: register(t2);
	Texture2D EmissiveTexture			: register(t3);
	Texture2D TraslucencyTexture		: register(t4);
	SamplerState TextureSampler			: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define PI 3.14159265359f
	
	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
		float2 texCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 normal		: NORMAL;
		float2 texCoord 	: TEXCOORD0;
		float3 positionWS 	: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		
		output.positionWS = mul(input.position, World).xyz;
		output.normal = mul(float4(input.normal, 0), World).xyz;
		output.texCoord = input.texCoord;

		return output;
	}

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

	// https://johnaustin.io/articles/2020/fast-subsurface-scattering-for-the-unity-urp
	half3 LightingSubsurface(float3 lightDir, half3 normalWS, half3 subsurfaceColor, half subsurfaceRadius)
	{
	    // Calculate normalized wrapped lighting. This spreads the light without adding energy.
	    // This is a normal lambertian lighting calculation (using N dot L), but warping NdotL
	    // to wrap the light further around an object.
	    //
	    // A normalization term is applied to make sure we do not add energy.
	    // http://www.cim.mcgill.ca/~derek/files/jgt_wrap.pdf
	
	    half NdotL = dot(normalWS, lightDir);
	    half alpha = subsurfaceRadius;
	    half theta_m = acos(-alpha); // boundary of the lighting function
	
	    half theta = max(0, NdotL + alpha) - alpha;
	    half normalization_jgt = (2 + alpha) / (2 * (1 + alpha));
	    half wrapped_jgt = (pow(((theta + alpha) / (1 + alpha)), 1 + alpha)) * normalization_jgt;
	
	    half wrapped_valve = 0.25 * (NdotL + 1) * (NdotL + 1);
	    half wrapped_simple = (NdotL + alpha) / (1 + alpha);
	
	    half3 subsurface_radiance = subsurfaceColor * wrapped_jgt;
	
	    return subsurface_radiance;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		//float3 base = BaseTexture.Sample(TextureSampler, input.Tex).rgb;
		float3 base = baseColor;
		float2 mrTexture = MetalRoughnessTexture.Sample(TextureSampler, input.texCoord).xy;
		float3 emission = EmissiveTexture.Sample(TextureSampler, input.texCoord).rgb;
		float fLTThickness = TraslucencyTexture.Sample(TextureSampler, input.texCoord).r;
		
		float3 viewDir = normalize(CameraPosition - input.positionWS);
		float3 lightDir = normalize(LightPosition - input.positionWS);
		float3 normal = normalize(input.normal);
		float roughness = Roughness; //mrTexture.x;
		float metallic = Metallic; //mrTexture.y;
		float reflectance = Reflectance;
		
		float3 radiance = base * ambientFactor + emission;		
		float irradiance = max(dot(lightDir, normal), 0.0) * irradiPerp;
		//if(irradiance > 0.0) // if receives light
		//{
			float3 brdf = brdfMicrofacet(lightDir, viewDir, normal, base, metallic, roughness, reflectance);
			radiance += brdf * irradiance;// * lightColor.rgb;
		//}
		
		float3 subsurfaceContribution = LightingSubsurface(lightDir, normal, SSColor, SubsurfaceRadius);
		radiance = lerp(radiance, subsurfaceContribution, SubsurfaceScattering);

		return float4(radiance, 1.0);
	}

[End_Pass]