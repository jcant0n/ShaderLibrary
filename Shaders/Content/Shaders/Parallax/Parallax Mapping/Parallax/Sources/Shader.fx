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
		float heightScale		: packoffset(c0.w); [Default(0.03)]
		
	};

	Texture2D DiffuseTexture		: register(t0);
	Texture2D HeightTexture			: register(t1);
	Texture2D NormalTexture			: register(t2);
	SamplerState TextureSampler		: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
		float4 tangent  : TANGENT;
		float2 texCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 position : SV_POSITION;
		float2 texCoord : TEXCOORD0;
		float3 pixelPos : TEXCOORD1;
		float3 viewPos	: TEXCOORD2;
		float3 lightPos	: TEXCOORD3;
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
		float h = HeightTexture.Sample(TextureSampler, input.texCoord).r;
		
		float3 viewDir = normalize(input.viewPos - input.pixelPos);		
		float2 offset = (h * heightScale - (heightScale / 2.0)) * (viewDir.xy / viewDir.z);
		
		float2 uv = input.texCoord + offset;
		float3 diffuse = DiffuseTexture.Sample(TextureSampler, uv).rgb;
		float3 normal = NormalTexture.Sample(TextureSampler, uv).rgb;
		normal = normalize(normal * 2.0 - 1.0);
		
		// Diffuse Light
		float3 lightDir = normalize(input.lightPos - input.pixelPos);
		float diff = max(dot(lightDir, normal), 0.0);;
		
		// Specular Light		
		float3 reflectDir = reflect(-lightDir, normal);
   		float3 halfwayDir = normalize(lightDir + viewDir);  
    	float specular = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
    	float specularPower = 0.2;
		float3 color = diffuse * diff + specular * specularPower;
		
		return float4(color, 1);
	}

[End_Pass]