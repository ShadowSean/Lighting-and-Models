Shader "URP/FlatShadingURP"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)   // Base color of the object
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType" = "Opaque" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;  // Object space position
                float3 normalOS : NORMAL;      // Object space normal
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // Homogeneous clip-space position
                float3 posWS : TEXCOORD0;         // World space position
                float3 normalWS : TEXCOORD1;      // Interpolated world space normal (for lighting)
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;   // Base color property
            CBUFFER_END

            // Vertex Shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Transform object space position to world space
                OUT.posWS = TransformObjectToWorld(IN.positionOS.xyz);
                
                // Transform object space position to homogeneous clip-space
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);

                // Pass the world space normal (we'll recompute it in the fragment shader)
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                return OUT;
            }

            // Fragment Shader
            half4 frag(Varyings IN) : SV_Target
            {
                // Recalculate face normal using the pixel derivatives in world space
                float3 edge1 = ddx(IN.posWS);
                float3 edge2 = ddy(IN.posWS);
                half3 faceNormalWS = normalize(cross(edge1, edge2));

                // Fetch the main light in URP
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);

                // Invert the dot product for proper lighting
                half NdotL = saturate(dot(faceNormalWS, -lightDir)); // Inverted light direction

                // Multiply base color by the diffuse lighting term (NdotL)
                half3 finalColor = _BaseColor.rgb * NdotL;

                return half4(finalColor, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}