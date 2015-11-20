﻿Shader "Unlit/ParticleUpdater"
{
	Properties
	{
		_Scale ("curl scale", Float) = 0.1
		_Speed ("curl speed", Float) = 1
		_Life ("life time", Float) = 30
		_Sepa ("separation", Float) = 1.0
		_EmitRate ("particles per sec", Float) = 0.1
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGINC/Random.cginc"

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
		
		struct pOut
		{
			float4 vel : SV_Target0;
			float4 pos : SV_Target1;// (pos.xyz, life)
			float4 col : SV_Target2;
		};

		uniform sampler2D
			_NoiseTex,
			_Vel,
			_Pos,
			_Col,
			_FlowTex,
			_EmitTex;
		half4 _Pos_TexelSize;
		
		uniform float4x4 _MATRIX_VP,_MATRIX_C2W,_MATRIX_S2W;
		uniform float4 _SParams;
		
		uniform float _MRT_TexSize;
		float _Scale,_Speed,_Life,_EmitRate,_Sepa;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
			o.uv = (v.vertex.xy/v.vertex.w+1.0)*0.5;
			return o;
		}
		
		float2 sUV(float3 wPos){
			float4 sPos = mul(_MATRIX_VP, float4(wPos,1));
			sPos = ComputeScreenPos(sPos);
			return sPos.xy/sPos.w;
		}
		float3 rgb2hsv(float3 c)
		{
		    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
		    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

		    float d = q.x - min(q.w, q.y);
		    float e = 1.0e-10;
		    return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
		}
		float3 hsv2rgb(float3 c)
		{
		    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
		    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
		    return lerp(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y) * c.z;
		}
		float colorRate(float t){
			return saturate(t)*saturate(_Life-t);
		}
		float2 fullPos(float2 uv, float rad, float t)
		{
			float x = uv.x + frac(t/_MRT_TexSize);
			float y = uv.y + t/_MRT_TexSize/_MRT_TexSize;
			uv = frac(float2(x,y));
			return normalize(uv-0.5) * max(abs(uv.x-0.5),abs(uv.y-0.5)) * rad;
		}
		float3 fullPos(float2 uv, float d){
			float4 sPos = float4((uv-0.5)*float2(16,10)*_Pos_TexelSize.w*0.01,-20,1);
			float3 wPos = mul(_MATRIX_C2W, sPos).xyz;
			return wPos;
		}
		pOut fragInit (v2f i)
		{
			pOut o;
			o.vel = 0;
			o.pos = float4(fullPos(i.uv,20,0),0,-rand(i.uv)*_Life);
			o.col = 0;
			return o;
		}
		pOut fragEmit(v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float2 emitPos = fullPos(i.uv,20,_Time.y*_MRT_TexSize*_MRT_TexSize*_EmitRate);
			float2 uv = sUV(float3(emitPos,0));
			float4 emi = tex2D(_EmitTex, uv);
			
			if(life < 0)
			if(0.95<frac(life))
			if(0<min(uv.x,uv.y))
			if(max(uv.x,uv.y)<1)
//			if(rand(uv+_Time.xy) < saturate(_Time.y*0.1)*6*pow(0.5-distance(uv,0.5),2)-0.5)
			{
				pos = float4(emitPos,0,_Life);
				emi.rgb = rgb2hsv(emi.rgb);
				emi.x += rand(i.uv+_Time.xy)*0.1-0.05;
				emi.x = frac(emi.x);
				emi.rgb = hsv2rgb(emi.rgb);
				col = emi;
			}
			
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
		pOut fragUpdate (v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float2 uv = sUV(pos.xyz);
			if(min(uv.x,uv.y) < 0)
				pos.w -= 1.0;
			if(1 < max(uv.x,uv.y))
				pos.w -= 1.0;
			
			
			float4
				flow = tex2D(_FlowTex, uv);
			vel.xy = flow.xy*_Sepa;
			pos.xy += vel.xy;
			
			pos.xy += vel.xy*unity_DeltaTime.x*saturate(pos.w);
			pos.w -= unity_DeltaTime.x;
			
			col = col;
			
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
		pOut fragCurl (v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv),
				noise = tex2D(_NoiseTex, pos.xy*_Scale);
			
			float2 curl = noise.xy;
			curl *= _Speed;
			pos.xy += curl*unity_DeltaTime.x;
			
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
		pOut fragFullPos(v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			
			pos.xyz = half3(i.uv*40,0);//fullPos(i.uv,10);
			pos.w = _Life;
			col = 0.5;//half4(i.uv,0,1);
			
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
	ENDCG
	SubShader
	{
		ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragInit
			#pragma target 3.0
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragEmit
			#pragma target 3.0
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragUpdate
			#pragma target 3.0
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragCurl
			#pragma target 3.0
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragFullPos
			#pragma target 3.0
			ENDCG
		}
	}
}