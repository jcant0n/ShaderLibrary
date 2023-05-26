[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(C4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
		float  Amount				: packoffset(c0.w); [Default(0.4)]
		float3 BoxMax				: packoffset(c1.x); [Default(1, 1, 1)]
		float3 BoxMin				: packoffset(c2.x); [Default(0,0,0)]
		float3 CubeMapPos			: packoffset(c3.x); [Default(0.5,0.5,0.5)]
	}

	Texture2D AlbedoTexture		: register(t0);
	TextureCube CubeTexture			: register(t1);
	SamplerState TextureSampler		: register(s0);

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 position : POSITION;
		float3 normal	: NORMAL;
		float2 texCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 normal		: NORMAL0;
		float3 positionWS	: TEXCOORD0;
		float2 texCoord		: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		output.positionWS = mul(input.position, World).xyz;
		output.normal = input.normal;
		output.texCoord = input.texCoord;
		
		return output;
	}

	// https://seblagarde.wordpress.com/2012/09/29/image-based-lighting-approaches-and-parallax-corrected-cubemap/
	float3 ParallaxCorrectNormal(float3 pos, float3 v, float3 boxMax, float3 boxMin, float3 cubePos )
	{	
		float3 nDir = normalize(v);
		float3 firstPlaneIntersect = (boxMax - pos ) / nDir;
		float3 secondPlaneIntersect  = (boxMin - pos ) / nDir;

		float3 furthestPlane = max(firstPlaneIntersect, secondPlaneIntersect);
		float vdistance = min(min(furthestPlane.x, furthestPlane.y), furthestPlane.z);
		float3 boxIntersection = pos + nDir * vdistance;
		
		return boxIntersection - cubePos;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 viewDir = normalize(input.positionWS - CameraPosition);
		float3 vreflect = reflect(viewDir, input.normal);
		float3 sampleDir = ParallaxCorrectNormal(input.positionWS, vreflect, BoxMax, BoxMin, CubeMapPos);
		float3 reflection = CubeTexture.Sample(TextureSampler, sampleDir).xyz;
		
		float3 base = AlbedoTexture.Sample(TextureSampler, input.texCoord).xyz;
		float3 color = lerp(base, reflection, Amount);
		return float4(color, 1.0);
	}

[End_Pass]