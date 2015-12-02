using UnityEngine;
using System.Collections;

public class SceneInfo : MonoBehaviour {
    public int[] updatePasses;
    public float noiseSpeed = 0.2f;
    public float curlScale = 0.04f;
    public float curlSpeed = 0.5f;
    public float pLifeTime = 10f;
    public float emitRate = 0.1f;

    public Color col0, col1;

    public CameraSetting[] cSetting = new CameraSetting[4];
    public GameObject[]
   		ActionTarget0,
    	ActionTarget1,
    	ActionTarget2,
    	ActionTarget3;

    CameraSetting currentCamera;
	
	Controller controller{
		get{
			if(_controller == null)
                _controller = FindObjectOfType<Controller>();
            return _controller;
        }
	}
    Controller _controller;
	
	void Start(){
    }
	void SetCamera(int index){
		if(cSetting[index]==null)
            return;
        currentCamera = cSetting[index];
        currentCamera.Init();
	}
	public void Init(SceneInfo preScene){
		if(preScene != null&&preScene.currentCamera!=null)
            currentCamera = preScene.currentCamera;
    }
    public void SceneUpdate()
	{
		if(currentCamera != null)
            currentCamera.CameraUpdate();

        if(Input.anyKeyDown){
			if(Input.GetKeyDown(controller.button0))
                foreach(var go in ActionTarget0)
                    go.BroadcastMessage("Action", SendMessageOptions.DontRequireReceiver);
            else if(Input.GetKeyDown(controller.button1))
                foreach(var go in ActionTarget1)
                    go.BroadcastMessage("Action", SendMessageOptions.DontRequireReceiver);
            else if(Input.GetKeyDown(controller.button2))
                foreach(var go in ActionTarget2)
                    go.BroadcastMessage("Action", SendMessageOptions.DontRequireReceiver);
            else if(Input.GetKeyDown(controller.button3))
                foreach(var go in ActionTarget3)
                    go.BroadcastMessage("Action", SendMessageOptions.DontRequireReceiver);
					
			if(Input.GetKeyDown(controller.camButton0))
                SetCamera(0);
			else if(Input.GetKeyDown(controller.camButton1))
                SetCamera(1);
			else if(Input.GetKeyDown(controller.camButton2))
                SetCamera(2);
			else if(Input.GetKeyDown(controller.camButton3))
                SetCamera(3);
        }
    }
}
