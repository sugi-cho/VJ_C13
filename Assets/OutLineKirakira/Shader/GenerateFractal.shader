Shader "Custom/GenerateFractal" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
//		_BGTex ("back ground", 2D) = "black"{}
//		_O ("overlay color", Color) = (0.5,0.5,0.5,0.5)
//		_HanaBlur ("hanabira", 2D) = "black"{}
//		_Hikari ("hikari", Float) = 1
		_DeltaTime ("delta time", Float) = 0
		_Scale("fractal scale", Float) = 1
		_I ("intencity", Float) = 1
		_S ("speed", Float) = 1
	}
	CGINCLUDE
		#include "UnityCG.cginc"
		#include "Libs/Noise.cginc"
		#include "Libs/PhotoshopMath.cginc"
 
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		float _DeltaTime,_Scale,_I,_S;
//		fixed _Hikari;
			
		half4 frag(v2f_img i) : COLOR{
		#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
		        i.uv.y = 1-i.uv.y;
		#endif
			float2 uv = i.uv;
			uv.y *= _MainTex_TexelSize.w/_MainTex_TexelSize.z;
			uv.x *= 0.5;
			uv.y *= 1.0;
			float t = _Time.x + _DeltaTime;
			t *= _S;
			float3 f3 = half3(uv+t*0.2, t*0.4)*_Scale;
			half n = snoise(f3)+0.5*snoise(f3*2)+0.25*snoise(f3*4)+0.125*snoise(f3*8);
//			n = 1.5 * sign(n) * n*n;
//			n = saturate(n+tex2D(_HanaBlur, i.uv).a*_Hikari);
//			fixed4 c = tex2D(_BGTex, i.uv);
//			c.a = 0;
			//c.rgb = BlendOverLay(c.rgb, half4(saturate(n*_O.rgb+0.5), _O.a));
//			c.rgb += _O*n/2.5;
			//return n*_O+0.5;
			return n*_I;
		}
	ENDCG
	
	SubShader {
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }  
		ColorMask RGB
 
		pass{
			CGPROGRAM
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma target 3.0
			#pragma glsl
			ENDCG
		}
	} 
}