Shader "Unlit/ViewPortToPos"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_VP ("viewport position", Vector) = (0.5,0.5,1,0)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100
		
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos: TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _VP; // viewPosition
			
			float3 clipToLocal(float4 clipPos){
				float4 viewPos = mul(unity_CameraInvProjection, clipPos);
				viewPos.w = 1;
				return mul(viewPos, UNITY_MATRIX_IT_MV).xyz;
			}
			
			v2f vert (appdata v)
			{
				float n = _ProjectionParams.y;
				float f = _ProjectionParams.z;
				
				float w = _VP.z;
				float z = w * (2*(w-n)/(f-n)-1);
				float2 xy = w * (2*_VP.xy-1);
				float4 clipPos = float4(xy,z,w);
				float3 localPos = clipToLocal(clipPos);
				
				v.vertex.xyz += localPos;
				
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.pos = o.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = half4(i.pos.xyz/i.pos.w*0.5+0.5,0);
				return col;
			}
			ENDCG
		}
	}
}
