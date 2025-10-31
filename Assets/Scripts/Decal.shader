Shader "Custom/URP_DecalWithToggle"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}  // Main texture
        _DecalTex ("Decal Texture", 2D) = "white" {}  // Decal texture
        [Toggle] _ShowDecal ("Show Decal?", Float) = 0  // Toggle to show/hide decal
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }

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

            // Texture samplers
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            TEXTURE2D(_DecalTex);
            SAMPLER(sampler_DecalTex);
            float _ShowDecal;  // Toggle for showing decal

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);  // Transform to clip space
                OUT.uv = IN.uv;  // Pass UVs to fragment shader
                return OUT;
            }

            // Fragment shader: blend decal with main texture based on toggle
            half4 frag(Varyings IN) : SV_Target
            {
                // Sample the main texture
                half4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // Sample the decal texture
                half4 decalTexColor = SAMPLE_TEXTURE2D(_DecalTex, sampler_DecalTex, IN.uv);

                // If _ShowDecal is 1, blend the decal with the main texture; otherwise, use the main texture only
                half4 finalColor = (_ShowDecal == 1) ? mainTexColor + decalTexColor : mainTexColor;

                return finalColor;
            }

            ENDHLSL
        }
    }
}