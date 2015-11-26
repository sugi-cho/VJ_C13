Shader "Custom/ShadowCaster" {
	Properties {
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
	// ---- shadow caster pass:
	Pass {
		Name "ShadowCaster"
		Tags { "LightMode" = "ShadowCaster" }
		ZWrite On ZTest LEqual

		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			
			#define UNITY_PASS_SHADOWCASTER
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			
			struct appdata{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			struct v2f {
				V2F_SHADOW_CASTER;
			};
			
			// vertex shader
			v2f vert (appdata v) {
				v2f o;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			
			// fragment shader
			fixed4 frag (v2f i) : SV_Target {
				SHADOW_CASTER_FRAGMENT(i)
			}
		
		ENDCG
		}
	}
	FallBack "Diffuse"
}
