Shader "Unlit/ViewDir"
{
    Properties
    {
        _BaseMap   ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        [KeywordEnum(UV0, UV1)] _UVSET ("UV Set", Float) = 0

        // Optional: rim/fresnel demo
        _RimColor ("Rim Color", Color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(0.5, 8)) = 3
        _RimStrength ("Rim Strength", Range(0,1)) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalRenderPipeline" }
        LOD 200

        Pass
        {
            Name "Unlit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #pragma shader_feature_local _UVSET_UV0 _UVSET_UV1

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;    // <-- added (for rim/Fresnel)
                float2 uv0        : TEXCOORD0;
                float2 uv1        : TEXCOORD1;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;

                float3 positionWS  : TEXCOORD1; // <-- added
                float3 normalWS    : TEXCOORD2; // <-- added
            };

            // Textures
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // Material props
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _RimColor;
                float  _RimPower;
                float  _RimStrength;
            CBUFFER_END

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                // World data
                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionWS  = posWS;                 // pass to frag
                OUT.normalWS    = nrmWS;
                OUT.positionHCS = TransformWorldToHClip(posWS);

                // UV selection stays the same
                #if defined(_UVSET_UV1)
                    OUT.uv = TRANSFORM_TEX(IN.uv1, _BaseMap);
                #else
                    OUT.uv = TRANSFORM_TEX(IN.uv0, _BaseMap);
                #endif

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                // Base color
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half3 color   = baseTex.rgb * _BaseColor.rgb;

                // ------- viewDir in URP -------
                // Get vector from surface point to camera (world space)
                float3 viewDirWS = GetWorldSpaceViewDir(IN.positionWS);
                viewDirWS = SafeNormalize(viewDirWS);

                // Optional: Fresnel / rim using the world-space normal
                float3 n = SafeNormalize(IN.normalWS);
                float  ndotv = saturate(dot(n, viewDirWS));
                float  fres  = pow(1.0 - ndotv, _RimPower);     // stronger at grazing angles
                color += (_RimColor.rgb * fres) * _RimStrength; // additively boost rim

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }

    FallBack Off
}