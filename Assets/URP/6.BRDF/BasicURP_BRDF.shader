Shader "Yifun/BasicURP_BRDF"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}

        _LightDirection ("Light Direction", Vector) = (0, 1, 0, 0)
        _LightColor ("Light Color", Color) = (1, 1, 1)

        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Smoothness ("Smoothness", Range(0,1)) = 0.5
        
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        
        // 预乘Alpha, 在渲染时将Alpha值与颜色值相乘，以避免在渲染时出现透明度问题
        [Toggle(_PREMULTIPLY_ALPHA)] _PremulAlpha ("Premul Alpha", Float) = 0
    }
    SubShader
    {
        Pass
        {
            Name "Forward"
            Tags
            { 
                "Queue" = "Transparent"
                "RenderType" = "Transparent"
                "RenderPipeline" = "UniversalPipeline"
                "LightMode" = "UniversalForward" 
            }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma shader_feature _PREMULTIPLY_ALPHA

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
            #include "Assets/URP/Common/ShaderStruct/Surface.hlsl"
            #include "Assets/URP/Common/ShaderStruct/Light.hlsl"
            #include "Assets/URP/Common/ShaderStruct/BRDF.hlsl"
            
            // 非金属材质的最小反射率0.04（4%的光被反射，这是大多数非金属材质的平均值）
            #define MIN_REFLECTIVITY 0.04
            
            #ifndef CUSTOM_LIGHTING_INCLUDED
                #define CUSTOM_LIGHTING_INCLUDED

                // 计算入射光
                float3 IncomingLight(Surface surface, Light light)
                {
                    return saturate(dot(surface.normal, light.direction)) * light.color * light.intensity;
                }

                // 计算镜面反射强度（使用GGX分布）
                float SpecularStrength(Surface surface, BRDFData brdf, Light light)
                {
                    // 计算半向量
                    float3 h = SafeNormalize(light.direction + surface.viewDirection);
                    // 计算半向量和法线的点积
                    float ndoth = max(0, dot(surface.normal, h));
                    // 计算分子
                    float alpha = brdf.roughness * brdf.roughness;
                    float alpha2 = alpha * alpha;
                    // 计算分母（添加0.0001防止除零）
                    float denom = (ndoth * ndoth) * (alpha2 - 1.0) + 1.0001;
                    return alpha2 / (PI * denom * denom);
                }

                // 计算直接光照
                float3 DirectBRDF(Surface surface, BRDFData brdf, Light light)
                {
                    // 漫反射 + 镜面反射
                    return brdf.diffuse + SpecularStrength(surface, brdf, light) * brdf.specular;
                }

                // 计算最终光照
                float3 GetLighting(Surface surface, BRDFData brdf, Light light)
                {
                    return IncomingLight(surface, light) * DirectBRDF(surface, brdf, light);
                }
            #endif

            #ifndef CUSTOM_BRDF_INCLUDED
                #define CUSTOM_BRDF_INCLUDED
                // 计算BRDF数据
                BRDFData GetBRDFData(Surface surface,float applyAlphaToDiffuse)
                {
                    BRDFData brdf;
                    // 漫反射 = 表面颜色 * (1 - 金属度)
                    brdf.diffuse = surface.color * (1 - surface.metallic); 
                    // 如果需要应用Alpha到漫反射，则将漫反射乘以Alpha
                    // if(applyAlphaToDiffuse)
                    // {
                        //     brdf.diffuse *= surface.alpha;
                    // }
                    // shader中if判断性能较低，使用lerp替代
                    // 当applyAlphaToDiffuse为true (1)时，乘以surface.alpha
                    // 当applyAlphaToDiffuse为false (0)时，乘以1（不变）
                    brdf.diffuse *= lerp(1.0, surface.alpha, applyAlphaToDiffuse);
                    // 镜面反射 = 基于金属度进行插值
                    // 金属材质时为表面颜色（金属材质的反射颜色由表面颜色决定）
                    brdf.specular = lerp(MIN_REFLECTIVITY, surface.color, surface.metallic);
                    // 感知粗糙度 = 1 - 光滑度（CommonMaterial.hlsl源码中可以找到）
                    float perceptualRoughness =
                    PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
                    // 物理粗糙度 = 感知粗糙度 * 感知粗糙度（CommonMaterial.hlsl源码中可以找到）
                    brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
                    return brdf;
                }

            #endif

            struct Attributes
            {
                // 物体空间位置
                float4 positionOS : POSITION;
                // 物体空间法线
                float3 normalOS : NORMAL;
                // 纹理坐标
                float2 uv : TEXCOORD0;
            };

            struct Varyings
            {
                // 裁剪空间位置
                float4 positionCS : SV_POSITION;
                // 世界空间位置
                float3 positionWS : TEXCOORD0;
                // 世界空间法线
                float3 normalWS : TEXCOORD1;
                // 纹理坐标
                float2 uv : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _LightDirection;
                float3 _LightColor;
                float _Metallic;
                float _Smoothness;
                float _PremulAlpha;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // 将物体空间位置转换为裁剪空间位置
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 将物体空间位置转换为世界空间位置
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                // 将物体空间法线转换为世界空间法线
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                // 将纹理坐标转换为贴图坐标
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                // 采样贴图
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                // 计算视角方向
                float3 viewDirection = normalize(_WorldSpaceCameraPos - IN.positionWS);

                // 创建Surface结构体
                Surface surface;
                surface.normal = normalize(IN.normalWS);
                surface.viewDirection = viewDirection;
                surface.color = baseMap.rgb * _BaseColor.rgb;
                surface.alpha = max(baseMap.a * _BaseColor.a,0.01f);
                surface.metallic = _Metallic;
                surface.smoothness = _Smoothness;

                // 创建Light结构体
                Light light;
                light.direction = normalize(_LightDirection.xyz);
                light.color = _LightColor.rgb;
                light.intensity = _LightDirection.w;

                // 计算BRDF数据
                #if defined(_PREMULTIPLY_ALPHA)
                    // 预乘Alpha
                    BRDFData brdf = GetBRDFData(surface, _PremulAlpha);
                #else
                    BRDFData brdf = GetBRDFData(surface, _PremulAlpha);
                #endif
                
                // 计算最终颜色
                float3 finalColor = GetLighting(surface, brdf, light);
                return half4(finalColor, surface.alpha);
            }

            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
