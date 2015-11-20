Shader "Hidden/AudioVisualize"
{
	Properties
	{
		_MainTex("tex",2D) = "black"{}
	}
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
		
		uniform sampler2D _AudioTex;
		uniform sampler2D _MainTex;
		half4 _AudioTex_TexelSize;

		half4 frag (v2f i) : SV_Target
		{
			half d = _AudioTex_TexelSize.y;
			half t = saturate((i.uv.y-d)/d);
			half4 audio = tex2D(_MainTex, i.uv);
			i.uv.y -= d;
			half4 col = tex2D(_AudioTex, i.uv);
			return lerp(audio,col,t);
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
