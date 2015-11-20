﻿Shader "Hidden/DrawCanvas"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
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
		
		uniform sampler2D _Canvas, _ParticleComp;
		sampler2D _MainTex;
		half4 _Canvas_TexelSize;

		half4 frag (v2f i) : SV_Target
		{
			half2 d = _Canvas_TexelSize.xy;
			half
				c00 = tex2D(_Canvas, i.uv+half2(-d.x,-d.y)).a,
				c01 = tex2D(_Canvas, i.uv+half2(-d.x, d.y)).a,
				c10 = tex2D(_Canvas, i.uv+half2( d.x,-d.y)).a,
				c11 = tex2D(_Canvas, i.uv+half2( d.x, d.y)).a;
			
			float2 flow = float2(c10+c11-c00-c01, c01+c11-c00-c10)*d*0.5;
			half4 canvas = tex2D(_Canvas, i.uv+flow);
			half4 brush = tex2D(_ParticleComp, i.uv);
			
			canvas.rgb = lerp(canvas.rgb, brush.rgb*brush.rgb*2, saturate(brush.a*2)*0.5);
			canvas.a += brush.a;
			
			canvas.a *= 1-unity_DeltaTime.x;
			canvas.a = saturate(canvas.a);
			canvas.rgb = max(canvas.rgb,0);
			return canvas;
		}
	ENDCG
	SubShader
	{
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			ENDCG
		}
	}
}
