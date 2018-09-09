Shader "Custom/CookTorranceSurface" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_ColorTint("Color", Color)           = (1,1,1,1)
		_SpecColor("Speclar Color", Color)   = (1,1,1,1)
		_BumpMap("Normal Map", 2D)  = "bump"{}
		_Roughness("Roughness", Range(0,1)) = 0.5
		_Subsurface("Subsuface", Range(0,1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200

		CGPROGRAM
		#pragma surface surf CookTorrance fullforwardshadows
		#pragma target 3.0

		#define PI 3.14159265338979323846f

		sampler2D _MainTex;
		sampler2D _BumpMap;
		half	  _Roughness;
		float	  _Subsurface;
		fixed4	  _ColorTint;

		struct Input {
			float2 uv_MainTex;
		};

		UNITY_INSTANCING_BUFFER_START(Props)
		UNITY_INSTANCING_BUFFER_END(Props)

		struct SurfaceOutputCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			fixed3 Emission;
			fixed  Alpha;
		};

		float sqr(float value)
		{
			return value * value;
		}

		float SchlickFresnel(float value)
		{
			float m = clamp(1 - value, 0, 1);
			return pow(m, 5);
		}

		float Fresnel(float F0, float NdotV)
		{
			return F0 + (1 - F0) * SchlickFresnel(NdotV);
		}

		float NDF(float roughness, float NdotH)
		{
			float alpha = sqr(roughness);
			float alphaSqr = sqr(alpha);
			return alphaSqr / (PI * sqr(sqr(NdotH) * (alphaSqr - 1) + 1));
		}

		float modifiedRoughness(float roughness)
		{
			return sqr(roughness + 1) / 8;
		}

		float G1(float k, float _cos)
		{
			return _cos / (_cos * (1 - k) + k);
		}
		
		float G(float roughness, float NdotL, float NdotV)
		{
			float k = sqr(roughness + 1) / 8;
			// 一定要加epsilon,避免除0
			return G1(k, NdotL) * G1(k, NdotV) / (4 * NdotL * NdotV + 1e-5f);
		}

		inline float3 CookTorranceSpec(float NdotL, float NdotV, float LdotH, float NdotH, float roughness, float F0)
		{
			float DFG = Fresnel(F0, NdotV) * G(roughness, NdotL, NdotV) * NDF(roughness, NdotH);
			return DFG * NdotL;
		}

		inline float3 DisneyDiffuse(float3 albedo, float NdotL, float NdotV, float LdotH, float roughness)
		{
			// luminance approximation
			float albedoLuminosity = 0.3f * albedo.r + 0.6f * albedo.g + 0.1f * albedo.b;

			// normalize luminosity to isolate hue and saturation
			float3 albedoTint = albedoLuminosity > 0 ? albedo / albedoLuminosity : float3(1, 1, 1);

			float fresnelL = SchlickFresnel(NdotL);
			float fresnelV = SchlickFresnel(NdotV);

			float fresnelDiffuse = 0.5f + 2.0f * roughness * sqr(LdotH);
			float diffuse = albedoTint * lerp(1.0f, fresnelDiffuse, fresnelL) * lerp(1.0f, fresnelDiffuse, fresnelV);

			// subsurface diffuse
			float fresnelSubsurface90 = sqr(LdotH) * roughness;
			float fresnelSubsurface = lerp(1.0f, fresnelSubsurface90, fresnelL) * lerp(1.0f, fresnelSubsurface90, fresnelV);
			float ss = 1.25f * (fresnelSubsurface * (1 / (NdotL + NdotV) - 0.5f) + 0.5f);

			return saturate(lerp(diffuse, ss, _Subsurface) * (1.0 / PI) * albedo);
		}

		inline void LightingCookTorrance_GI(SurfaceOutputCustom s, UnityGIInput data, inout UnityGI gi)
		{
			gi = UnityGlobalIllumination(data, 1.0f, s.Normal);
		}

		inline float4 LightingCookTorrance(SurfaceOutputCustom s, float3 viewDir, UnityGI gi)
		{
			UnityLight light = gi.light;

			viewDir         = normalize(viewDir);
			float3 lightDir = normalize(light.dir);
			s.Normal        = normalize(s.Normal);
			float3 halfV = normalize(lightDir + viewDir);
			// saturate将会把值截断为0
			// 因此一定要注意除0的问题
			// 比如NdotL,N与L大于90度的情况下,该值都是0
			float NdotL  = saturate(dot(s.Normal, lightDir));
			float NdotV  = saturate(dot(s.Normal, viewDir));
			float NdotH  = saturate(dot(s.Normal, halfV));
			float VdotH  = saturate(dot(viewDir, halfV));
			float LdotH  = saturate(dot(lightDir, halfV));
			
			// BRDF
			float3 diffuse = DisneyDiffuse(s.Albedo, NdotL, NdotV, LdotH, _Roughness);
			float3 spec = CookTorranceSpec(NdotL, NdotV, LdotH, NdotH, _Roughness, _SpecColor);

			float3 finalColor = (diffuse + spec * _SpecColor) * _LightColor0.rgb;
			float4 c = float4(finalColor, s.Alpha);

		#ifdef UNITY_LIGHT_FUNCTION_APPLY_INDIRECT
			c.rgb += s.Albedo * gi.indirect.diffuse;
		#endif

			return c;
		}

		void surf (Input IN, inout SurfaceOutputCustom o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _ColorTint;
			o.Albedo = c.rgb;
			o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
			o.Alpha  = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
