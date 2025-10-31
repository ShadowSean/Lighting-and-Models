Shader "Alvaro/URP/StandardSpecularPBRURP"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)   // Base color property
        _MetallicTex("Metallic (R)", 2D) = "white" {} // Texture for metallic
        _SpecColor("Specular", Color) = (1,1,1,1) // Specular color
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5 // Smoothness property
        _MainTex("Base Texture", 2D) = "white" {}  // Albedo texture (optional)
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

            // Vertex input structure
            struct Attributes
            {
                float4 positionOS : POSITION;  // Object space position
                float3 normalOS : NORMAL;      // Object space normal
                float2 uv : TEXCOORD0;         // UV for texturing
            };

            // Varying variables passed to the fragment shader
            struct Varyings
            {
                float4 positionHCS : SV_POSITION; // Clip-space position
                float3 normalWS : TEXCOORD1;      // World-space normal for lighting
                float2 uv : TEXCOORD0;            // UV for textures
            };

            // Declare texture samplers and material properties
            TEXTURE2D(_MetallicTex);
            SAMPLER(sampler_MetallicTex);
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;            // Base color
                float4 _SpecColor;        // Specular color
                float _Smoothness;        // Smoothness
            CBUFFER_END

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz); // Convert to clip space
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS)); // Convert normal to world space
                OUT.uv = IN.uv; // Pass UVs for texture sampling
                return OUT;
            }

            // Fragment shader
            half4 frag(Varyings IN) : SV_Target
            {
                // Sample the albedo (base color) texture and metallic texture
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;
                half metallicTex = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, IN.uv).r;

                // Fetch the main light for URP
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);
                half3 normalWS = normalize(IN.normalWS); // World-space normal

                // Lambertian diffuse lighting
                half NdotL = saturate(dot(normalWS, lightDir));

                // Specular reflection using Blinn-Phong
                half3 viewDir = normalize(GetWorldSpaceViewDir(IN.positionHCS.xyz));
                half3 halfDir = normalize(lightDir + viewDir);
                half NdotH = saturate(dot(normalWS, halfDir));

                // Specular term (Blinn-Phong reflection model)
                half3 specular = _SpecColor.rgb * pow(NdotH, _Smoothness * 128.0);

                // Combine diffuse and specular components
                half3 diffuse = baseColor.rgb * NdotL;
                half3 finalColor = diffuse + specular * metallicTex;

                return half4(finalColor, baseColor.a); // Return the final color with alpha
            }

            ENDHLSL
        }
    }
}