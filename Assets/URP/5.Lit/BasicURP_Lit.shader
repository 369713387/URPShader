Shader "Yifun/BasicURP_Lit"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}

        _LightDirection ("Light Direction", Vector) = (0, 1, 0, 0)
        _LightColor ("Light Color", Color) = (1, 1, 1)
    }
    
    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing 
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/URP/Common/ShaderStruct/Surface.hlsl"
            #include "Assets/URP/Common/ShaderStruct/Light.hlsl"
            
            #ifndef CUSTOM_LIGHTING_INCLUDED
            #define CUSTOM_LIGHTING_INCLUDED
            float3 GetLighting1(Surface surface)
            {
                //模拟正上方往下照射的光照
                return surface.normal.y * surface.color;
            }
            
            float3 IncomingLight (Surface surface, Light light)
            {
                // 计算光照方向
                return saturate(dot(surface.normal, light.direction)) * light.color * light.intensity;
            }

            float3 GetLighting2(Surface surface, Light light)
            {
                // 计算光照
                return IncomingLight(surface, light) * surface.color;
            }
            #endif

            // 顶点着色器输入结构体
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 顶点着色器输出结构体
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float2 uv : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            // 纹理声明
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            // 实例化缓冲区
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_TexelSize)
                UNITY_DEFINE_INSTANCED_PROP(float4, _LightDirection)
                UNITY_DEFINE_INSTANCED_PROP(float3, _LightColor)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            // 顶点着色器
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // 设置实例ID
                UNITY_SETUP_INSTANCE_ID(IN); 
                // 传递实例ID到片段着色器
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT); 
                // 将顶点从对象空间转换为世界空间
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                // 将世界空间位置转换为裁剪空间位置
                OUT.positionCS = TransformWorldToHClip(positionWS);
                // 将法线从对象空间转换为世界空间
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                // 将纹理坐标从对象空间转换为纹理空间
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }
    
            // 片段着色器
            half4 frag(Varyings IN) : SV_Target
            {
                // // 测试获取的法线向量是否正确
                // return half4(IN.normalWS, 1);

                //// 观察法线向量没有进行归一化时的效果
                //// 这行代码检查法线向量是否标准化（长度是否为1）
                //// abs(length(IN.normalWS) - 1.0)计算法线长度与1的差值的绝对值
                //// 乘以10是为了放大这个差异，使其在可视化时更明显
                //// 如果法线完全标准化，结果应该是0（黑色）；如果有偏差，会显示为非黑色
                //float3 color = abs(length(IN.normalWS) - 1.0) * 10;

                //// 这行代码将法线向量归一化（长度为1）
                //// 归一化后的法线向量才可以用于光照计算
                //// 如果法线向量没有被正确归一化，可能会导致光照计算不正确
                // float3 n_normal = normalize(IN.normalWS);
                // float3 color = abs(length(n_normal) - 1.0) * 10;
                // return float4(color, 1);

                //// 测试GetLighting1函数
                // // 片段着色器中设置实例ID
                // UNITY_SETUP_INSTANCE_ID(IN); 
                // // 访问实例化属性
                // half4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                // // 创建Surface结构体
                // Surface surface;
                // // 归一化法线向量
                // surface.normal = normalize(IN.normalWS);
                // // 设置颜色
                // surface.color = color.rgb;
                // // 设置透明度
                // surface.alpha = color.a;
                // float3 finalColor = GetLighting1(surface);
                // return float4(finalColor, surface.alpha);

                // 测试GetLighting2函数 
                // 片段着色器中设置实例ID
                UNITY_SETUP_INSTANCE_ID(IN); 
                // 访问实例化属性
                half4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                // 创建Surface结构体
                Surface surface;
                // 归一化法线向量
                surface.normal = normalize(IN.normalWS);
                // 设置颜色
                surface.color = color.rgb;
                // 设置透明度
                surface.alpha = color.a;
                // 创建Light结构体
                Light light;
                float4 lightDirection = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _LightDirection);
                // 设置光照方向
                light.direction = lightDirection.xyz;
                // 设置光照强度
                light.intensity = lightDirection.w;
                // 设置光照颜色
                light.color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _LightColor);
                // 计算光照
                float3 finalColor = GetLighting2(surface, light);
                // 返回最终颜色
                return float4(finalColor, surface.alpha);
            }
            ENDHLSL
        }
    }
}