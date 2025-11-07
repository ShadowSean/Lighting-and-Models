Shader "Custom/URP_SimpleLightingWithShadows"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" }

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster

            // Include URP core, lighting, and shadow libraries
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;   // Object space vertex position
                float3 normal : NORMAL;     // Object space normal
                float2 uv : TEXCOORD0;      // UV coordinates for texture sampling
            };

            struct v2f
            {
                float4 pos : SV_POSITION;   // Clip space position
                float2 uv : TEXCOORD0;      // UV coordinates passed to fragment shader
                half3 worldNormal : TEXCOORD1;  // World space normal for lighting
                float3 worldPos : TEXCOORD2;    // World space position for shadow sampling
                float4 shadowCoord : TEXCOORD3; // Shadow coordinates
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            // Vertex Shader
            v2f vert(appdata v)
            {
                v2f o;
                // Transform vertex to clip space
                o.pos = TransformObjectToHClip(v.vertex.xyz);

                // Pass UV coordinates to fragment shader
                o.uv = v.uv;

                // Transform object space normal to world space
                o.worldNormal = normalize(TransformObjectToWorldNormal(v.normal));

                // Store the world position (before the transformation to clip space)
                float3 worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.worldPos = worldPos;

                // Compute shadow coordinates using world position (no truncation warning)
                o.shadowCoord = TransformWorldToShadowCoord(worldPos);

                return o;
            }

            // Fragment Shader
            half4 frag(v2f i) : SV_Target
            {
                // Sample texture
                half4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);

                // Get the main light direction and color
                Light mainLight = GetMainLight();
                half3 lightDirWS = normalize(mainLight.direction);

                // Lambertian lighting calculation
                half NdotL = max(0.0, dot(i.worldNormal, lightDirWS));
                half3 diffuseLight = NdotL * mainLight.color;

                // Sample shadow attenuation for the main light
                half shadowAttenuation = MainLightRealtimeShadow(i.shadowCoord);

                // Combine texture, diffuse lighting, and shadow attenuation
                col.rgb *= diffuseLight * shadowAttenuation;

                return col;
            }

            ENDHLSL
        }
    }
}