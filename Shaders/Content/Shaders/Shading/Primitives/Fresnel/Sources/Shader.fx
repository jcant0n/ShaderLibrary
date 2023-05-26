[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Parameters : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
		float FresnelExponent		: packoffset(c1.w); [Default(2)]
	}

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position 	: POSITION0;
		float3 normal		: NORMAL0;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 normal		: TEXCOORD0;
		float3 viewDir		: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		float3 positionWS = mul(input.position, World).xyz;
		output.viewDir = normalize(CameraPosition - positionWS);
		output.normal = mul(float4(input.normal, 0), World).xyz;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 fresnel = dot(input.normal, input.viewDir);
		fresnel = saturate(1 - fresnel);		
		fresnel = pow(fresnel, FresnelExponent);
		return float4(fresnel, 1.0);
	}

[End_Pass]