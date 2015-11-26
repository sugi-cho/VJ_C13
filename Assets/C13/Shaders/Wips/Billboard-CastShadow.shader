Shader "Unlit/Billboard-CastShadow"
{
	Properties
	{
		_DC ("diffuse", Color) = (0.5,0.5,0.5,1)
		_SC ("Specular color (RGB), roughness (A)", Color) = (0.5,0.5,0.5,0.5)
		_Size ("size", Float) = 1
	}
	CGINCLUDE
		#define UNITY_PASS_SHADOWCASTER
		#include "UnityCG.cginc"
		#include "Lighting.cginc"
		#include "UnityPBSLighting.cginc"

		struct appdata
		{
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float2 uv : TEXCOORD0;
		};

		struct v2f
		{
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 vCenter : TEXCOORD1;
			float3 vRight : TEXCOORD2;
			float3 vUp : TEXCOORD3;
			float3 vForward : TEXCOORD4;
		};
		struct v2f_shadow {
			V2F_SHADOW_CASTER;
			float2 uv : TEXCOORD1;
		};

		half4 _DC,_SC;
		float _Size;
		
		v2f vert (appdata v)
		{
			v2f o;
			float4 pos = v.vertex;
			pos.xy -= v.uv - 0.5;
			pos = mul(UNITY_MATRIX_MV,pos);
			o.vCenter = pos;
			pos.xy += (v.uv-0.5)*_Size;
			o.vertex = mul(UNITY_MATRIX_P, pos);
			o.uv = v.uv;
			
			o.vRight = normalize(UNITY_MATRIX_V[0].xyz);
			o.vUp = normalize(UNITY_MATRIX_V[1].xyz);
			o.vForward = normalize(UNITY_MATRIX_V[2].xyz);
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
			vNormal.xy = i.uv * 2 - 1;
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
			
			outDiffuse = _DC;
			outSpecSmoothness = _SC;
			outNormal.xyz = normalize(vNormal.x*i.vRight + vNormal.y*i.vUp + vNormal.z*i.vForward);
			outNormal = half4(outNormal.xyz*0.5+0.5,1);
			outEmission = 10;
			
			#ifndef UNITY_HDR_ON
				outEmission.rgb = exp2(-outEmission.rgb);
			#endif
		}
		
		
		// vertex shader
		v2f_shadow vertShadow (appdata v) {
			v.vertex.xy -= v.uv-0.5;
			float4 wPos = mul(_Object2World, v.vertex);
			float3 wLitDir = UnityWorldSpaceLightDir( wPos.xyz );
			float3 lLitDir = mul(_World2Object, float4(wLitDir,0)).xyz;
			float3 lCamDir = mul(_World2Object, float4(_WorldSpaceCameraPos,1)).xyz;
			
			float3 right = normalize(cross(lLitDir, lCamDir));
			float3 up = normalize(cross(right, lLitDir));
			right = normalize(cross(up, lLitDir));
			
			v.vertex.xyz += ((v.uv-0.5).x * right + (v.uv-0.5).y * up)*_Size;
			
			v2f_shadow o;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			o.uv = v.uv;
			return o;
		}
		// fragment shader
		fixed4 fragShadow (v2f_shadow i) : SV_Target {
			float2 uv = i.uv*2-1;
			if(dot(uv,uv) > 1.0)
				discard;
			SHADOW_CASTER_FRAGMENT(i)
		}
	ENDCG
	
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			Name "DEFERRED"
			Tags { "LightMode" = "Deferred" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			
			ENDCG
		}
		pass
		{
			Name "ShadowCaster"
			Tags { "LightMode" = "ShadowCaster" }
			ZWrite On ZTest LEqual
			
			CGPROGRAM
			#pragma vertex vertShadow
			#pragma fragment fragShadow
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			ENDCG
		}
	}
}
