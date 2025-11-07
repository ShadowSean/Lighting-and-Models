Shader "Alvaro/URP_Extrude"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Amount ("Extrude", Range(0.0, 0.01)) = 0.001
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float _Amount;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
            };

            // Vertex Shader (extrusion happens here)
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Extrude along vertex normal
                float3 extrudedPosition = IN.positionOS.xyz + IN.normalOS * _Amount;

                OUT.positionCS = TransformObjectToHClip(extrudedPosition);
                OUT.uv = IN.uv;
                OUT.worldNormal = normalize(TransformObjectToWorldNormal(IN.normalOS));

                return OUT;
            }

            // Fragment Shader (lighting + texture)
            half4 frag(Varyings IN) : SV_Target
            {
                half4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 lightColor = mainLight.color;

                half NdotL = max(dot(IN.worldNormal, lightDir), 0.0);
                half3 finalColor = albedo.rgb * lightColor * NdotL;

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }
    }
}
