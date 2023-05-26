[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Matrices : register(b1)
	{		
		float3 LightPosition	: packoffset(c0.x); [Default(0,0,1)]
	};

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position 	: POSITION0;
		float3 positionWS 	: TEXCOORD0;
	};
	
	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 positionWS 	: TEXCOORD0;
	};
	
	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		output.positionWS = mul(input.position, World).xyz;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 lightDir = normalize(input.positionWS - LightPosition);
		
		float3 dpdx = ddx(input.positionWS);
		float3 dpdy = ddy(input.positionWS);
		float3 triangleNormal = normalize(cross(dpdx, dpdy));
		
		float3 diffuse = max(dot(lightDir, triangleNormal), 0.0);
		
		return float4(diffuse, 1.0);
	}

[End_Pass]