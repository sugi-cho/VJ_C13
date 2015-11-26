Shader "Unlit/ParticleVisualizer"
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
			float4 vCenter : TEXCOORD3;
			float3 right : TEXCOORD4;
			float3 up : TEXCOORD5;
			float forward : TEXCOORD6;
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
			
			v2f o;
			
			v.vertex.xyz = pos.xyz;
			o.vCenter = v.vertex;
			float4 vPos = mul(UNITY_MATRIX_V, v.vertex);
			
			if(id < numParticles && pos.w > 0)
				vPos.xy -= (v.uv-0.5)*_Size;
			else
				vPos.xyz = 0;
			v.color = col;
			
			o.vertex = mul(UNITY_MATRIX_P, vPos);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			o.color = v.color;
			o.life = pos.w;
			o.right = UNITY_MATRIX_V[0].xyz;
			o.up = UNITY_MATRIX_V[1].xyz;
			o.forward = UNITY_MATRIX_V[2].xyz;
			return o;
		}
		
		void frag (v2f i, 
			out half4 outDiffuse : SV_Target0,
			out half4 outSpecSmoothness : SV_Target1,
			out half4 outNormal : SV_Target2,
			out half4 outEmission : SV_Target3,
			out half outDepth : SV_Depth) 
		{
			half3 vNormal;
			vNormal.xy = i.uv*2.0-1.0;
			half r2 = dot(vNormal.xy, vNormal.xy);
			if(r2 > 1.0)
				discard;
			vNormal.z = sqrt(1.0-r2);
			
			half4 vPos = half4(i.vCenter.xyz+vNormal*_Size, 1.0);
			half4 cPos = mul(UNITY_MATRIX_P, vPos);
			#if defined(SHADER_TARGET_GLSL)
				outDepth = (cPos.z/cPos.w) * 0.5 + 0.5;
			#else
				outDepth = cPos.z/cPos.w;
			#endif
			if(outDepth <= 0)
				discard;
			
			
			
			
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
