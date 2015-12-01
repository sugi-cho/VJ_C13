using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

public class CameraSetting : MonoBehaviour {
	public float targetDistance = 10f;
    public float nearDistance = 1f;
    public float farDistance = 30f;
    public float shakingDistance = 0;
    public float freq = 0.01f;


    float targetFocalLength;
    float focalLevel;
    Vector2[] randVectors;

    Controller controller{
		get{
			if(_controller == null)
                _controller = FindObjectOfType<Controller>();
            return _controller;
        }
	}
    Controller _controller;
    // Use this for initialization
    void Start()
	{
        randVectors = new Vector2[3];
		for(var i = 0; i<randVectors.Length;i++)
            randVectors[i] = Random.insideUnitCircle.normalized * Mathf.PI * 2f;
    }
	public void Init(){
        focalLevel = 0;
        SetFocalLength();
    }
	void SetFocalLength(){
		if(focalLevel < 0)
			targetFocalLength = Mathf.Lerp(nearDistance, targetDistance, (focalLevel + 3f) / 3f);
		else if(focalLevel == 0)
			targetFocalLength = targetDistance;
		else
			targetFocalLength = Mathf.Lerp(targetDistance, farDistance, focalLevel / 3f);
        Shader.SetGlobalFloat("_FocalLength", targetFocalLength);
    }
	public void CameraUpdate()
	{
        var mainCam = Camera.main;
        var dof = mainCam.GetComponent<DepthOfField>();

        dof.focalLength = Mathf.Lerp(dof.focalLength, targetFocalLength, 0.1f);
		
		//focus
		if(Input.anyKeyDown){
			if(Input.GetKeyDown(controller.focusIn))
                focalLevel--;
			else if(Input.GetKeyDown(controller.focusOut))
                focalLevel++;
            focalLevel = Mathf.Clamp(focalLevel, -3f, 3f);
            SetFocalLength();
        }
        
		//camera movement
		var t = Time.time * freq;
        var p = new Vector3(
        	Fbm(randVectors[0] * t),
			Fbm(randVectors[1] * t),
			Fbm(randVectors[2] * t)
        );
		
        mainCam.transform.position = Vector3.Lerp(
			mainCam.transform.position,
			transform.position + p * shakingDistance, 
			0.1f);
        mainCam.transform.rotation = Quaternion.Slerp(
            mainCam.transform.rotation,
            transform.rotation,
            0.1f
        );
    }
	
	float Fbm(Vector2 v2, int oct = 2){
        var v = 0f;
        var f = 1f;
        for(var i = 0; i < oct; i++){
            v += f * (Mathf.PerlinNoise(v2.x, v2.y)-0.5f);
            f *= 0.5f;
            v2 *= 2f;
        }
        return v;
    }
	
}
