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
	
	[maxvertexcount(15)]
	void GS(triangle GS_IN input[3],  uint pid : SV_PrimitiveID, inout TriangleStream<PS_IN> outputStream)
	{		
		float4 p0 = input[0].position;
		float4 p1 = input[1].position;
		float4 p2 = input[2].position;
		
		float3 triangleNormal = normalize(cross(p2.xyz - p0.xyz, p1.xyz - p0.xyz));

		float4 v0 = mul(p0, WorldViewProj);
		float4 v1 = mul(p1, WorldViewProj);
		float4 v2 = mul(p2, WorldViewProj);
	
		float4 h = float4(triangleNormal, 0) * ExtrudeAmount * (1 + 0.8 * cos(pid * 200));
		float4 v3 = mul(p0 + h, WorldViewProj);
		float4 v4 = mul(p1 + h, WorldViewProj);
		float4 v5 = mul(p2 + h, WorldViewProj);
		
		PS_IN v;

		v.color = TopColor;
		v.position = v3;
		outputStream.Append(v);
		v.position = v4;
		outputStream.Append(v);
		v.position = v5;
		outputStream.Append(v);
		
		outputStream.RestartStrip();
		
		v.color = TopColor;
		v.position = v3;
		outputStream.Append(v);
		v.color = BottomColor;
		v.position = v0;
		outputStream.Append(v);
		v.color = TopColor;
		v.position = v4;
		outputStream.Append(v);
		v.color = BottomColor;
		v.position = v1;
		outputStream.Append(v);

		v.color = TopColor;
		v.position = v4;
		outputStream.Append(v);
		v.color = BottomColor;
		v.position = v1;
		outputStream.Append(v);
		v.color = TopColor;
		v.position = v5;
		outputStream.Append(v);
		v.color = BottomColor;
		v.position = v2;
		outputStream.Append(v);

		
		v.color = TopColor;
		v.position = v5;
		outputStream.Append(v);
		v.color = BottomColor;
		v.position = v2;
		outputStream.Append(v);
		v.color = TopColor;
		v.position = v3;
		outputStream.Append(v);
		v.color = BottomColor;
		v.position = v0;
		outputStream.Append(v);
	}

	float4 PS(PS_IN input) : SV_Target
	{
		return float4(input.color, 1);
	}

[End_Pass]