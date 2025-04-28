struct Surface
{
    // 物体表面法线
    float3 normal;
    // 物体表面颜色
    float3 color;
    // 视角方向
    float3 viewDirection;
    // 透明度
    float alpha;

    // 金属度
    float metallic;
    // 光滑度
    float smoothness;
};
