[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Params : register(b1)
	{		
		float3 AmbientColor 		: packoffset(c0.x); [Default(0.3, 0.3, 0.3)]
		float irradiPerp			: packoffset(c0.w); [Default(4)]
		float3 CameraPosition		: packoffset(c1.x); [CameraPosition]
		float SpecularPower			: packoffset(c1.w); [Default(0.3)]
		float3 lightPosition		: packoffset(c2.x); [Default(0,0,1)]
		float Shininess				: packoffset(c2.w); [Default(32.0)];
	};
	
	Texture2D DiffuseTexture		: register(t0);
	SamplerState TextureSampler		: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
		float2 texCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 normal		: NORMAL0;
		float2 texCoord 	: TEXCOORD0;
		float3 positionWS 		: TEXCOORD1;
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

	float3 BlinnPhongBRDF(float3 lightDir, float3 viewDir, float3 normal, float3 phongDiffuseCol, float3 phongSpecularCol, float phongShininess)
	{
		float3 color = phongDiffuseCol;
		float3 halfDir = normalize(viewDir + lightDir);
		float specDot = max(dot(halfDir, normal), 0.0);
		color += pow(specDot, phongShininess) * phongSpecularCol;
		return color;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 diffuseColor = DiffuseTexture.Sample(TextureSampler, input.texCoord).rgb;
		float3 lightDir = normalize(lightPosition - input.positionWS);
		float3 viewDir = normalize(CameraPosition - input.positionWS);
		float3 normal = normalize(input.normal);
		
    	float3 radiance = AmbientColor;
    	
    	float irradiance = max(dot(lightDir, normal), 0.0) * irradiPerp; // irradiance contribution from light
    	
    	if(irradiance > 0.0) 
    	{
	    	float3 brdf = BlinnPhongBRDF(lightDir, viewDir, normal, diffuseColor, SpecularPower, Shininess);
	    	radiance += brdf * irradiance;//e * lightColor;
    	}

		return float4(radiance, 1.0);
	}

[End_Pass]