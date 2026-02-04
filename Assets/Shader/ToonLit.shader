Shader "Custom/ToonLit"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _BaseMap ("Texture", 2D) = "white" {}

        _Ambient ("Ambient", Range(0.0001,1)) = 0.1
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalRenderPipeline"
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry"
        }

        Pass
        {
            Name "ToonPass"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/BRDF.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RealtimeLights.hlsl"
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS


            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float2 uv          : TEXCOORD2;
                float4 shadowCoord : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _BaseMap_ST;
            float4 _Color;

            float _Ambient;

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);

                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs normInputs = GetVertexNormalInputs(v.normalOS);
                o.shadowCoord = GetShadowCoord(posInputs);
                
                return o;
            }

            float ToonBand(float value, float bands)
            {
                return floor(value * bands) / bands;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                float3 albedo = tex.rgb * _Color.rgb;

                float3 lighting = 0;

                uint lightCount = GetAdditionalLightsCount();
                for (uint li = 0; li < lightCount; li++)
                {
                    float3 biasedPosWS = i.positionWS + i.normalWS * 0.005;
                    Light light = GetAdditionalLight(li, biasedPosWS, i.shadowCoord);

                    float ndl = saturate(dot(normalize(i.normalWS), light.direction));

                    half4 shadowMask = unity_ProbesOcclusion;
                    float shadow = light.shadowAttenuation;

                    float band = ToonBand(ndl*shadow, 3);

                    band = max(band, _Ambient);

                    lighting += band * light.color * light.distanceAttenuation;
                }

                return half4(albedo * lighting, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            HLSLPROGRAM
            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            #pragma multi_compile_shadowcaster


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 posHCS : SV_POSITION;
                float3 positionOS : TEXCOORD0;
                float2 uv : TEXCOORD1;
            };

            Varyings vertShadowCaster(Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS   = TransformObjectToWorldNormal(IN.normalOS);

                float3 lightDirWS = _MainLightPosition.xyz;

                positionWS = ApplyShadowBias(positionWS, normalWS, lightDirWS);

                OUT.posHCS = TransformWorldToHClip(positionWS);

                OUT.positionOS = IN.positionOS.xyz;
                OUT.uv = IN.uv;
                return OUT;
            }
            
            float4 fragShadowCaster(Varyings IN) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }
}
