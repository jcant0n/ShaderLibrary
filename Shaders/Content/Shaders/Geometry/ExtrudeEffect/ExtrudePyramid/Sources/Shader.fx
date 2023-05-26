[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Matrices : register(b1)
	{		
		float3 BottomColor				: packoffset(c0); [Default(0,0,0)]
		float ExtrudeAmount				: packoffset(c0.w); [Default(0.4)]
		float3 TopColor 				: packoffset(c1); [Default(1, 1, 1)]
	};

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS GS=GS PS=PS]
	
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
		float3 color	: TEXCOORD0;
	};
	
	GS_IN VS(VS_IN input)
	{
		GS_IN output = (GS_IN)0;

		output.position = input.position;
		output.normal = input.normal;

		return output;
	}
	
	[maxvertexcount(9)]
	void GS(triangle GS_IN input[3], inout TriangleStream<PS_IN> outputStream)
	{		
		float4 p0 = input[0].position;
		float4 p1 = input[1].position;
		float4 p2 = input[2].position;
		float4 topVertex = (p0 + p1 + p2) / 3.0;
		
		float3 triangleNormal = normalize(cross(p2.xyz - p0.xyz, p1.xyz - p0.xyz));
		topVertex.xyz += triangleNormal * ExtrudeAmount;

		PS_IN v;

		for(int i = 0; i < 3; i++)
		{
			int index = (i + 1) % 3;
			v.position = mul(input[index].position, WorldViewProj);
			v.color = BottomColor;
			outputStream.Append(v);
			
			v.position = mul(topVertex, WorldViewProj);
			v.color = TopColor;
			outputStream.Append(v);
						
			v.position = mul(input[i].position, WorldViewProj);
			v.color = BottomColor;
			outputStream.Append(v);
			
			outputStream.RestartStrip();
		}
	}

	float4 PS(PS_IN input) : SV_Target
	{
		return float4(input.color, 1);
	}

[End_Pass]