using UnityEngine;
using System.Collections;

public class ShaderSim : MonoBehaviour {
    public Vector3 viewPos;
    [SerializeField]
    Vector4 clipPos;
    [SerializeField]
    Vector3 ndcPos;
    // Use this for initialization
    void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        var cam = Camera.main;
        var n = cam.nearClipPlane;
        var f = cam.farClipPlane;
        var d = f - n;
        var w = viewPos.z;
        var z = w * (2 * (w - n) / d - 1);
        var y = w * (2 * viewPos.y - 1);
        var x = w * (2 * viewPos.x - 1);
        clipPos = new Vector4(x, y, z, w);
        ndcPos = new Vector3(clipPos.x, clipPos.y, clipPos.z) / clipPos.w;
    }
}
