Shader "Custom/LambertAndSpecular"
{
	Properties
	{
		_DiffuseTex("DiffuseTexture", 2D) = "white"{}
		_Color("Color", Color) = (1,0,0,1)
		_Ambient("Ambient", Range(0,1)) = 0.25
		_SpecularColor("Specular Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Float) = 10
	}
	SubShader
	{
		Tags { "LightMode"="ForwardBase" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityLightingCommon.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv     : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex      : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float2 uv          : TEXCOORD1;
				float3 worldPos    : TEXCOORD2;
			};

			sampler2D _DiffuseTex;
			float4	  _DiffuseTex_ST;
			float4    _Color;
			float     _Ambient;
			float     _Shininess;
			float4    _SpecularColor;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex      = UnityObjectToClipPos(v.vertex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.uv          = TRANSFORM_TEX(v.uv, _DiffuseTex);
				o.worldPos    = mul(unity_ObjectToWorld, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float3 normalDirection = normalize(i.worldNormal);
				float3 viewDirection   = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 lightDirection  = normalize(UnityWorldSpaceLightDir(i.worldPos));


				// Diffuse Implment(Lambert)
				float4 diffuse     = tex2D(_DiffuseTex, i.uv);
				float nl           = max(_Ambient, dot(normalDirection, lightDirection));
				float4 diffuseTerm = nl * _Color * diffuse * _LightColor0;

				// Specular implment(Phong)
				float3 reflectionDirection = reflect(-lightDirection, normalDirection);
				float3 specularDot         = max(0.0f, dot(viewDirection, reflectionDirection));
				float3 specular            = pow(specularDot, _Shininess);
				float4 specularTerm        = float4(specular, 1) * _SpecularColor * _LightColor0;

				// light combine
				float4 finalColor = diffuseTerm + specularTerm;

				return finalColor;
			}
			ENDCG
		}
	}
}
