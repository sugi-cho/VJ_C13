Shader "Unlit/ParticleUpdater end year"
{
	Properties
	{
		_Scale ("curl scale", Float) = 0.1
		_Speed ("curl speed", Float) = 1
		_Life ("life time", Float) = 30
		_EmitRate ("emit rate", Float) = 0.1
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Assets/CGINC/Random.cginc"
		#include "Assets/CGINC/Quaternion.cginc"
		
		#define Cam1R _Cam1_W2C[0].xyz
		#define Cam1U _Cam1_W2C[1].xyz
		#define Cam1F _Cam1_W2C[2].xyz
		#define Cam2R _Cam2_W2C[0].xyz
		#define Cam2U _Cam2_W2C[1].xyz
		#define Cam2F _Cam2_W2C[2].xyz
		#define ITR 3

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
			_SyphonFlow,
			_SyphonTex;
		half4 _Pos_TexelSize;
		
		uniform float4x4 _Cam1_W2C, _Cam1_W2S, _Cam1_S2C, _Cam1_C2W;
		uniform float4x4 _Cam2_W2C, _Cam2_W2S, _Cam2_S2C, _Cam2_C2W;
		uniform float4 _Cam1_SParams, _Cam1_PParams;
		uniform float4 _Cam2_SParams, _Cam2_PParams;

		uniform float2 _Field;
		uniform float _MRT_TexSize,_Drag;
		float _Scale, _Speed, _Life, _EmitRate,_FocalLength;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = v.vertex;
			o.uv = (v.vertex.xy / v.vertex.w + 1.0)*0.5;
			return o;
		}
		
		float2 sUV(float3 wPos)//screen space of main
		{
			float4 sPos = mul(_Cam1_W2S, float4(wPos,1));
			sPos = ComputeScreenPos(sPos);
			return sPos.xy/sPos.w;
		}
		float3 cPos(float3 wPos)//camera space of main
		{
			return mul(_Cam1_W2C, float4(wPos,1)).xyz;
		}
		float2 sUV2(float3 wPos)//screen space of target
		{
			float4 sPos = mul(_Cam2_W2S, float4(wPos,1));
			sPos = ComputeScreenPos(sPos);
			return sPos.xy/sPos.w;
		}
		float3 cPos2(float3 wPos)//camera space of target
		{
			return mul(_Cam2_W2C, float4(wPos,1)).xyz;
		}
		float3 fullPos(float2 uv, float d){ //fullPos2 at target
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
		float3 fullPos2(float2 uv, float d){ //fullPos2 at target
			float n = _Cam2_PParams.y;
			float f = _Cam2_PParams.z;
			
			float w = d;
			float z = w*(2*(w-n)/(f-n)-1);
			float2 xy = w*(2*uv-1);
			
			float4 pos = float4(xy,z,w);
			pos = mul(_Cam2_S2C,pos);
			pos.w = 1;
			pos = mul(_Cam2_C2W,pos);
			
			return pos.xyz;
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
		half3 curl3d(half3 pos){
			
			half2
				xy = tex2D(_NoiseTex, pos.xy + pos.z).xy,
				zx = tex2D(_NoiseTex, pos.zx + pos.y).xy;
			half3 c3d = 0;
			c3d.xy += xy;
			c3d.zx += zx;
			return c3d;
		}
		pOut createPOut(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
		pOut lifeSpan(pOut o){
			o.pos.w -= unity_DeltaTime.x;
			return o;
		}
		pOut baseUpdate(pOut o){
			o.pos.xyz += o.vel.xyz*unity_DeltaTime.x;
			o.vel.xyz *= _Drag;
			return o;
		}
		pOut loopInField(pOut o){
			o.pos.xyz = (frac((o.pos.xyz+_Field.x)*_Field.y*0.5)-0.5)*_Field.x*2;
			return o;
		}
		pOut worldCurl(pOut o){
			half scale = _Scale;
			half speed = _Speed;

			for(int i = 0; i < ITR; i++){
				o.vel.xyz += curl3d(o.pos.xyz*scale)*speed*unity_DeltaTime.x;
				scale *= 2.0;
				speed *= 0.5;
			}

			return o;
		}
		pOut emitFromTex(v2f i, pOut o){
			float x = rand(i.uv + _Time.y) + rand(i.uv.yx + _Time.y)*0.004;
			float y = rand(i.uv.yx + _Time.y *2 ) + rand(i.uv + _Time.y*2)*0.004;
			float2 uv = float2(x,y);
			float tex = tex2D(_SyphonFlow, uv).b;
			float4 col = tex2D(_SyphonTex, uv);
			if(rand(uv)+rand(uv.yx)*0.004*frac(o.pos.w) < unity_DeltaTime.x*_Pos_TexelSize.x/_Pos_TexelSize.x){
				o.pos = half4(fullPos(uv, _Field*(1-tex*0.5)),10);
				o.col = 5*col*col;
			}
			return o;
		}
		pOut fragInit (v2f i)
		{
			pOut o;
			o.vel = 0;
			o.pos = float4(fullPos2(i.uv,_Field), 1);
			o.col = 1;
			return o;
		}
		pOut takiEmitter(v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			if(life < 0){
				life -= unity_DeltaTime.x;
				float emission = 1+tex2D(_NoiseTex, float2(i.uv.x*2,0.5)*3)+0.5*tex2D(_NoiseTex, float2(i.uv.x*4,0.75))+0.25*tex2D(_NoiseTex, float2(i.uv.x*8,0.25));
				if(frac(abs(life))<_EmitRate*unity_DeltaTime.x*emission)
				{
					col = half4(1,1,1,1);
					life = _Life*rand(i.uv+_Time.yx);
					pos.xyz = fullPos2(float2(i.uv.x,0.99),10);
					vel = half4(pow(0.5 + emission*0.5, 0.5)*Cam2F*lerp(0.2, 0.25, i.uv.y), 0);
				}
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut takiUpdate (v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			float2 uv = sUV2(pos.xyz);
			if(min(uv.x,uv.y) < 0)
				pos.w -= 1.0;
			if(1 < max(uv.x,uv.y))
				pos.w -= 1.0;
			
			float4
				flow = tex2D(_FlowTex, uv);
			vel.xyz -= unity_DeltaTime.x*(1.0-i.uv.y*0.5)*Cam2U;
			
			pos.xyz += vel.xyz*unity_DeltaTime.x * saturate(pos.w);
			pos.w -= unity_DeltaTime.x;
			
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
		pOut curl (v2f i)
		{
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float3
				cp = cPos(pos.xyz),
				right = normalize(_Cam1_W2C[0].xyz),
				up = normalize(_Cam1_W2C[1].xyz);
			float4
				n1 = tex2D(_NoiseTex, cp.xy*_Scale),
				n2 = tex2D(_NoiseTex, cp.xy*_Scale*2.0),
				n3 = tex2D(_NoiseTex, cp.xy*_Scale*4.0);
			float3 curl = n1.xyz+n2.xyz*0.5+n3.xyz*0.25;
			
			curl *= _Speed;
			pos.xyz += (curl.x*right+curl.y*up)*unity_DeltaTime.x * saturate(life);
			pos.z += curl.z*unity_DeltaTime.x;
			
			pOut o;
			o.vel = vel;
			o.pos = pos;
			o.col = col;
			return o;
		}
		pOut collToTaki(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float t = floor(_Time.y*5) * 0.3;
			float3 coll = fullPos2(float2(rand(t),rand(t)), 10);
			float rad = 3*frac(_Time.y*5);
			float3 dist = pos.xyz - coll;
			if(length(dist)<rad){
				float3 to = coll + rad * normalize(dist);
				dist = to - pos.xyz;
				pos.xyz = to;
				vel.xyz += dist/unity_DeltaTime.x;
				col.rgb = normalize(vel.xyz)*0.5+0.5;
				col.rgb *= col.rgb*length(vel.xyz);
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut yukiEmitter(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float r = rand(i.uv.yx+_Time.y);
			float3 newPos = fullPos2(float2(i.uv.x,1),1+29*(1-i.uv.y*i.uv.y));
			newPos.y = fullPos2(float2(i.uv.x,lerp(1.0,1.5,r)),30).y;
			float3
				cp = cPos2(newPos.xyz);
			float n = tex2D(_NoiseTex, cp.xz*_Scale+_Time.x).b;
			
			if(life < 0){
				life -= unity_DeltaTime.x;
				if(rand(i.uv.xy+_Time.xy)*500-frac(abs(life*0.01))*n<unity_DeltaTime.x)
				{
					col = 1;
					life = _Life*rand(i.uv+_Time.yx);
					pos.xyz = newPos;
					vel.xyz = -Cam2U;
				}
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut yukiUpdate(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			float3
				cp = cPos2(pos.xyz);
			float4
				n1 = tex2D(_NoiseTex, cp.xz*_Scale),
				n2 = tex2D(_NoiseTex, cp.xz*_Scale*2.0),
				n3 = tex2D(_NoiseTex, cp.xz*_Scale*4.0);
			float3 curl = n1.xyz+n2.xyz*0.5+n3.xyz*0.25;
			float ground = -5 + n1.b * 5;
			life -= unity_DeltaTime.x;
			if(0 < life){
				vel.xyz -= Cam2U * unity_DeltaTime.x * 5 * (0.7 + 0.3*i.uv.y) + (curl.x*Cam2R + curl.y*Cam2F)*unity_DeltaTime*_Speed;
				vel.xyz *= 0.8;

				pos.xyz += vel.xyz * unity_DeltaTime.x;
				if (pos.y < ground)
					pos.y = ground;
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut flowUpdate(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float2 uv = sUV(pos.xyz);
			float3 cp = cPos(pos.xyz);
			float4 
				n1 = tex2D(_NoiseTex, cp.xy*_Scale*0.1),
				n2 = tex2D(_NoiseTex, cp.xy*_Scale*0.1*2.0),
				n3 = tex2D(_NoiseTex, cp.xy*_Scale*0.1*4.0);
			float3 curl = n1.xyz+n2.xyz*0.5+n3.xyz*0.25;
			
			col.rgb = abs(normalize(vel.xyz));
			vel.xyz += curl.xyz*_Speed;
			vel.y -= unity_DeltaTime.x;
			vel*=0.9;
			pos.xyz += vel.xyz * unity_DeltaTime.x;
			pos.x /= 2;
			pos.xyz = frac(pos.xyz/30+0.5)*30-15;
			pos.x *= 2;
			life = _Life*((rand(i.uv.yx)+rand(i.uv.xy)/256)+1);
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut flowTex(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float2 uv = sUV2(pos.xyz);
			float3 cp = cPos(pos.xyz);
			float4 
				tex = tex2D(_FlowTex,uv),
				n1 = tex2D(_NoiseTex, cp.xy*_Scale*0.1),
				n2 = tex2D(_NoiseTex, cp.xy*_Scale*0.1*2.0),
				n3 = tex2D(_NoiseTex, cp.xy*_Scale*0.1*4.0);
			float3 curl = n1.xyz+n2.xyz*0.5+n3.xyz*0.25;
			
			col.rgb = half3(uv,0);
			tex = tex2D(_FlowTex, uv);
			float3 to = fullPos2(i.uv,60-20*length(tex.rgb));
			vel.xyz += to - pos.xyz;
			pos.xyz += vel.xyz * unity_DeltaTime.x;
			vel.xyz *= 1-unity_DeltaTime.x;
			life = _Life*((rand(i.uv.yx)+rand(i.uv.xy)/256)+1);
			col.rgb = tex.rgb;
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut collisionToCenter(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float3 center = fullPos(float2(0.5,0.5), _FocalLength);
			float rad = _FocalLength*0.4;
			float3 dist = pos.xyz - center;
			if(length(dist)<rad){
				float3 to = center + rad * normalize(dist);
				dist = to - pos.xyz;
				pos.xyz = to;
				vel.xyz += dist/unity_DeltaTime.x;
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut gotoCube(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float3 to=0;
			to.x = frac(i.uv.x*10.0)*10.0;
			to.y = frac(i.uv.y*10.0)*10.0;
			to.z = floor(i.uv.x*10.0)/10.0+floor(i.uv.y*10.0);
			to -= 5.0;
			to = rotateAngleAxis(to,float3(1.0,2.0,3.0),0.1*_Time.y*UNITY_PI);
			
			vel.xyz += to.xyz - pos.xyz;
			
			col.rgb = 1+vel.xyz;
			pos.xyz += vel.xyz * unity_DeltaTime.x;
			vel.xyz *= 1-unity_DeltaTime.x;
			life = _Life*((rand(i.uv.yx)+rand(i.uv.xy)/256)+1);
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut gotoSphere(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float3 to=0;
			to.x = frac(i.uv.x*10.0)*10.0;
			to.y = frac(i.uv.y*10.0)*10.0;
			to.z = floor(i.uv.x*10.0)/10.0+floor(i.uv.y*10.0);
			to -= 5.0;
			to = normalize(to)*max(abs(to.x),max(abs(to.y),abs(to.z)));
			to *= 0.4;
			to = rotateAngleAxis(to,float3(1.0,2.0,3.0),0.1*_Time.y*UNITY_PI);
			
			vel.xyz += to.xyz - pos.xyz;

			pos.xyz += vel.xyz * unity_DeltaTime.x;
			vel.xyz *= _Drag;
			life = _Life*((rand(i.uv.yx)+rand(i.uv.xy)/256)+1);
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut emitToCamCenter(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float3 center = fullPos(float2(0.5,0.5), _Field*0.5);
			float3 sphere = float3(
				frac(i.uv.x*10),
				frac(i.uv.y*10),
				floor(i.uv.x*10)*0.01+floor(i.uv.y*10)*0.1
			)-0.5;
			
			sphere = normalize(sphere) * max(abs(sphere.x),max(abs(sphere.y),abs(sphere.z)));
			float3 emitPos = center + sphere*0.2;
			
			if(life<0){
				life -= unity_DeltaTime.x;
				float r = rand(i.uv+_Time.xy)+rand(i.uv.yx+_Time.yx)/256;
				if(r*frac(life) < 50*unity_DeltaTime.x/_Pos_TexelSize.z/_Pos_TexelSize.z){
					pos.xyz = emitPos;
					vel.xyz = sphere*10;
					col = 1;
					life = _Life*(0.6+0.4*length(sphere.xyz));
				}
			}
			else{
				life -= unity_DeltaTime.x;
				if(life<_Life*0.5){
					vel.xyz += normalize(emitPos - pos.xyz)*unity_DeltaTime.x*2;
					float3 dist = pos.xyz-emitPos;
					if(length(dist)<2){
						float3 to = emitPos+normalize(dist);
						dist = to-pos.xyz;
						vel.xyz += dist/unity_DeltaTime.x;
					}
					pos.xyz += vel.xyz*unity_DeltaTime.x;
					col.rgb = vel.xyz*vel.xyz;
					vel.xyz *= 1-unity_DeltaTime.x*0.1;
					
				}
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut kieru(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			
			float3
				cp = cPos(pos.xyz),
				right = normalize(_Cam1_W2C[0].xyz),
				up = normalize(_Cam1_W2C[1].xyz);
			float4
				n1 = tex2D(_NoiseTex, cp.xy*_Scale),
				n2 = tex2D(_NoiseTex, cp.xy*_Scale*2.0),
				n3 = tex2D(_NoiseTex, cp.xy*_Scale*4.0);
			float3 curl = n1.xyz+n2.xyz*0.5+n3.xyz*0.25;
			
			curl *= _Speed;
			pos.xyz += (vel.xyz+(curl.x*right+curl.y*up))*unity_DeltaTime.x * saturate(life);
			life -= unity_DeltaTime.x;
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = col;
			return o;
		}
		pOut emitSquare(v2f i){
			float4
				vel = tex2D(_Vel, i.uv),
				pos = tex2D(_Pos, i.uv),
				col = tex2D(_Col, i.uv);
			float life = pos.w;
			float3 cp = cPos(pos.xyz);
			float4
				n1 = tex2D(_NoiseTex, (pos.xy+pos.z)*_Scale),
				n2 = tex2D(_NoiseTex, (pos.xy+pos.z)*_Scale*2.0),
				n3 = tex2D(_NoiseTex, (pos.xy+pos.z)*_Scale*4.0),
				n4 = tex2D(_NoiseTex, (pos.zx+pos.y)*_Scale),
				n5 = tex2D(_NoiseTex, (pos.zx+pos.y)*_Scale*2.0),
				n6 = tex2D(_NoiseTex, (pos.zx+pos.y)*_Scale*4.0);
			float3 
				curlXY = n1.xyz+n2.xyz*0.5+n3.xyz*0.25,
				curlZX = n4.xyz+n5.xyz*0.5+n6.xyz*0.25;
			
			float3 emitPos = (half3(i.uv.x,-25,i.uv.y)-0.5)*0.1 + 5.0*half3(sin(_Time.y*0.1),0,cos(_Time.y*0.1));
			
			if(life<0){
				life -= unity_DeltaTime.x;
				float r = rand(i.uv+_Time.xy)+rand(i.uv.yx+_Time.yx)/256;
				if(r*frac(life) < 20000*unity_DeltaTime.x*_Pos_TexelSize.x/_Pos_TexelSize.x){
					pos.xyz = emitPos;
					vel.xyz = half3(0,100*(1-distance(i.uv,0.5)),0);
					life = _Life*(0.6+0.4*i.uv.x);
				}
			}
			else{
				life -= unity_DeltaTime.x;
				vel.xy += curlXY.xy;
				vel.zx += curlZX.xy;
				vel.y -= 9.8 * unity_DeltaTime.x;
				
				if(pos.x < -7.5 || 7.5 < pos.x){
					vel.x *= -1;
					pos.x = max(-7.5,min(pos.x,7.5));
					life -= 1;
				}
				if(pos.z < -7.5 || 7.5 < pos.z){
					vel.z *= -1;
					pos.z = max(-7.5,min(pos.z,7.5));
					life -= 1;
				}
				if(pos.y < -2.5 || 11.5 < pos.y){
					vel.y *= -1;
					pos.y = max(-2.5,min(pos.y,11.5));
					life -= 1;
				}
				pos.xyz += vel.xyz*unity_DeltaTime.x*_Speed*(0.9+0.1*(rand(i.uv.xy+_Time.y)+rand(i.uv.yx+_Time.y)/256))*saturate(life*0.1);

				vel.xyz *= 1-unity_DeltaTime.x*0.5;
			}
			
			pOut o;
			o.vel = vel;
			o.pos = half4(pos.xyz,life);
			o.col = 1;
			return o;
		}
		pOut basic(v2f i){
			pOut o = createPOut(i);
			if(0<o.pos.w){
				o = worldCurl(o);
				o = baseUpdate(o);
				o = loopInField(o);
				o.pos.z -= unity_DeltaTime.x*0.3;
				o.pos.w = 1;
			}
			else{
				o = fragInit(i);
			}
			return o;
		}
		pOut emitTex(v2f i){
			pOut o = createPOut(i);
			if(o.pos.w < 0)
				o = emitFromTex(i,o);
			else{
				float2 uv = sUV(o.pos.xyz);
				float v = tex2D(_SyphonFlow,uv).b;
				o.pos.w -= (1-v);
			}
			o = lifeSpan(o);
			return o;
		}
	ENDCG
	SubShader
	{
		ZTest Always

		Pass//0
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragInit
			#pragma target 3.0
			ENDCG
		}
		Pass//1
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment takiEmitter
			#pragma target 3.0
			ENDCG
		}
		Pass//2
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment takiUpdate
			#pragma target 3.0
			ENDCG
		}
		Pass//3
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment curl
			#pragma target 3.0
			ENDCG
		}
		Pass//4
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment yukiEmitter
			#pragma target 3.0
			ENDCG
		}
		Pass//5
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment yukiUpdate
			#pragma target 3.0
			ENDCG
		}
		Pass//6
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment flowUpdate
			#pragma target 3.0
			ENDCG
		}
		Pass//7
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment flowTex
			#pragma target 3.0
			ENDCG
		}
		Pass//8
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment collToTaki
			#pragma target 3.0
			ENDCG
		}
		Pass//9
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment gotoCube
			#pragma target 3.0
			ENDCG
		}
		Pass//10
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment gotoSphere
			#pragma target 3.0
			ENDCG
		}
		Pass//11
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment emitToCamCenter
			#pragma target 3.0
			ENDCG
		}
		Pass//12
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment kieru
			#pragma target 3.0
			ENDCG
		}
		Pass//13
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment emitSquare
			#pragma target 3.0
			ENDCG
		}
		Pass//14
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment basic
			#pragma target 3.0
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment emitTex
			#pragma target 3.0
			ENDCG
		}
	}
}
