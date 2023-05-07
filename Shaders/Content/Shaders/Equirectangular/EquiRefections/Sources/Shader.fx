[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj		: packoffset(c0); [WorldViewProjection]
		float4x4 World				: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}
	
	Texture2D EnvironmentTexture		: register(t0);
	SamplerState TextureSampler			: register(s0);

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define RECIPROCAL_PI2 0.15915494f
	
	struct VS_IN
	{
		float4 Position : POSITION;
		float3 Normal	: NORMAL;
		float2 TexCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 pos : SV_POSITION;
		float3 Nor	: NORMAL;
		float2 Tex : TEXCOORD0;
		float3 posw : TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.pos = mul(input.Position, WorldViewProj);
		output.posw = mul(input.Position, World).xyz;

		output.Nor = mul(float4(input.Normal, 0), World).xyz;
		output.Tex = input.TexCoord;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 viewVector = normalize(input.posw - CameraPosition);
		float3 normal = normalize(input.Nor);
		float3 reflectVec = normalize(reflect(viewVector, normal));
		
		float lon = atan2(reflectVec.z, reflectVec.x);
		float lat = acos(reflectVec.y);
		float2 sphereCoords = float2(lon, lat) * RECIPROCAL_PI2 * 2.0;
		float s = sphereCoords.x * 0.5 + 0.5;
		float t = sphereCoords.y;
		float2 uv = float2(s, t);
		float3 env = EnvironmentTexture.Sample(TextureSampler, uv);
	
		return float4(env ,1);
	}

[End_Pass]