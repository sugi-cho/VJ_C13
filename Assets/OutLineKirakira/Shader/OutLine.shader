Shader "Unlit/OutLine"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_LC ("line color", Color) = (0,0,1,1)
		_LS ("line size", Float) = 0.1
	}
	CGINCLUDE
		#include "UnityCG.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
			float3 normal : NORMAL;
		};

		struct v2f
		{
			float2 uv : TEXCOORD0;
			float4 vertex : SV_POSITION;
		};

		sampler2D _MainTex;
		float4 _MainTex_ST;
		float4 _LC;
		float _LS;
		
		v2f vert (appdata v)
		{
			v2f o;
			o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			return o;
		}
		v2f vertLine (appdata v)
		{
			v.normal = -v.normal;
			float4 vPos = mul(UNITY_MATRIX_MV, v.vertex);
			float3 vNorm = mul(UNITY_MATRIX_MV, float4(v.normal,0)).xyz;
			vPos.xy -= normalize(vNorm.xy)*_LS;
			v2f o;
			o.vertex = mul(UNITY_MATRIX_P, vPos);
			o.uv = TRANSFORM_TEX(v.uv, _MainTex);
			return o;
		}
		
		half4 frag (v2f i) : SV_Target
		{
			fixed4 col = tex2D(_MainTex, i.uv);	
			col.a = 0;	
			return col;
		}
		half4 fragLine (v2f i) : SV_Target
		{
			half4 col = _LC;
			col.a = 1.0;
			return col;
		}
	ENDCG
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		Pass
		{
			Cull Front
			CGPROGRAM
			#pragma vertex vertLine
			#pragma fragment fragLine
			
			ENDCG
		}
		Pass
		{
			Cull Back
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			ENDCG
		}
	}
}
