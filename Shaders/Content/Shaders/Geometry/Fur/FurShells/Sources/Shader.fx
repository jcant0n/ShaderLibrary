[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0);	[WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer Parameters : register(b1)
	{		
		float MaxHairLength			: packoffset(c0.x); [Default(0.04)]
		float StartShadowValue		: packoffset(c0.y); [Default(0.2)]
	};

	Texture2D DiffuseTexture		: register(t0);
	Texture2D FurTexture			: register(t1);
	SamplerState TextureSampler		: register(s0);
	SamplerState FurSampler		: register(s1);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS GS=GS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION0;
		float3 normal	: NORMAL0;
		float3 texCoord : TEXCOORD0;
	};

	struct GS_IN
	{
		float4 position : SV_POSITION;
		float3 normal	: NORMAL0;
		float3 texCoord : TEXCOORD0;
	};
	
	struct PS_IN
	{
		float4 position : SV_POSITION;
		float3 texCoord : TEXCOORD0;
		float layer		: TEXCOORD1;
		float shadow	: TEXCOORD2;
	};
	
	GS_IN VS(VS_IN input)
	{
		GS_IN output = (GS_IN)0;

		output.position = input.position;
		output.normal = input.normal;
		output.texCoord = input.texCoord;
		
		return output;
	}
	
	[maxvertexcount(96)]
	void GS(triangle GS_IN input[3], inout TriangleStream<PS_IN> triStream)
	{	
		PS_IN e;
		for (int i = 0; i < 32; i++)
		{
			float currentLayer = i / 32.0;
			float h = currentLayer * MaxHairLength;
			for(int v = 0; v < 3; v++)
			{
				float4 layerVertex = input[v].position + float4(input[v].normal, 0) * h;
				e.position = mul(layerVertex, WorldViewProj);
				e.texCoord = input[v].texCoord;
				e.layer = currentLayer;
				e.shadow = lerp(StartShadowValue, 1.0, currentLayer);
				triStream.Append(e);
			}
			
			triStream.RestartStrip();
		}
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float furData = FurTexture.Sample(FurSampler, input.texCoord).r;
		if (input.layer > 0 && (furData == 0 || furData < input.layer))
			discard;
		
		float3 color = DiffuseTexture.Sample(TextureSampler, input.texCoord).rgb;
		color *= input.shadow;
		
		return float4(color, 1.0);
	}

[End_Pass]