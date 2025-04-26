Shader "Yifun/BasicURP_Unlit_GPUInstancing"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
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

            // 顶点着色器输入结构体
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID // 支持实例化
            };

            // 顶点着色器输出结构体
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID // 支持实例化
            };
            
            // 实例化缓冲区
            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                // 定义实例化属性
	            UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            // 顶点着色器
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                // 设置实例ID
                UNITY_SETUP_INSTANCE_ID(IN); 
                // 传递实例ID到片段着色器
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT); 
                // 将顶点从对象空间转换为裁剪空间
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                // 将纹理坐标从对象空间转换为纹理空间
                OUT.uv = IN.uv;
                return OUT;
            }
    
            // 片段着色器
            half4 frag(Varyings IN) : SV_Target
            {
                // 片段着色器中设置实例ID
                UNITY_SETUP_INSTANCE_ID(IN); 
                // 访问实例化属性
                half4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
                return color;
            }
            ENDHLSL
        }
    }
}