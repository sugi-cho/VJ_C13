using UnityEngine;
using System.Collections;

public class ViewToWorldTransformation : MonoBehaviour {
    public Vector3 viewPos;
    public Transform target;
    [SerializeField]
    Vector4 clipPos;
    [SerializeField]
    Vector3 ndcPos;
    [SerializeField]
    Vector3 worldPos;
	void Start(){
		if(target == null)
            target = GameObject.CreatePrimitive(PrimitiveType.Sphere).transform;
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
		
		var camToWorld = cam.cameraToWorldMatrix;
		var projection = GL.GetGPUProjectionMatrix (cam.projectionMatrix, false);
		var inverseP = projection.inverse;

        var camPos = inverseP * clipPos;
        camPos.w = 1f;
        worldPos = camToWorld * camPos;
        target.transform.position = worldPos;
    }
}
