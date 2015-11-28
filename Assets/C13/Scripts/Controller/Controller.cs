﻿using UnityEngine;
    {
        get
        {
            if (_mrtex == null)
                _mrtex = GetComponentInChildren<MultiRenderTexture>();
            return _mrtex;
        }
    }
    {
        var special = Input.GetKey(sceneSpecialKey);
        for(var i = 0; i < utils.Length; i++)
        {
            if(utils[i].isCalled(special))
            {
                SetUtil(utils[i]);
                continue;
            }
        }
    }
    {
        mrtex.updateRenderPasses = util.updatePasses;

        noiseGenerator.SetFloat("_S", util.noiseSpeed);

        particleUpdater.SetFloat("_Scale", util.curlScale);
        particleUpdater.SetFloat("_Speed", util.curlSpeed);
        particleUpdater.SetFloat("_Life", util.pLifeTime);
        particleUpdater.SetFloat("_EmitRate", util.emitRate);

        particleVisualizer.SetFloat("_Size", util.particleSize);
        particleVisualizer.SetColor("_Col0", util.col0);
        particleVisualizer.SetColor("_Col1", util.col1);

        util.cSetting[0].Set();
    }
    {
        public string name = "option";
        public bool specialKey;
        public KeyCode key;

        public int[] updatePasses;
        public float noiseSpeed = 0.2f;
        public float curlScale = 0.04f;
        public float curlSpeed = 0.5f;
        public float pLifeTime = 10f;
        public float emitRate = 0.1f;
        public float particleSize = 0.1f;

        public Color col0, col1;

        public CameraSetting[] cSetting = new CameraSetting[4];

        public bool isCalled(bool special)
        {
            return special == specialKey && Input.GetKeyDown(key);
        }
    }