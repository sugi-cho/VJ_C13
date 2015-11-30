using UnityEngine;
using System.Collections;

public class Controller : MonoBehaviour {
    public int sqrtNumParticles = 256;
    public Material
        particleVisualizer,
        particleUpdater,
        noiseGenerator;
    public KeyCode
		selectSpecialKey,
		button0,
		button1,
		button2,
		button3;
    public SceneKeySetting[] keySettings;

    [SerializeField]
    SceneInfo currentScene;

    MultiRenderTexture mrtex
    {
        get
        {
            if (_mrtex == null)
                _mrtex = GetComponentInChildren<MultiRenderTexture>();
            return _mrtex;
        }
    }
    MultiRenderTexture _mrtex;

    void Awake() {
        var mm = GetComponentInChildren<MassMeshes>();
        mm.numMeshes = sqrtNumParticles * sqrtNumParticles;
        mrtex.util.texSize = sqrtNumParticles;

        Application.targetFrameRate = 30;
        //Cursor.visible = false;
        //Cursor.lockState = CursorLockMode.Locked;
    }
    // Use this for initialization
    void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        SelectScene();
		if (currentScene != null)
			SceneUpdate();
	}
    void SelectScene()
    {
        if (!Input.anyKey)
            return;
        var select = Input.GetKey(selectSpecialKey);
        for(var i = 0; i < keySettings.Length; i++)
        {
            if(keySettings[i].isCalled(select))
            {
                var scene = keySettings[i].scene;
                SetScene(scene);
                continue;
            }
        }
    }
    public void SetScene(SceneInfo scene)
    {
        mrtex.updateRenderPasses = scene.updatePasses;

        noiseGenerator.SetFloat("_S", scene.noiseSpeed);

        particleUpdater.SetFloat("_Scale", scene.curlScale);
        particleUpdater.SetFloat("_Speed", scene.curlSpeed);
        particleUpdater.SetFloat("_Life", scene.pLifeTime);
        particleUpdater.SetFloat("_EmitRate", scene.emitRate);
        
        particleVisualizer.SetColor("_Col0", scene.col0);
        particleVisualizer.SetColor("_Col1", scene.col1);

        scene.cSetting[0].Set();
        currentScene = scene;
    }
	void SceneUpdate()
	{
		currentScene.SceneUpdate();
	}

    [System.Serializable]
    public class SceneKeySetting
    {
        public string name = "option scene name";
        public bool specialKey;
        public KeyCode key;
        public SceneInfo scene;

        public bool isCalled(bool special)
        {
            return special == specialKey && Input.GetKeyDown(key);
        }
    }
}
