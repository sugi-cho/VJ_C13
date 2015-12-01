using UnityEngine;
using System.Collections;
using System.Linq;

public class AddPassAction : MonoBehaviour {
    public int[] passes;
	Controller controller{
		get{
			if(_controller == null)
                _controller = FindObjectOfType<Controller>();
            return _controller;
        }
	}
    Controller _controller;
    void Action(){
        controller.mrtex.updateRenderPasses = controller.mrtex.updateRenderPasses.Concat(passes).ToArray();
    }
	
}
