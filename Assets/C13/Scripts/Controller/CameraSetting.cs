using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

public class CameraSetting : MonoBehaviour {
	public float targetDistance = 10f;
	public float farDistanc = 30f;

	Camera cam;
	DepthOfField dof;

	// Use this for initialization
	void Start()
	{
		cam = Camera.main;
		dof = cam.GetComponent<DepthOfField>();
	}
	public void Set()
    {
		dof.focalLength = targetDistance;
    }
	public void CameraUpdate()
	{

	}
}
