[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
	};

	cbuffer Parameters : register(b1)
	{
		float3 Color				: packoffset(c0);   [Default(0.3, 0.3, 1.0)]
		float WireframeSmoothing 	: packoffset(c0.w); [Default(1)]
		float WireframeThickness	: packoffset(c1.x); [Default(1)]
	};

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS GS=GS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
		float2 texCoord : TEXCOORD;
	};

	struct GS_IN
	{
		float4 position : SV_POSITION;
		float3 normal	: NORMAL;
		float3 barycentric : TEXCOORD0;
		float2 texCoord : TEXCOORD1;
	};
	
	struct PS_IN
	{
		float4 position : SV_POSITION;
		float3 normal	: NORMAL;
		float3 barycentric : TEXCOORD0;
		float2 texCoord : TEXCOORD1;
	};

	GS_IN VS(VS_IN input)
	{
		GS_IN output = (GS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		output.normal = input.normal;
		output.texCoord = input.texCoord;

		return output;
	}
	
	[maxvertexcount(3)]
	void GS(triangle GS_IN input[3], inout TriangleStream<PS_IN> triStream)
	{	
		float3 coord[3] = {float3(1,0,0), float3(0,1,0), float3(0,0,1)};
			
		for (int i = 0; i < 3; i++)
		{
			input[i].barycentric = coord[i];
			triStream.Append(input[i]);
		}
		
		triStream.RestartStrip();
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float minBary = min(min(input.barycentric.x, input.barycentric.y), input.barycentric.z);
		float deltas = fwidth(minBary);
		float3 smoothing = deltas * WireframeSmoothing;
		float3 thickness = deltas * WireframeThickness;
		minBary = smoothstep(thickness, thickness + smoothing, minBary);
		return float4(Color * minBary, 1);
	}

[End_Pass]