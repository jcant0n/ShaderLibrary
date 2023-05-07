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
	
	cbuffer Parameters : register(b2)
	{
		float PupilRadius			: packoffset(c0.x); [Default(0.1)]
		float IrisRadius			: packoffset(c0.y); [Default(0.2)]
		float LimbusScale			: packoffset(c0.z); [Default(0.7)]
		float Parallax				: packoffset(c0.w); [Default(0.2)]
	};

	Texture2D ScleraTexture			: register(t0);
	Texture2D IrisTexture			: register(t1);
	Texture2D ReflectionsTexture	: register(t2);
	Texture2D NormalTexture			: register(t3);
	SamplerState TextureSampler		: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	#define RECIPROCAL_PI2 0.15915494f
	
	struct VS_IN
	{
		float4 Position 	: POSITION;
		float3 Normal		: NORMAL;
		float4 Tangent  	: TANGENT;
		float2 TexCoord 	: TEXCOORD;
	};

	struct PS_IN
	{
		float4 pos 				: SV_POSITION;
		float2 TexCoord 		: TEXCOORD0;
		float3 viewDir 			: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.pos = mul(input.Position, WorldViewProj);
		float3 position = mul(input.Position, World).xyz;
		float3 viewdir = CameraPosition - position;
		
		float3 T = mul(input.Tangent, World).xyz;
		float3 N = mul(float4(input.Normal, 0), World).xyz;
		float3 B = cross(T, N) * input.Tangent.w;
		
		float3x3 tbn = float3x3( normalize(T),
								 normalize(B),
								 normalize(N));
		
		output.viewDir = mul(viewdir, tbn);
		output.TexCoord = input.TexCoord;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float2 center = float2(0.5, 0.5);
		float2 uv = input.TexCoord - center;
		float dis = length(uv);
		
		// Pupil
		float ramp = saturate((dis - PupilRadius) / (IrisRadius - PupilRadius));		
		float ratio = (IrisRadius / PupilRadius) / 4.6;
		float uvScale = (0.35 / IrisRadius) *lerp(ratio, 1.0, ramp);
		
		// Masks
		float scleraMask = smoothstep(IrisRadius, IrisRadius + LimbusScale * 0.05, dis);
		float irisMask = smoothstep(IrisRadius + 0.01, IrisRadius, dis);
		
		// Eye Paralax Mapping
		//float h = HeightTexture.Sample(TextureSampler, uv * uvScale + 0.5).r;
		float h = dis;
		float3 v = normalize(input.viewDir);	
		float2 offset =  (h * Parallax - Parallax / 2.0) * (v.xy / v.z);
		
		// Textures
		float2 irisUV = uv * uvScale + 0.5 + offset;
		float3 sclera = ScleraTexture.Sample(TextureSampler, input.TexCoord).rgb;
		float3 iris = IrisTexture.Sample(TextureSampler, irisUV).rgb;
		
		// Normal
		float3 normal = NormalTexture.Sample(TextureSampler, irisUV).rgb;
		normal = normalize(normal * 2.0 - 1.0);
		
		// Reflections
		float3 reflectVec = reflect(input.viewDir, normal);
		float lon = atan2(reflectVec.z, reflectVec.x);
		float lat = acos(reflectVec.y);
		float2 sphereCoords = float2(lon, lat) * RECIPROCAL_PI2 * 2.0;
		float s = sphereCoords.x * 0.5 + 0.5;
		float t = sphereCoords.y;
	
		float2 reflectUV = float2(s, t);		
		float3 reflections = ReflectionsTexture.Sample(TextureSampler, reflectUV).rgb;
				
		// Specular
		float3 lightDir = float3(0,0.9,1);
		float3 halfwayDir = normalize(lightDir + input.viewDir);  
		float specular = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
		
		// Color Composition
		float3 color = scleraMask * sclera;
		color += irisMask * iris;
		//color += specular * irisMask;
		color += reflections * irisMask;
		//color = reflections;

		return float4(color, 1.0);
	}

[End_Pass]