#ifndef GET_SHADOW_TOON_INCLUDE
#define GET_SHADOW_TOON_INCLUDE

// Shader includes example taken from: https://github.com/Cyanilux/URP_ShaderGraphCustomLighting/blob/6000.1/CustomLighting.hlsl
#ifndef SHADERGRAPH_PREVIEW
	#if SHADERPASS != SHADERPASS_FORWARD && SHADERPASS != SHADERPASS_GBUFFER
		// #if to avoid "duplicate keyword" warnings if this is included in a Lit Graph

    	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
    	#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
		#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
		#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
		#pragma multi_compile _ _CLUSTER_LIGHT_LOOP

		// Left some keywords (e.g. light layers, cookies) in subgraphs to help avoid unnecessary shader variants
		// But means if those subgraphs are nested in another, you'll need to copy the keywords from blackboard

	#endif
#endif

void GetShadowAtten_float(float3 worldPos, out float atten)
{
    atten = 1;
	
    #ifndef SHADERGRAPH_PREVIEW
	float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
    Light mainLight = GetMainLight(shadowCoord);
	half sa = mainLight.shadowAttenuation;
	atten = sa;
    #endif
}

/*
half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    uint lightsCount = GetAdditionalLightsCount();
    uint meshRenderingLayers = GetMeshRenderingLayer();

    LIGHT_LOOP_BEGIN(lightsCount)
        Light light = GetAdditionalLight(lightIndex, positionWS);

#ifdef _LIGHT_LAYERS
    if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
#endif
    {
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    }

    LIGHT_LOOP_END
#endif

    return vertexLightColor;
}
*/

#endif