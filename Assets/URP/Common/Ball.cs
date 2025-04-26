using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Ball : MonoBehaviour
{
    private Material material;

    void Awake()
    {
        material = GetComponent<MeshRenderer>().material;
    }

    void Update()
    {
        material.SetColor("_BaseColor", new Color32(
            (byte)(Mathf.FloorToInt(transform.position.x * 100) % 255),
            (byte)(Mathf.FloorToInt(transform.position.y * 100) % 255),
            (byte)(Mathf.FloorToInt(transform.position.z * 100) % 255), 255));
    }
}
