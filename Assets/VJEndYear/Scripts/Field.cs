using UnityEngine;
using System.Collections;
using UnityStandardAssets.ImageEffects;

public class Field : MonoBehaviour
{
	public float fieldRange = 30f;
	public float shakingDistance = 0;
	public float focalFrec = 0.01f;
	public float freq = 0.01f;

	Controller controller;
	Vector2[] randVectors;
	Camera mainCam;
	DepthOfField dof;

	Vector3 cameraPosTo;
	[SerializeField]
	Quaternion cameraRotTo;

	// Use this for initialization
	void Start ()
	{
		controller = FindObjectOfType<Controller> ();
		mainCam = Camera.main;
		dof = mainCam.GetComponent<DepthOfField> ();

		Shader.SetGlobalVector ("_Field", new Vector2 (fieldRange, 1f / fieldRange));
		randVectors = new Vector2[4];
		for (var i = 0; i < randVectors.Length; i++)
			randVectors [i] = Random.insideUnitCircle.normalized * Mathf.PI * 2f;
		cameraPosTo = mainCam.transform.position;
	}
	
	// Update is called once per frame
	void Update ()
	{
		SetCamera ();
		UpdateCamera ();
		CreateLit ();
	}

	void CreateLit ()
	{
		if (!Input.GetKey (controller.button7))
			return;
		var pos = GetPosRandomInField ();

		var lit = new GameObject ("lit").AddComponent<Light> ();
		lit.color = new Color (Random.value, Random.value, Random.value);
		lit.range = fieldRange;
		lit.type = LightType.Point;
		lit.intensity = fieldRange * 5f;
		lit.shadows = LightShadows.None;

		lit.transform.position = pos;
		Destroy (lit.gameObject, Time.deltaTime);
	}

	void UpdateCamera ()
	{

		//focus
		dof.focalLength = Fbm (randVectors [0] * Time.time * focalFrec) * fieldRange;

		//camera movement
		var t = Time.time * freq;
		var p = new Vector3 (
			        Fbm (randVectors [1] * t),
			        Fbm (randVectors [2] * t),
			        Fbm (randVectors [3] * t)
		        );


		mainCam.transform.position = Vector3.Lerp (
			mainCam.transform.position,
			cameraPosTo + p * shakingDistance, 
			0.1f);
		mainCam.transform.rotation = Quaternion.Slerp (
			mainCam.transform.rotation,
			cameraRotTo,
			0.1f
		);
	}

	void SetCamera ()
	{
		if (!Input.anyKeyDown)
			return;
		if (Input.GetKeyDown (controller.camButton0)) {
			cameraPosTo = new Vector3 (0, 0, -fieldRange);
			cameraRotTo = Quaternion.identity;
		} else if (Input.GetKeyDown (controller.camButton1)) {
			cameraPosTo = Vector3.zero;
			cameraRotTo = Quaternion.identity;
		} else if (Input.GetKeyDown (controller.camButton2)) {
			cameraPosTo = GetPosRandomInField ();
			cameraRotTo = Quaternion.LookRotation (-cameraPosTo);
		} 
		if (Input.GetKeyDown (controller.camButton3))
			shakingDistance = Random.value * fieldRange;
	}

	Vector3 GetPosRandomInField ()
	{
		var x = Random.Range (-fieldRange, fieldRange);
		var y = Random.Range (-fieldRange, fieldRange);
		var z = Random.Range (-fieldRange, fieldRange);
		return new Vector3 (x, y, z);
	}

	float Fbm (Vector2 v2, int oct = 2)
	{
		var v = 0f;
		var f = 1f;
		for (var i = 0; i < oct; i++) {
			v += f * (Mathf.PerlinNoise (v2.x, v2.y) - 0.5f);
			f *= 0.5f;
			v2 *= 2f;
		}
		return v;
	}
}
