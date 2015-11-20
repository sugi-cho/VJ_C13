using UnityEngine;
using System.Collections;
using System.Linq;

public class AudioInput : MonoBehaviour
{
	public Texture2D audioTex;
	public string propTex = "_AudioTex";
	public string propVolume = "_AudioVolume";
	public int numData = 256;
	public float maxAmp = 1f;
	public Material processMat;

	[SerializeField]
	RenderTexture[]
		rts = new RenderTexture[2];

	float offset;
	float amp;
	AudioSource aSource;
	float[] spectrum;
	// Use this for initialization
	void Start ()
	{
		aSource = gameObject.AddComponent<AudioSource> ();
		aSource.clip = Microphone.Start ("", true, 9999, 44100);
		aSource.loop = true;
		while (!(Microphone.GetPosition("")>0)) {
		}
		aSource.Play ();

		spectrum = new float[numData];
		audioTex = new Texture2D (numData, 1, TextureFormat.RGB24, false);

		CreateRts ();
	}

	void CreateRts ()
	{
		for (var i = 0; i < rts.Length; i++) 
			rts [i] = Extensions.CreateRenderTexture (numData, 512, rts [i]);
	}
	void SwapRts ()
	{
		var tmp = rts [0];
		rts [0] = rts [1];
		rts [1] = tmp;
	}
	
	// Update is called once per frame
	void Update ()
	{
		aSource.GetSpectrumData (spectrum, 0, FFTWindow.BlackmanHarris);
		spectrum = spectrum.Select (b => Mathf.Log10 (b)).ToArray ();
		var min = Mathf.Min (spectrum);
		var max = Mathf.Max (spectrum);
		if (float.IsNaN (offset))
			offset = -min;
		else
			offset = Mathf.Lerp (offset, -min, Time.deltaTime);
		if (float.IsNaN (amp))
			amp = 1f - (max - min);
		else
			amp = Mathf.Lerp (amp, 1f / (max - min), Time.deltaTime);
		amp = Mathf.Min (maxAmp, amp);
		spectrum = spectrum.Select (b => (b + offset) * amp).ToArray ();

		var cs = spectrum.Select (b => Color.red * b).ToArray ();
		audioTex.SetPixels (cs);
		audioTex.Apply ();

		Graphics.Blit (audioTex, rts [0], processMat);
		Shader.SetGlobalTexture (propTex, rts [0]);
		SwapRts ();
	}
}
