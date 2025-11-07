Shader "Custom/SimpleShadowsWithTintedShadow"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}  // Texture property
        _ShadowTint ("Shadow Tint Color", Color) = (0, 0, 0, 1) // Tint color for shadows
    }

    SubShader
    {
        Tags { "RenderType" = "AlphaTest" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {
            // Main pass for receiving shadows and texture rendering
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // Declare the texture sampler and shadow tint color
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _ShadowTint;

            // Declare the _MainTex_ST for texture tiling and offset
            float4 _MainTex_ST;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;  // UV coordinates for texture mapping
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float4 shadowCoords : TEXCOORD3;
                float2 uv : TEXCOORD0;  // UV coordinates passed to fragment shader
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);

                // Get the VertexPositionInputs for the vertex position  
                VertexPositionInputs positions = GetVertexPositionInputs(IN.positionOS.xyz);

                // Calculate shadow coordinates manually using a basic approach
                OUT.shadowCoords = TransformWorldToShadowCoord(positions.positionWS);

                // Pass the UV coordinates to the fragment shader, applying tiling and offset
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                // Sample the main texture
                half4 textureColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // Calculate shadow amount from shadow map
                half shadowAmount = MainLightRealtimeShadow(IN.shadowCoords);

                // Tint only the shadow
                half4 tintedShadow = lerp(float4(1, 1, 1, 1), _ShadowTint, shadowAmount);

                // Combine the texture color with tinted shadow
                return textureColor * tintedShadow;
            }

            ENDHLSL
        }

        // Shadow caster pass
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            HLSLPROGRAM

            #pragma vertex vertShadowCaster
            #pragma fragment fragShadowCaster
            #pragma multi_compile_shadowcaster

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 vertex : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
            };

            // Vertex shader for shadow caster pass
            Varyings vertShadowCaster(Attributes IN)
            {
                Varyings OUT;
                OUT.positionCS = TransformObjectToHClip(IN.vertex.xyz); // Transform to clip space
                return OUT;
            }

            // Fragment shader for shadow caster pass
            float4 fragShadowCaster(Varyings i) : SV_Target
            {
                return float4(0, 0, 0, 1);  // Standard output for shadow casting
            }

            ENDHLSL
        }
    }
}