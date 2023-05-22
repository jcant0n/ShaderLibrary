[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Matrices : register(b1)
	{		
		float3 Color					: packoffset(c0); [Default(1,1,0)]
		float ExplosionFactor 			: packoffset(c0.w); [Default(1)]
		float Time						: packoffset(C1.x); [Time]
	};

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS GS=GS PS=PS]
	[CullMode None]
	
	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
	};

	struct GS_IN
	{
		float4 position : SV_POSITION;
		float3 normal	: NORMAL0;
	};
	
	struct PS_IN
	{
		float4 position : SV_POSITION;		
	};
	
	GS_IN VS(VS_IN input)
	{
		GS_IN output = (GS_IN)0;

		output.position = input.position;
		output.normal = input.normal;

		return output;
	}
	
	[maxvertexcount(3)]
	void GS(triangle GS_IN input[3], inout TriangleStream<PS_IN> outputStream)
	{
		PS_IN v;
		
		float3 triangleNormal = normalize(cross(input[2].position - input[0].position, 
												input[1].position - input[0].position));
		
		for(int i = 0; i < 3; i++)
		{
			float4 newPosition = input[i].position + float4(triangleNormal, 1) * ExplosionFactor;
			v.position = mul(newPosition, WorldViewProj);
			outputStream.Append(v);
		}
		
		outputStream.RestartStrip();
	}

	float4 PS(PS_IN input) : SV_Target
	{
		return float4(Color,1);
	}

[End_Pass]