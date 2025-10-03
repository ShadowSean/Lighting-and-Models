Shader "Alvaro/URP/ToggleableLightingURP_Checkboxes"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _MainTex ("Base Texture", 2D) = "white" {}
        _SpecColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Shininess ("Shininess", Range(0.1, 100)) = 16

        [Toggle] _UseDiffuse ("Enable Diffuse", Float) = 1
        [Toggle] _UseAmbient ("Enable Ambient", Float) = 1
        [Toggle] _UseSpecular ("Enable Specular", Float) = 1
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
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD1;
                float3 viewDirWS : TEXCOORD2;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _SpecColor;
                float _Shininess;

                float _UseDiffuse;
                float _UseAmbient;
                float _UseSpecular;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                float3 worldPosWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.viewDirWS = normalize(GetCameraPositionWS() - worldPosWS);
                OUT.uv = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                half4 texColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 normalWS = normalize(IN.normalWS);
                half NdotL = saturate(dot(normalWS, lightDir));

                // Base color
                half3 base = texColor.rgb * _BaseColor.rgb;

                // Individual lighting terms
                half3 diffuse = base * NdotL;
                half3 ambient = SampleSH(normalWS) * base;
                half3 reflectDir = reflect(-lightDir, normalWS);
                half3 viewDir = normalize(IN.viewDirWS);
                half specFactor = pow(saturate(dot(reflectDir, viewDir)), _Shininess);
                half3 specular = _SpecColor.rgb * specFactor;

                // Start with black and add contributions conditionally
                half3 finalColor = 0;

                if (_UseDiffuse > 0.5) finalColor += diffuse;
                if (_UseAmbient > 0.5) finalColor += ambient;
                if (_UseSpecular > 0.5) finalColor += specular;

                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }
}
