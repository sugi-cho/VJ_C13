Shader "Unlit/TexOutline"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_LC ("line color", Color) = (0,0,1,0)
		_LS ("line size", Float) = 0.01
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
			float4 gPos : TEXCOORD1;
			float4 vertex : SV_POSITION;
		};

		sampler2D _MainTex,_GrabTexture;
		float4 _MainTex_ST,_MainTex_TexelSize;
		half4 _LC;
		float _LS;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
			o.gPos = ComputeGrabScreenPos(o.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			return o;
		}
		
		half4 frag (v2f i) : SV_Target
		{
			float2 d = _MainTex_TexelSize.xy * _LS;
			float2 gUV = i.gPos.xy/i.gPos.w;
			
			half4 grab = tex2D(_GrabTexture, gUV);
			half4 col = tex2D(_MainTex, i.uv);
			half t = col.a;
			
			half
				col00 = tex2D(_MainTex, i.uv+float2(-d.x,-d.y)).a,
				col01 = tex2D(_MainTex, i.uv+float2(-d.x, d.y)).a,
				col10 = tex2D(_MainTex, i.uv+float2( d.x,-d.y)).a,
				col11 = tex2D(_MainTex, i.uv+float2( d.x, d.y)).a;
			half4 line = max(max(col00, col01), max(col10,col11)) - col.a;
			col.a *= 0;
			line.rgb *= _LC.rgb;
			t += line.a;
			col.rgb = lerp(col.rgb,line.rgb,line.a);
			col.a = line.a;
			return lerp(grab,col,saturate(t));
		}
	ENDCG
	SubShader
	{
		Tags { "RenderType"="Opaque" "Queue"="Geometry+1"}
		LOD 100 Cull Off
		GrabPass{}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			ENDCG
		}
	}
}
