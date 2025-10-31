Shader "Alvaro/URP/StandardPBRURP"
{
    Properties
    {
        _Color("Color", Color) = (1,1,1,1)   // Base color property
        _MetallicTex("Metallic (R)", 2D) = "white" {} // Texture for metallic
        _Metallic("Metallic", Range(0.0, 1.0)) = 0.0  // Metallic value property
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

            // Define input structure for vertex data
            struct Attributes
            {
                float4 positionOS : POSITION;  // Object space position
                float3 normalOS : NORMAL;      // Object space normal
                float2 uv : TEXCOORD0;         // Texture UV for base and metallic map
            };

            // Define varying structure for interpolated data passed to the fragment shader
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;  // Clip space position
                float3 normalWS : TEXCOORD1;       // World space normal for lighting
                float2 uv : TEXCOORD0;             // UV coordinates for textures
            };

            // Define texture samplers and material properties
            TEXTURE2D(_MetallicTex);
            SAMPLER(sampler_MetallicTex);
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;            // Color property
                float _Metallic;          // Metallic property
                float _Smoothness;        // Smoothness property
            CBUFFER_END

            // Vertex shader
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Transform object space position to homogeneous clip-space
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                
                // Transform object space normal to world space
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                
                // Pass the UVs for texture sampling
                OUT.uv = IN.uv;

                return OUT;
            }

            // Fragment shader
            half4 frag(Varyings IN) : SV_Target
            {
                // Sample base color texture
                half4 baseColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv) * _Color;

                // Sample metallic value from texture (R channel)
                half metallicTex = SAMPLE_TEXTURE2D(_MetallicTex, sampler_MetallicTex, IN.uv).r;

                // Calculate final metallic and smoothness
                half metallic = lerp(metallicTex, _Metallic, _Metallic);
                half smoothness = _Smoothness;

                // Get the main light (in URP)
                Light mainLight = GetMainLight();
                half3 lightDir = normalize(mainLight.direction);

                // Normalize the world space normal
                half3 normalWS = normalize(IN.normalWS);

                // Calculate Lambertian diffuse lighting (NdotL)
                half NdotL = saturate(dot(normalWS, lightDir));

                // Calculate Fresnel effect
                half3 viewDir = normalize(GetWorldSpaceViewDir(IN.positionHCS.xyz));
                half fresnel = pow(1.0 - saturate(dot(viewDir, normalWS)), 5.0);

                // Combine base color with lighting and PBR metallic/smoothness effects
                half3 diffuse = baseColor.rgb * NdotL;
                half3 specular = lerp(half3(0.04, 0.04, 0.04), baseColor.rgb, metallic) * fresnel * smoothness;

                // Combine diffuse and specular lighting
                half3 finalColor = diffuse + specular;

                return half4(finalColor, baseColor.a); // Return color with alpha channel
            }

            ENDHLSL
        }
    }
}