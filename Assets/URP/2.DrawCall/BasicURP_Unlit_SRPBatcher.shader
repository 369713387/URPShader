Shader "Yifun/BasicURP_Unlit_SRPBatcher"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _BaseMap ("Base Map", 2D) = "white" {}
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
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // 顶点着色器输入结构体
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
            };

            // 顶点着色器输出结构体
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // 旧式方式（不推荐）
            //sampler2D _BaseMap;

            // 现代URP方式（推荐）
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            //在URP中，CBUFFER_START(UnityPerMaterial) 特别重要的原因：
            //1.Unity的SRP Batcher（可编程渲染管线批处理器）需要所有材质属性都在一个常量缓冲区中
            //2.使用 UnityPerMaterial 缓冲区是启用SRP Batcher的必要条件
            //3.可以大大提高渲染性能，特别是当场景中有多个使用相同shader的物体时

            // 使用常量缓冲区的方式（推荐）
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                half4 _BaseColor;
            CBUFFER_END

            // 不使用常量缓冲区的方式（不推荐）
            // float4 _BaseMap_ST;
            // half4 _BaseColor;

            // 顶点着色器
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // 将顶点从对象空间转换为裁剪空间
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 将纹理坐标从对象空间转换为纹理空间
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }
    
            // 片段着色器
            half4 frag(Varyings IN) : SV_Target
            {
                // 采样纹理
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                // 计算最终颜色
                half4 finalColor = baseMap * _BaseColor;
                return finalColor;
            }
            ENDHLSL
        }
    }
}