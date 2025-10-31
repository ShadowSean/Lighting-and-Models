Shader "Custom/URP_StencilRead_Hole_BackObject"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}  // Main texture
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "Queue" = "Geometry" }

        // Stencil operations
        Stencil
        {
            Ref 1  // Reference value to check against
            Comp NotEqual  // Only render where the stencil buffer is NOT equal to the reference
        }

        // Standard pass
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Include URP core functionality
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;  // Object space position
                float2 uv : TEXCOORD0;         // UV coordinates for texture sampling
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;  // Clip-space position
                float2 uv : TEXCOORD0;             // UV coordinates passed to fragment shader
            };

            // Texture sampler
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);  // Transform position to clip space
                OUT.uv = IN.uv;  // Pass UV coordinates
                return OUT;
            }

            // Fragment shader
            half4 frag(Varyings IN) : SV_Target
            {
                // Sample texture using UV coordinates
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                return texColor;  // Output the texture color
            }

            ENDHLSL
        }
    }
}