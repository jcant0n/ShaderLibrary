[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

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
		float4 pos 			: SV_POSITION;
		float3 positionWS	: TEXCOORD0;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.pos = mul(input.position, WorldViewProj);
		output.positionWS = mul(input.position, World).xyz;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		return float4(input.positionWS, 1.0);
	}

[End_Pass]