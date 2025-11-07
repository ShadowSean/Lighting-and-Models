Shader "URP_OutlineBasic"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _Outline ("Outline Width", Range(-0.01, 0.11)) = 0.0
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }
        Tags { "Queue" = "Transparent" }

        Pass
        {
            Name "Texture Color"
            ZWrite On
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vertTex
            #pragma fragment fragTex

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            struct Attributes
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 position     : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 worldNormalT : TEXCOORD1;
            };

            // Vertex Shader
            Varyings vertTex(Attributes IN)
            {
                Varyings OUT;

                OUT.position = TransformObjectToHClip(IN.vertex);
                OUT.uv = IN.uv;
                OUT.worldNormalT = normalize(TransformObjectToWorldNormal(IN.normal));

                return OUT;
            }

            // Fragment Shader
            half4 fragTex(Varyings IN) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                half NdotL = max(dot(IN.worldNormalT, lightDir), 0.0);
                half3 finalColor = albedo.rgb * lightColor * NdotL;

                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }
}
