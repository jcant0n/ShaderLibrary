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
		float4 position : POSITION0;
		float3 normal	: NORMAL0;
		float2 texCoord : TEXCOORD0;
	};

	struct PS_IN
	{
		float4 position		: SV_POSITION;
		float3 cameraVector	: TEXCOORD0;
		float3 normal		: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);	
		float3 positionWS = mul(input.position, World).xyz;
		output.cameraVector = CameraPosition -  positionWS;	
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
		float3 nomalizedCameraVector = normalize(-input.cameraVector);
		float3 normal = normalize(input.normal);
		float3 reflectDir = normalize(reflect(nomalizedCameraVector, normal));

		float2 uv = DirectionToEquirectangular(reflectDir);
		float3 env = EnvironmentTexture.Sample(TextureSampler, uv);
	
		return float4(env ,1);
	}

[End_Pass]