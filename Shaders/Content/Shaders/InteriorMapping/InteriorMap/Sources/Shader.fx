[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj		: packoffset(c0); [WorldViewProjection]
		float4x4 World				: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
		float2 Tilling				: packoffset(c1.x); [Default(1,1)]
	}

	TextureCube cubeTexture			: register(t0);
	SamplerState TextureSampler		: register(s0);

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION0;
		float3 normal	: NORMAL0;
		float4 tangent	: TANGENT0;
		float2 texCoord : TEXCOORD0;
	};

	struct PS_IN
	{
		float4 position 		: SV_POSITION;
		float3 viewDirTangent	: TEXCOORD0;
		float2 texCoord 		: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		float3 posw = mul(input.position, World).xyz;
		
		float3 T = input.tangent;
		float3 N = input.normal;
		float3 B = cross(N, T) * input.tangent.w;
		
		float3x3 tbn = float3x3( normalize(T),
								 normalize(B),
								 normalize(N));
		
		float3 viewDir = CameraPosition - posw;
		output.viewDirTangent = mul(viewDir, tbn);
		output.texCoord = input.texCoord;
		
		return output;
	}
	
	float3 InteriorCubemap(float2 uv, float2 tilling, float3 viewTS)
	{
    	uv *= tilling;
   		uv = frac(uv) * float2(2, -2) - float2(1, -1);
	    float3 uvw = float3(uv, -1);
	
	    float3 view = viewTS * float3(-1, -1, 1);
	    float3 viewInverse = 1.0 / view;
	
	    float3 fractor = abs(viewInverse) - viewInverse * uvw;
	    float3 fmin = min(min(fractor.x, fractor.y), fractor.z) ;
	    float3 minview = fmin * view + uvw;
	
	    return minview.xyz;
	}

	float4 PS(PS_IN input) : SV_Target
	{	
		float2 uv = input.texCoord;
		float3 sampleDir = InteriorCubemap(uv, Tilling, normalize(input.viewDirTangent));
		
		float3 color = cubeTexture.Sample(TextureSampler, sampleDir).xyz;
		return float4(color, 1.0);
	}

[End_Pass]