Shader "Hidden/PostEffects"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			name "InvertColor"

			// No culling or depth
			Cull Off ZWrite Off ZTest Always

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
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				// just invert the colors
				col.rgb = 1 - col.rgb;
				return col;
			}
			ENDCG
		}

		Pass
		{
			name "DebugDepth"
			Cull Off ZWrite Off ZTest Always Lighting Off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv     : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv     : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _CameraDepthTexture;
			fixed4 frag(v2f i) : SV_Target
			{
				fixed depth = UNITY_SAMPLE_DEPTH(tex2D(_CameraDepthTexture, i.uv));
				fixed4 col = fixed4(depth, depth, depth, 1);
				return col;
			}
			ENDCG
		}
		Pass
		{
			name "LinearSpaceInvertColor"
			// No culling or depth
			Cull Off ZWrite Off ZTest Always

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
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv     = v.uv;
				return o;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col = pow(tex2D(_MainTex, i.uv),2.2);
				col.rgb    = 1 - col.rgb;
				return pow(col, 1.0 / 2.2);
			}
			ENDCG
		}
		Pass
		{
			name "ToneMapper"
			// No culling or depth
			Cull Off ZWrite Off ZTest Always

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
				float4 vertex : SV_POSITION;
			};

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			sampler2D _MainTex;
			float _ToneMapperExposure;

			// https://www.slideshare.net/ozlael/hable-john-uncharted2-hdr-lighting
			float3 hableOperator(float3 col)
			{
				float A = 0.15f;
				float B = 0.50f;
				float C = 0.10f;
				float D = 0.20f;
				float E = 0.02f;
				float F = 0.30f;

				return ((col * (col * A + B * C) + D * E) / (col * (col * A + B) + D * F)) - E / F;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				fixed4 col        = tex2D(_MainTex, i.uv);
				float3 toneMapped = col * _ToneMapperExposure * 4;
				toneMapped        = hableOperator(toneMapped) / hableOperator(11.2);
				return float4(toneMapped, 1.0f);
			}
			ENDCG
		}
	}
}
