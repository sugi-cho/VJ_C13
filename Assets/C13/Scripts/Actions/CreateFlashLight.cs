using UnityEngine;
using System.Collections;

public class CreateFlashLight : MonoBehaviour {
    public KeyCode key;
    Camera cam;
    // Use this for initialization
    void Start () {
        cam = Camera.main;
    }
	
	// Update is called once per frame
	void Update () {
		if(Input.GetKey(key))
            CreateLit();
    }
	void CreateLit(){
		
        var pos = new Vector3(Random.value, Random.value, Random.value);
        pos.z = Mathf.Lerp(cam.nearClipPlane, cam.farClipPlane*0.5f, pos.z);
        pos = cam.ViewportToWorldPoint(pos);

        var lit = new GameObject("lit").AddComponent<Light>();
        lit.color = new Color(Random.value, Random.value, Random.value);
        lit.range = 10;
        lit.type = LightType.Point;
        lit.intensity = 30f;
        lit.shadows = LightShadows.Soft;

        lit.transform.position = pos;
        lit.transform.parent = transform;
        Destroy(lit.gameObject, 0.1f);
    }
}
