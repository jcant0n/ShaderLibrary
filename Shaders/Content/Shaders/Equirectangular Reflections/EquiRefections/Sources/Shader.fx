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
		float4 Position : POSITION0;
		float3 Normal	: NORMAL0;
		float2 TexCoord : TEXCOORD0;
	};

	struct PS_IN
	{
		float4 Position		: SV_POSITION;
		float3 CameraVector	: TEXCOORD0;
		float3 NormalWS		: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.Position = mul(input.Position, WorldViewProj);	
		float3 positionWS = mul(input.Position, World).xyz;
		output.CameraVector = CameraPosition -  positionWS;	
		output.NormalWS = mul(input.Normal, (float3x3)World);

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
		float3 nomalizedCameraVector = normalize(-input.CameraVector);
		float3 normal = normalize(input.NormalWS);
		float3 reflectDir = normalize(reflect(nomalizedCameraVector, normal));

		float2 uv = DirectionToEquirectangular(reflectDir);
		float3 env = EnvironmentTexture.Sample(TextureSampler, uv);
	
		return float4(env ,1);
	}

[End_Pass]