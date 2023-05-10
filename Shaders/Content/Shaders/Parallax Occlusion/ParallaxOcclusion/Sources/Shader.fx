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
		float3 lightPosition	: packoffset(c0.x); [Default(0,0,1)]
		float heightScale		: packoffset(c0.w); [Default(0.03)]
		
	};

	Texture2D DiffuseTexture		: register(t0);
	Texture2D HeightTexture			: register(t1);
	Texture2D NormalTexture			: register(t2);
	SamplerState TextureSampler		: register(s0);
	
[End_ResourceLayout]

[Begin_Pass:Default]
	[Profile 10_0]
	[Entrypoints VS=VS PS=PS]

	struct VS_IN
	{
		float4 Position : POSITION;
		float3 Normal	: NORMAL;
		float4 Tangent  : TANGENT;
		float2 TexCoord : TEXCOORD;
	};

	struct PS_IN
	{
		float4 pos 		: SV_POSITION;
		float2 Tex 		: TEXCOORD0;
		float3 pixelPos : TEXCOORD1;
		float3 viewPos	: TEXCOORD2;
		float3 lightPos	: TEXCOORD3;
	};

	PS_IN VS(VS_IN input)
	{
		PS_IN output = (PS_IN)0;

		output.pos = mul(input.Position, WorldViewProj);
		float3 posw = mul(input.Position, World).xyz;
		
		float3 T = mul(input.Tangent, World).xyz;
		float3 N = mul(float4(input.Normal, 0), World).xyz;
		float3 B = cross(T, N) * input.Tangent.w;
		
		float3x3 tbn = float3x3( normalize(T),
								 normalize(B),
								 normalize(N));
		
		output.pixelPos = mul(posw, tbn);
		output.viewPos = mul(CameraPosition, tbn);
		output.lightPos = mul(lightPosition, tbn);
		output.Tex = input.TexCoord;

		return output;
	}


	float2 ParallaxMapping(float2 texCoords, float3 viewDir)
	{ 
		// number of depth layers
		const float minLayers = 8;
		const float maxLayers = 32;
		float numLayers = lerp(maxLayers, minLayers, abs(dot(float3(0.0, 0.0, 1.0), viewDir)));  
		// calculate the size of each layer
		float layerDepth = 1.0 / numLayers;
		// depth of current layer
		float currentLayerDepth = 0.0;
		// the amount to shift the texture coordinates per layer (from vector P)
		float2 P = viewDir.xy / viewDir.z * heightScale; 
		float2 deltaTexCoords = P / numLayers;
		
		// get initial values
		float2  currentTexCoords     = texCoords;
		float currentDepthMapValue = HeightTexture.Sample(TextureSampler, currentTexCoords).r;
		
		[loop]
		while(currentLayerDepth < currentDepthMapValue)
		{
		    // shift texture coordinates along direction of P
		    currentTexCoords -= deltaTexCoords;
		    // get depthmap value at current texture coordinates
		    currentDepthMapValue = HeightTexture.Sample(TextureSampler, currentTexCoords).r;
		    // get depth of next layer
		    currentLayerDepth += layerDepth;  
		}
		
		// get texture coordinates before collision (reverse operations)
		float2 prevTexCoords = currentTexCoords + deltaTexCoords;
		
		// get depth after and before collision for linear interpolation
		float afterDepth  = currentDepthMapValue - currentLayerDepth;
		float beforeDepth = HeightTexture.Sample(TextureSampler, prevTexCoords).r - currentLayerDepth + layerDepth;
		
		// interpolation of texture coordinates
		float weight = afterDepth / (afterDepth - beforeDepth);
		float2 finalTexCoords = prevTexCoords * weight + currentTexCoords * (1.0 - weight);
		
		return finalTexCoords;
	}

	float4 PS(PS_IN input) : SV_Target
	{
		float3 viewDir = normalize(input.viewPos - input.pixelPos);		
		
		float2 texCoords = ParallaxMapping(input.Tex, viewDir);
		if(texCoords.x > 1.0 || texCoords.y > 1.0 || texCoords.x < 0.0 || texCoords.y < 0.0)
        	discard;
        
		float3 diffuse = DiffuseTexture.Sample(TextureSampler, texCoords).rgb;
		float3 normal = NormalTexture.Sample(TextureSampler, texCoords).rgb;
		normal = normalize(normal * 2.0 - 1.0);
		
		// Diffuse Light
		float3 lightDir = normalize(input.lightPos - input.pixelPos);
		float diff = max(dot(lightDir, normal), 0.0);;
		
		// Specular Light		
		float3 reflectDir = reflect(-lightDir, normal);
   		float3 halfwayDir = normalize(lightDir + viewDir);  
    	float specular = pow(max(dot(normal, halfwayDir), 0.0), 32.0);
    	float specularPower = 0.2;
		float3 color = diffuse * diff + specular * specularPower;
		
		return float4(color, 1);
	}

[End_Pass]