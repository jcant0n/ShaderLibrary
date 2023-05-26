[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj		: packoffset(c0); [WorldViewProjection]
		float4x4 World				: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}
	
	cbuffer Parameters : register(b2)
	{
		float3 lightPosition	: packoffset(c0.x); [Default(0,0,1)]
	};

	Texture2D DiffuseTexture		: register(t0);
	Texture2D NormalTexture			: register(t1);
	SamplerState TextureSampler		: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position 	: POSITION;
		float3 normal		: NORMAL0;
		float4 tangent  	: TANGENT0;
		float2 texCoord 	: TEXCOORD;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float2 texCoord 	: TEXCOORD0;
		float3 pixelPos 	: TEXCOORD1;
		float3 viewPos		: TEXCOORD2;
		float3 lightPos		: TEXCOORD3;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		float3 positionWS = mul(input.position, World).xyz;
		
		float3 T = input.tangent;
		float3 N = input.normal;
		float3 B = cross(T, N) * input.tangent.w;
		
		float3x3 tbn = float3x3( normalize(T),
								 normalize(B),
								 normalize(N));
		
		output.pixelPos = mul(positionWS, tbn);
		output.viewPos = mul(CameraPosition, tbn);
		output.lightPos = mul(lightPosition, tbn);
		output.texCoord = input.texCoord;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 diffuse = DiffuseTexture.Sample(TextureSampler, input.texCoord).rgb;
		float3 normal = NormalTexture.Sample(TextureSampler, input.texCoord).rgb;
		normal = normalize(normal * 2.0 - 1.0);
		
		// Diffuse Light
		float3 lightDir = normalize(input.lightPos - input.pixelPos);
		float diff = max(dot(lightDir, normal), 0.0);;
		
		// Specular Light		
		float3 viewDir = normalize(input.viewPos - input.pixelPos);	
		float3 reflectDir = reflect(-lightDir, normal);
   		float3 halfwayDir = normalize(lightDir + viewDir);  
    	float specular = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
    	float specularPower = 0.2;
		float3 color = diffuse * diff + specular * specularPower;
		
		return float4(color, 1);
	}

[End_Pass]