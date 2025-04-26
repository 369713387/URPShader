Shader "Yifun/BasicURP_Unlit"
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

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            float4 _BaseMap_ST;
            half4 _BaseColor;

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