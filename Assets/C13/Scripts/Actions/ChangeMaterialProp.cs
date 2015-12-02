using UnityEngine;
using System.Collections;

public class ChangeMaterialProp : MonoBehaviour {
    public string propName = "";
    public Material targetMat;
    public float flotVal;
    public float duration = 1f;

    void Action(){
        StartCoroutine("ChangeValCoroutine");
    }
	IEnumerator ChangeValCoroutine(){
        var t = 0f;
        var v0 = targetMat.GetFloat(propName);
        while(t < 1f){
            targetMat.SetFloat(propName, Mathf.Lerp(v0, flotVal, t));
            yield return t += Time.deltaTime/duration;
        }
    }
}
