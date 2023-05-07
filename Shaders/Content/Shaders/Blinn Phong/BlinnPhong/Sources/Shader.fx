[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Params : register(b1)
	{		
		float3 AmbientColor 		: packoffset(c0.x); [Default(1.0, 1.0, 1.0)]
		float AmbientPower			: packoffset(c0.w); [Default(0.05)]
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
		float4 Position : POSITION;
		float3 Normal	: NORMAL;
		float2 TexCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 pos 		: SV_POSITION;
		float3 Nor		: NORMAL;
		float2 Tex 		: TEXCOORD0;
		float3 fragPos 	: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.pos = mul(input.Position, WorldViewProj);
		output.Nor = mul(float4(input.Normal, 0), World);
		output.Tex = input.TexCoord;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 diffuseTex = DiffuseTexture.Sample(TextureSampler, input.Tex).rgb;
		
		// Ambient
    	float3 ambient = AmbientPower * AmbientColor;
    	
    	// Diffuse
    	float3 lightDir = normalize(lightPosition - input.fragPos);
    	float3 normal = normalize(input.Nor);
    	float diff = max(dot(lightDir, normal), 0.0);
    	float3 diffuse = diff * diffuseTex;
    	
    	// Specular
    	float3 viewDir = normalize(CameraPosition - input.fragPos);
    	float3 halfwayDir = normalize(lightDir + viewDir);
    	float3 specular = pow(max(dot(normal, halfwayDir), 0.0), Shininess) * SpecularPower;
    	
    
		float3 color = ambient + diffuse + specular;
		return float4(color, 1.0);
	}

[End_Pass]