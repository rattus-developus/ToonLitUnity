/* TODO
    - setup an ambient light property to allow use in enviroments with any lighting setup
    - steal shadows from unity (reference DissolveFromPoint?)
    - add NdotL lighting from point lights
*/

Shader "Custom/ToonMaster"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _BaseMap ("Texture", 2D) = "white" {}

        _StepHighlight ("StepHighlight", Range(0.0001,1)) = 0.9
        _StepBase ("StepBase", Range(0.0001,1)) = 0.8
        _StepSoftShadow ("StepShadow", Range(0.0001,1)) = 0.25

        _HighlightColor ("Highlight Color", Color) = (1,1,1,1)
        _BaseColor ("Base Color", Color) = (0.85,0.85,0.85,1)
        _SoftShadowColor ("Soft Shadow Color", Color) = (0.2,0.2,0.2,1)
        _HardShadowColor ("Hard Shadow Color", Color) = (0.1,0.1,0.1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"     = "Opaque"
            "Queue"          = "Geometry"
        }

        Pass
        {
            Name "ToonPass"

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            float4 _Color;

            float _StepHighlight;
            float _StepBase;
            float _StepSoftShadow;

            float4 _HighlightColor;
            float4 _BaseColor;
            float4 _SoftShadowColor;
            float4 _HardShadowColor;

            float3 GetMainLightDirection()
            {
                #if defined(SHADERGRAPH_PREVIEW)
                    return normalize(float3(0.5, 0.5, 0.5));
                #else
                    Light mainLight = GetMainLight();
                    return mainLight.direction; // normalized, surface → light
                #endif
            }
            
            // Defines the 3 step thresholds for n dot l lighting, applies them
            float GetShadingNL(float3 normalWS)
            {
                float3 mainLightDir = GetMainLightDirection();
                float lighting = saturate(dot(normalWS, mainLightDir));
                
                float highlight = step(_StepHighlight, lighting) * _HighlightColor;
                float base = step(_StepBase, lighting) * _BaseColor;
                float softShadow = step(_StepSoftShadow, lighting) * _SoftShadowColor;
                float hardShadow = _HardShadowColor;
                
                lighting = max(hardShadow, softShadow);
                lighting = max(lighting, base);
                lighting = max(lighting, highlight);

                return lighting;
            }

            Varyings vert (Attributes v)
            {
                Varyings o;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.uv = v.uv;
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 tex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);

                float lighting = GetShadingNL(i.normalWS);

                return tex * _Color * lighting;
            }
            ENDHLSL
        }
    }
}
