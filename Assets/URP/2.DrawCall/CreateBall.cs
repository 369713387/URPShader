using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CreateBall : MonoBehaviour
{
    public GameObject ballPrefab;
    public int ballCount = 1000;

    private float step = 2f;

    void Start()
    {
        int xCount = (int)Mathf.Pow(ballCount, 1f / 3f);
        int yCount = xCount;
        int zCount = xCount;

        for (int i = 0; i < xCount; i++)
        {
            for (int j = 0; j < yCount; j++)
            {
                for (int k = 0; k < zCount; k++)
                {
                    GameObject ball = Instantiate(ballPrefab,transform);
                    ball.transform.position = 
                    new Vector3(j * step, k * step, i * step);
                }
            }
        }
    }
}
