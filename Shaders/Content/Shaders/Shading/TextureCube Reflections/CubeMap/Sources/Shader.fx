[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj			: packoffset(c0); [WorldViewProjection]
		float4x4 World					: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}
	
	TextureCube EnvironmentTexture		: register(t0);
	SamplerState TextureSampler			: register(s0);

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define RECIPROCAL_PI2 0.15915494f
	
	struct VS_IN
	{
		float4 Position : POSITION0;
		float3 Normal	: NORMAL0;
		float2 TexCoord : TEXCOORD0;
	};

	struct PS_IN
	{
		float4 Position		: SV_POSITION;
		float3 CameraVector	: TEXCOORD0;
		float3 NormalWS		: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.Position = mul(input.Position, WorldViewProj);	
		float3 positionWS = mul(input.Position, World).xyz;
		output.CameraVector = CameraPosition -  positionWS;	
		output.NormalWS = mul(input.Normal, (float3x3)World);

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 nomalizedCameraVector = normalize(input.CameraVector);
		float3 normal = normalize(input.NormalWS);
		float3 envCoord = reflect(nomalizedCameraVector, normal);
	
		return EnvironmentTexture.Sample(TextureSampler, envCoord);
	}

[End_Pass]