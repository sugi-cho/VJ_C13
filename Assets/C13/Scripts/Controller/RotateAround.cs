using UnityEngine;
using System.Collections;

public class RotateAround : MonoBehaviour {
    public Vector3 rotPos;
    public Vector3 rotation;
    // Use this for initialization
    void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        transform.RotateAround(rotPos, rotation.normalized, rotation.magnitude * Time.deltaTime);
    }
}
