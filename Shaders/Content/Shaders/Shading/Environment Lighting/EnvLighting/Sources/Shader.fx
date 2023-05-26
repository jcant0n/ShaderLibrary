[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj		: packoffset(c0);	[WorldViewProjection]
		float4x4 World				: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}
	
	cbuffer Parameters : register(b2)
	{
		float DiffusePower			: packoffset(c0.x); [Default(0.7)]
		float SpecularPower			: packoffset(c0.y); [Default(0.2)]
	}

	Texture2D DiffuseImportanceSampling		: register(t0);
	Texture2D SpecularImportanceSampling	: register(t1);
	SamplerState TextureSampler				: register(s0);

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define RECIPROCAL_PI2 0.15915494f

	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 normal		: NORMAL0;
		float3 positionWS 	: TEXCOORD0;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		output.positionWS = mul(input.position, World).xyz;
		output.normal = mul(float4(input.normal, 0), World).xyz;

		return output;
	}

	float2 DirectionToEquirectangular(float3 dir)
	{
		float lon = atan2(dir.z, dir.x);
		float lat = acos(dir.y);
		float2 sphereCoords = float2(lon, lat) * RECIPROCAL_PI2 * 2.0;
		float s = sphereCoords.x * 0.5 + 0.5;
		float t = sphereCoords.y;
		
		return float2(s, t);
	}
	
	float4 PS(PS_IN input) : SV_Target
	{
		float3 viewDir = normalize(CameraPosition - input.positionWS);
		float3 normal = normalize(input.normal);
		float3 reflectDir = reflect(-viewDir, normal);
		
		float3 diff = DiffuseImportanceSampling.Sample(TextureSampler, DirectionToEquirectangular(normal)).rgb;
		float3 spec = SpecularImportanceSampling.Sample(TextureSampler, DirectionToEquirectangular(reflectDir)).rgb;
		float rn = dot(reflectDir, normal);
		
		float3 color = diff * DiffusePower + spec * SpecularPower * rn;
		
		return float4(color, 1);
	}

[End_Pass]