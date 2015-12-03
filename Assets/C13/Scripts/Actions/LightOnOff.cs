using UnityEngine;
using System.Collections;

public class LightOnOff : MonoBehaviour {
    public KeyCode key;
    public bool blink;

    Light lit;
	bool litDefault;
    void Start () {
        lit = GetComponent<Light>();
        litDefault = lit.enabled;
    }
	
	// Update is called once per frame
	void Update () {
		if(blink){
			if(Input.GetKey(key))
				lit.enabled = !lit.enabled;
			else
				lit.enabled = litDefault;
		}
		else
			if(Input.GetKeyDown(key))
				lit.enabled = !lit.enabled;
    }
}
