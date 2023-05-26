[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION;
	};

	struct PS_IN
	{
		float4 position : SV_POSITION;
		float3 viewDir	: TEXCOORD0;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		float3 positionWS = mul(input.position, World).xyz;
		output.viewDir = normalize(CameraPosition - positionWS);

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		return float4(input.viewDir, 1.0);
	}

[End_Pass]