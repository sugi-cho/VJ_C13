using UnityEngine;
using System.Collections;

public class Controller : MonoBehaviour {
    public int sqrtNumParticles = 256;
    public Material
        particleVisualizer,
        particleUpdater,
        noiseGenerator;
    public KeyCode sceneSpecialKey;
    public SceneKeySetting[] keySettings;

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

        Application.targetFrameRate = 60;
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;
    }
	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
        SelectScene();
	}
    void SelectScene()
    {
        var special = Input.GetKey(sceneSpecialKey);
        for(var i = 0; i < keySettings.Length; i++)
        {
            if(keySettings[i].isCalled(special))
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

        particleVisualizer.SetFloat("_Size", scene.particleSize);
        particleVisualizer.SetColor("_Col0", scene.col0);
        particleVisualizer.SetColor("_Col1", scene.col1);

        scene.cSetting[0].Set();
        currentScene = scene;
    }

    [System.Serializable]
    public class SceneKeySetting
    {
        public bool specialKey;
        public KeyCode key;
        public SceneInfo scene;

        public bool isCalled(bool special)
        {
            return special == specialKey && Input.GetKeyDown(key);
        }
    }
}
