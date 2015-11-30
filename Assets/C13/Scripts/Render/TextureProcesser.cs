using UnityEngine;
using System.Collections;

public class TextureProcesser : MonoBehaviour {
    public Texture original;
    public Material processMat;
    public string propName = "_ProcessedTex";
    public bool blur;

    [SerializeField]
    RenderTexture rt,rtb;
    // Use this for initialization
    void Start () {
        rt = Extensions.CreateRenderTexture(original.width, original.height, rt);
        Shader.SetGlobalTexture(propName, rt);
		
    }
	void OnDestroy(){
        Extensions.ReleaseRenderTexture(rt);
    }
	
	// Update is called once per frame
	void Update () {
        Graphics.Blit(original, rt, processMat);
		if(blur)
            rt.GetBlur(0.1f, 3);
    }
}
