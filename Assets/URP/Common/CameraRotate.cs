using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraRotate : MonoBehaviour
{
    // 旋转速度
    public float rotationSpeed = 20.0f;
    // Update is called once per frame
    void Update()
    {
        // 获取当前帧的时间增量
        float deltaTime = Time.deltaTime;

        // 计算旋转角度 (degrees per second * seconds = degrees)
        float rotationAmount = rotationSpeed * deltaTime;

        // 绕世界坐标系的Y轴(0,1,0)为轴心旋转
        transform.RotateAround(Vector3.zero, Vector3.up, rotationAmount);
    }
}
