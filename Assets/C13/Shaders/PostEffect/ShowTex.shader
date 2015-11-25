﻿Shader "Hidden/ShowTex"
{
	CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};

		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = v.uv;
			return o;
		}
		
		uniform sampler2D _CompTex,_FlowTex;
		sampler2D _MainTex;

		half4 frag (v2f i) : SV_Target
		{
			half4 col = tex2D(_CompTex, i.uv);
			return col;
		}
	ENDCG
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma  target 3.0
			
			ENDCG
		}
	}
}
