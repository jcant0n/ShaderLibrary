[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Matrices : register(b1)
	{		
		float3 LightPosition		: packoffset(c0.x); [Default(0,0,1)]
	};

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS GS=GS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION0;
		float3 normal	: NORMAL0;
		float3 positionWS : TEXCOORD0;
	};

	struct GS_IN
	{
		float4 position : SV_POSITION;
		float3 normal	: NORMAL0;
		float3 positionWS : TEXCOORD0;
	};
	
	struct PS_IN
	{
		float4 position : SV_POSITION;
		float3 normal 	: NORMAL0;
		float3 positionWS : TEXCOORD0;
	};
	
	GS_IN VS(VS_IN input)
	{
		GS_IN output = (GS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		output.positionWS = mul(input.position, World).xyz;
		output.normal = input.normal;

		return output;
	}
	
	[maxvertexcount(3)]
	void GS(triangle GS_IN input[3], inout TriangleStream<PS_IN> triStream)
	{		
		float3 p0 = input[0].positionWS.xyz;
		float3 p1 = input[1].positionWS.xyz;
		float3 p2 = input[2].positionWS.xyz;
		float3 triangleNormal = normalize(cross(p2 - p0, p1 - p0));

		for (int i = 0; i < 3; i++)
		{
			input[i].normal = triangleNormal;
			triStream.Append(input[i]);
		}
		
		triStream.RestartStrip();
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 lightDir = normalize(LightPosition - input.positionWS);	
		float3 diffuse = max(dot(lightDir, input.normal), 0.0);
		
		return float4(diffuse, 1.0);
	}

[End_Pass]