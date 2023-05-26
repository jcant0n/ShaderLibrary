[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
	};

	cbuffer Matrices : register(b1)
	{		
		float3 Color					: packoffset(c0); [Default(1,1,0)]
		float NormalLength 				: packoffset(c0.w); [Default(0.05)]
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
		float3 normal	: NORMAL;
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
	
	[maxvertexcount(6)]
	void GS(line GS_IN input[2], inout LineStream<PS_IN> outputStream)
	{
		PS_IN v;
		
		for(int i = 0; i < 2; i++)
		{
			float3 P = input[i].position.xyz;
			float3 N = input[i].normal;
			
			v.position = mul(float4(P, 1.0), WorldViewProj);
			outputStream.Append(v);

			v.position = mul(float4(P + (N * NormalLength), 1.0), WorldViewProj);
			outputStream.Append(v);

			outputStream.RestartStrip();
		}
	}

	float4 PS(PS_IN input) : SV_Target
	{
		return float4(Color,1);
	}

[End_Pass]