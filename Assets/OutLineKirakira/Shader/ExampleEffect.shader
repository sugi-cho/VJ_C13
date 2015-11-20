Shader "Hidden/ExampleEffect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_KC ("kirakira color", Color) = (1,0,0,0)
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
		uniform sampler2D _FNoise;
		sampler2D _MainTex;
		half4 _MainTex_TexelSize,_KC;

		half4 frag (v2f i) : SV_Target
		{
			float2 d = _MainTex_TexelSize.xy;
			
			half4 col = tex2D(_MainTex, i.uv);
			half n = saturate(tex2D(_FNoise, i.uv).r);
			col.rgb += _KC.rgb*n.r * col.a;
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
			
			ENDCG
		}
	}
}
