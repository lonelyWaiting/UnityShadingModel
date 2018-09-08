Shader "Custom/SurfaceShaderCustomPhong" 
{
	Properties 
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_SpecColor("Specular Material Color", Color) = (1,1,1,1)
		_Shininess("Shininess", Range(0.03, 128)) = 10
	}
	SubShader 
	{
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		// Physically based Standard lighting model, and enable shadows on all light types
		#pragma surface surf Phong fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 3.0

		sampler2D _MainTex;
		float _Shininess;
		fixed4 _Color;

		struct Input {
			float2 uv_MainTex;
		};

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
			// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		inline void LightingPhong_GI(SurfaceOutput s, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0f, s.Normal);
		}

		inline fixed4 LightingPhong(SurfaceOutput s, half3 viewDir, UnityGI gi)
		{
			UnityLight light = gi.light;

			// Diffuse
			float nl = max(0.0f, dot(s.Normal, light.dir));
			float3 diffuseTerm = nl * s.Albedo.rgb * light.color;

			// Specular
			float3 reflectionDirection = reflect(-light.dir, s.Normal);
			float3 specularDot = max(0.0f, dot(viewDir, reflectionDirection));
			float3 specular = pow(specularDot, _Shininess);
			float3 specularTerm = specular * _SpecColor.rgb * light.color.rgb;

			// Combine
			float3 finalColor = diffuseTerm.rgb + specularTerm;

			fixed4 c;
			c.rgb = finalColor;
			c.a   = s.Alpha;

			// Indirect Light
			#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
				c.rgb += s.Albedo * gi.indirect.diffuse;
			#endif

			return c;
		}

		void surf (Input IN, inout SurfaceOutput o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Alpha  = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
