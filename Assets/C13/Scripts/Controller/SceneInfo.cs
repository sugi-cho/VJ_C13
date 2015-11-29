using UnityEngine;
using System.Collections;

public class SceneInfo : MonoBehaviour {
    public int[] updatePasses;
    public float noiseSpeed = 0.2f;
    public float curlScale = 0.04f;
    public float curlSpeed = 0.5f;
    public float pLifeTime = 10f;
    public float emitRate = 0.1f;

    public Color col0, col1;

    public CameraSetting[] cSetting = new CameraSetting[4];

    // Use this for initialization
    void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
