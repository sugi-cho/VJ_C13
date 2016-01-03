using UnityEngine;
using System.Collections;

public class Controller : MonoBehaviour
{
	public int sqrtNumParticles = 256;
	public Material
		particleVisualizer,
		particleUpdater,
		noiseGenerator;
	public KeyCode
		selectSpecialKey,
		button0 = KeyCode.Alpha1,
		button1 = KeyCode.Alpha2,
		button2 = KeyCode.Alpha3,
		button3 = KeyCode.Alpha4,
		button4 = KeyCode.Alpha5,
		button5 = KeyCode.Alpha6,
		button6 = KeyCode.Alpha7,
		button7 = KeyCode.Alpha8,
		camButton0 = KeyCode.W,
		camButton1 = KeyCode.D,
		camButton2 = KeyCode.S,
		camButton3 = KeyCode.A,
		focusIn,
		focusOut,
		brakeKey,
		slowKey;
	public SceneKeySetting[] keySettings;
	public string propDrag = "_Drag";
	public float
		minDrag = 1f,
		maxDrag = 3f;

	[SerializeField]
	SceneInfo currentScene;
	[SerializeField]
	float drag;

	public MultiRenderTexture mrtex {
		get {
			if (_mrtex == null)
				_mrtex = GetComponentInChildren<MultiRenderTexture> ();
			return _mrtex;
		}
	}

	MultiRenderTexture _mrtex;

	void Awake ()
	{
		var mm = GetComponentInChildren<MassMeshes> ();
		mm.numMeshes = sqrtNumParticles * sqrtNumParticles;
		mrtex.util.texSize = sqrtNumParticles;

		Application.targetFrameRate = 30;
#if !UNITY_EDITOR
		{
			Cursor.visible = false;
			Cursor.lockState = CursorLockMode.Locked;
		}
#endif
	}
	// Use this for initialization
	void Start ()
	{
	
	}
	
	// Update is called once per frame
	void Update ()
	{
		SelectScene ();
		drag = Input.GetKey (brakeKey) ? maxDrag : minDrag;
		drag = Mathf.Exp (-drag * Time.deltaTime);
		Shader.SetGlobalFloat (propDrag, drag);
		Time.timeScale = Input.GetKey (slowKey) ? 0.2f : Mathf.Lerp (Time.timeScale, 1f, 0.03f);

	}

	void SelectScene ()
	{
		if (!Input.anyKey)
			return;
		var select = Input.GetKey (selectSpecialKey);
		for (var i = 0; i < keySettings.Length; i++) {
			if (keySettings [i].isCalled (select)) {
				var scene = keySettings [i].scene;
				SetScene (scene);
				continue;
			}
		}
	}

	public void SetScene (SceneInfo scene)
	{
		mrtex.updateRenderPasses = scene.updatePasses;

		noiseGenerator.SetFloat ("_S", scene.noiseSpeed);

		particleUpdater.SetFloat ("_Scale", scene.curlScale);
		particleUpdater.SetFloat ("_Speed", scene.curlSpeed);
		particleUpdater.SetFloat ("_Life", scene.pLifeTime);
		particleUpdater.SetFloat ("_EmitRate", scene.emitRate);
        
		particleVisualizer.SetColor ("_Col0", scene.col0);
		particleVisualizer.SetColor ("_Col1", scene.col1);

		scene.Init (currentScene);
		currentScene = scene;
	}

	void SceneUpdate ()
	{
		currentScene.SceneUpdate ();
	}

	[System.Serializable]
	public class SceneKeySetting
	{
		public string name = "option scene name";
		public bool specialKey;
		public KeyCode key;
		public SceneInfo scene;

		public bool isCalled (bool special)
		{
			return special == specialKey && Input.GetKeyDown (key);
		}
	}
}
