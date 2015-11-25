﻿Shader "Unlit/ParticleVisualizer"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Size ("size", Float) = 0.1
		_Sepa ("separate", Float) = 2
		_Col0 ("first color", Color) = (0,0.5,1,1)
		_Col1 ("die color", Color) = (1,1,1,1)
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGINC/Random.cginc"
		#include "Assets/CGINC/BillBoardCommon.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float2 uv2 : TEXCOORD1;
			half4 color : COLOR;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			half4 color : TEXCOORD1;
			float life : TEXCOORD2;
		};
		
		struct pOut
		{
			float4 vis : SV_Target0;
			float4 kage : SV_Target1;
		};
		
		uniform sampler2D _Pos,_Vel,_Col;
		half4 _Pos_TexelSize;
		uniform int _MRT_TexSize, _Offset;
		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _Col0,_Col1;
		float _Size,_Sepa;
		
		v2f vert (appdata v)
		{
			float numParticles = _Pos_TexelSize.w*_Pos_TexelSize.w;
			float id = floor(v.uv2.x) + _Offset;
			
			float2 uv = float2(frac(id/_MRT_TexSize),id/_MRT_TexSize/_MRT_TexSize);
			half4 pos = tex2Dlod(_Pos, float4(uv,0,0));
			half4 vel = tex2Dlod(_Vel, float4(uv,0,0));
			half4 col = tex2Dlod(_Col, float4(uv,0,0));
			
			v.vertex.xyz = pos.xyz;
			float4 vPos = mul(UNITY_MATRIX_V, v.vertex);
			if(id < numParticles && pos.w > 0)
				vPos.xy -= (v.uv-0.5)*_Size*_Sepa;
			else
				vPos.xyz = 0;
			v.color = col;
			
			v2f o;
			o.vertex = mul(UNITY_MATRIX_P, vPos);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			o.color = v.color;
			o.life = pos.w;
			return o;
		}
		
		pOut frag (v2f i)
		{
			float2 uv = i.uv;
			uv -= 0.5;
			uv *= _Sepa;
			uv += 0.5;
			uv = saturate(uv);
			
			pOut o;
			o.vis = tex2D(_MainTex, uv)*i.color;
			o.kage = distance(float2(0.5,0.5),i.uv);
			o.kage = saturate(0.25 - o.kage*o.kage)*0.1;
			return o;
		}
	ENDCG
	SubShader
	{
		ZTest Always ZWrite Off
		Blend One One
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
