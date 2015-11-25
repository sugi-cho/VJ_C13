using UnityEngine;
using System.Collections;

public class SetMatrixPropertyToMaterial : MonoBehaviour
{
    public string prefix = "_Cam";

    [SerializeField]
    string
        propModelToWorld = "_MATRIX_O2W",
        propWorldToModel = "_MATRIX_W2O",
        propWorldToCam = "_MATRIX_W2C",
        propCamToWorld = "_MATRIX_C2W",
        propCamProjection = "_MATRIX_PROJECTION",
        propCamVP = "_MATRIX_VP",
        propScreenToCam = "_Matrix_S2C",
        propProjectionParams = "_PParams",
        propScreenParams = "_SParams";

    public Material targetMat;

	Camera cam;

	// Use this for initialization
	void Start ()
	{
		cam = GetComponent<Camera> ();
	}
	
	// Update is called once per frame
	void Update ()
	{
		if (transform.hasChanged)
			SetParams ();
		transform.hasChanged = false;
	}

	void SetParams ()
	{
		var modelToWorld = transform.localToWorldMatrix;
		var worldToModel = transform.worldToLocalMatrix;

		if (targetMat != null) {
			targetMat.SetMatrix (prefix+propModelToWorld, modelToWorld);
			targetMat.SetMatrix (prefix+propWorldToModel, worldToModel);
		} else {
			Shader.SetGlobalMatrix (prefix+propModelToWorld, modelToWorld);
			Shader.SetGlobalMatrix (prefix+propWorldToModel, worldToModel);
		}

		if (cam != null) {
			SetCamParams ();
		}
	}
	void SetCamParams ()
	{
		var worldToCam = cam.worldToCameraMatrix;
		var camToWorld = cam.cameraToWorldMatrix;
		var projection = GL.GetGPUProjectionMatrix (cam.projectionMatrix, false);
		var inverseP = projection.inverse;
		var vp = projection * worldToCam;
		var screenToWorld = camToWorld * inverseP;
        var projectionParams = new Vector4(1f, cam.nearClipPlane, cam.farClipPlane, 1f / cam.farClipPlane);
		var screenParams = new Vector4 (cam.pixelWidth, cam.pixelHeight, 1f + 1f / (float)cam.pixelWidth, 1f + 1f / (float)cam.pixelHeight);

        if (targetMat != null) {
			targetMat.SetMatrix (prefix+ propWorldToCam, worldToCam);
			targetMat.SetMatrix (prefix+propCamProjection, projection);
			targetMat.SetMatrix (prefix+propCamVP, vp);
            targetMat.SetMatrix (prefix+propScreenToCam, inverseP);
			targetMat.SetMatrix (prefix+propCamToWorld, camToWorld);
            targetMat.SetVector (prefix+propProjectionParams, projectionParams);
			targetMat.SetVector (prefix+propScreenParams, screenParams);
        } else {
			Shader.SetGlobalMatrix (prefix+propWorldToCam, worldToCam);
			Shader.SetGlobalMatrix (prefix+propCamProjection, projection);
			Shader.SetGlobalMatrix (prefix+propCamVP, vp);
            Shader.SetGlobalMatrix (prefix+propScreenToCam, inverseP);
			Shader.SetGlobalMatrix (prefix+propCamToWorld, camToWorld);
            Shader.SetGlobalVector (prefix+propProjectionParams, projectionParams);
			Shader.SetGlobalVector (prefix+propScreenParams, screenParams);
		}
	}
}
