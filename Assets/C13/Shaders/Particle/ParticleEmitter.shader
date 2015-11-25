Shader "Unlit/ParticleEmitter"
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
		
		uniform float4x4 _Cam1_W2C,_Cam1_W2S,_Cam1_S2C,_Cam1_C2W;
		uniform float4x4 _Cam2_W2C,_Cam2_W2S,_Cam2_S2C,_Cam2_C2W;
		uniform float4 _SParams1,_Cam1_PParams;
		uniform float4 _SParams2,_Cam2_PParams;
		
		uniform float _MRT_TexSize;
		float _Scale,_Speed,_Life,_EmitRate,_Sepa;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
			o.uv = (v.vertex.xy/v.vertex.w+1.0)*0.5;
			return o;
		}
		
		float2 sUV(float3 wPos)//screen space
		{
			float4 sPos = mul(_Cam1_W2S, float4(wPos,1));
			sPos = ComputeScreenPos(sPos);
			return sPos.xy/sPos.w;
		}
		float3 cPos(float3 wPos)//camera space
		{
			return mul(_Cam1_W2C, float4(wPos,1)).xyz;
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
		float3 fullPos(float2 uv, float d){
			float n = _Cam1_PParams.y;
			float f = _Cam1_PParams.z;
			
			float w = d;
			float z = w*(2*(w-n)/(f-n)-1);
			float2 xy = w*(2*uv-1);
			
			float4 pos = float4(xy,z,w);
			pos = mul(_Cam1_S2C,pos);
			pos.w = 1;
			pos = mul(_Cam1_C2W,pos);
			
			return pos.xyz;
		}
		pOut fragInit (v2f i)
		{
			pOut o;
			o.vel = 0;
			o.pos = float4(fullPos(i.uv,20),-rand(i.uv)*_Life);
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
			if(life < 0 && frac(abs(life))<_EmitRate*unity_DeltaTime.x){
				half2 uv = i.uv;
			// 	uv = frac(uv+float2(frac(_Time.y*_Pos_TexelSize.z),_Time.y));
			// 	life -= unity_DeltaTime.x;
			// 	col = half4(i.uv.y+i.uv.x/_Pos_TexelSize.z,0,0,1);
			// 	float emission = uv.y;
				// if(emission > 0){
					col = 0.5;
					life = _Life*rand(uv+_Time.yx);
					pos.xyz = fullPos(float2(uv.x,0.5)+length(i.uv-0.5)*normalize(i.uv-0.5)*0.01,50);
				// }
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut fragUpdate (v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			float2 uv = sUV(pos.xyz);
			if(min(uv.x,uv.y) < 0)
				pos.w -= 1.0;
			if(1 < max(uv.x,uv.y))
				pos.w -= 1.0;
			
			
			float4
				flow = tex2D(_FlowTex, uv);
			vel.xy = flow.xy*_Sepa;
			vel.z = -5;
			
			pos.xyz += vel.xyz*unity_DeltaTime.x * saturate(pos.w);
			pos.w -= unity_DeltaTime.x;
			
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
				n1 = tex2D(_NoiseTex, pos.xy*_Scale),
				n2 = tex2D(_NoiseTex, pos.xy*_Scale*2.0),
				n3 = tex2D(_NoiseTex, pos.xy*_Scale*4.0);
			float3 curl = n1.xyz+n2.xyz*0.5+n3.xyz*0.25;
			float life = pos.w;
			
			curl *= _Speed;
			pos.xy += curl*unity_DeltaTime.x * saturate(pos.w);
			pos.z += curl.z*unity_DeltaTime.x;
			
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
	}
}