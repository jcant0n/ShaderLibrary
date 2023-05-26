[Begin_ResourceLayout]

	cbuffer PerDrawCall : register(b0)
	{
		float4x4 WorldViewProj	: packoffset(c0); [WorldViewProjection]
		float4x4 World			: packoffset(c4); [World]
	};

	cbuffer PerCamera : register(b1)
	{
		float3 CameraPosition		: packoffset(c0.x); [CameraPosition]
	}
	
	cbuffer Parameters : register(b2)
	{
		float3 Color			: packoffset(c0); [Default(0.3, 0.3, 1.0)]
		float Glossiness		: packoffset(c0.w); [Default(32)]
		float3 LightPosition	: packoffset(c1); [Default(0,0,1)]
		float RimAmount			: packoffset(c1.w); [Default(0.7)]
		float3 AmbientColor		: packoffset(c2); [Default(0.4,0.4,0.4)]
	};

[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]
	
	float ramp[3] = {0.2, 0.5, 0.8};
	
	struct VS_IN
	{
		float4 position 	: POSITION;
		float3 normal		: NORMAL;
		float2 texCoord 	: TEXCOORD;
	};

	struct PS_IN
	{
		float4 position 	: SV_POSITION;
		float3 normal		: NORMAL;
		float3 positionWS	: TEXCOORD0;
		float2 texCoord 	: TEXCOORD1;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.position = mul(input.position, WorldViewProj);
		output.positionWS = mul(input.position, World).xyz;
		output.normal = mul(float4(input.normal, 0), World).xyz;
		output.texCoord = input.texCoord;

		return output;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 lightDir = normalize(LightPosition - input.positionWS);
		float3 viewDir = normalize(CameraPosition - input.positionWS);
		float3 normal = normalize(input.normal);
		
		// Diffuse
		float3 NdotL = max(dot(normal, lightDir), 0.0);
		float diffuseIntensity = smoothstep(0, 0.01, NdotL);
		
		// Specular
		float3 halfVector = normalize(viewDir + lightDir);
		float NdotH = max(dot(normal, halfVector), 0.0);
		float specular = pow(NdotH, Glossiness * Glossiness);
		float specularIntensity = smoothstep(0.005, 0.01, specular);
		
		// Rim lighting
		float4 rimDot = 1 - dot(viewDir, normal);
		float rimIntensity = smoothstep(RimAmount - 0.01, RimAmount + 0.01, rimDot);
		
		float3 color = Color * (AmbientColor + diffuseIntensity + specularIntensity + rimIntensity);
		
		return float4(color, 1.0);
	}

[End_Pass]