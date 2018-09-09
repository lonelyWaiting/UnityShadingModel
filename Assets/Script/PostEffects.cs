using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class PostEffects : MonoBehaviour {

    public Shader curShader;
    private Material curMaterial;
    public bool mInvertColor       = false;
    public bool mDebugDepth        = false;
    public bool mConvertLinear     = false;
    public bool mToneMappingEffect = false;

    [Range(1.0f, 10.0f)]
    public float ToneMapperExposure = 2.0f;

    Material material
    {
        get
        {
            if(curMaterial == null)
            {
                curMaterial = new Material(curShader);
                curMaterial.hideFlags = HideFlags.HideAndDontSave;
            }
            return curMaterial;
        }
    }

	// Use this for initialization
	void Start ()
    {
        curShader = Shader.Find("Hidden/PostEffects");
        GetComponent<Camera>().allowHDR = true;
        if(!SystemInfo.supportsImageEffects)
        {
            enabled = false;
            Debug.Log("not supported");
            return;
        }

        if(!curShader || !curShader.isSupported)
        {
            enabled = false;
            Debug.Log("not supported");
        }

        GetComponent<Camera>().depthTextureMode = DepthTextureMode.Depth;
	}
	
	// Update is called once per frame
	void Update ()
    {
        if (!GetComponent<Camera>().enabled) return;
	}

    void OnDisable()
    {
        if (curMaterial) DestroyImmediate(curMaterial);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (curShader != null)
        {
            if(mInvertColor)
            {
                Graphics.Blit(source, destination, material, 0);
            }
            else if(mDebugDepth)
            {
                Graphics.Blit(source, destination, material, 1);
            }
            else if(mConvertLinear)
            {
                Graphics.Blit(source, destination, material, 2);
            }
            else if(mToneMappingEffect)
            {
                material.SetFloat("_ToneMapperExposure", ToneMapperExposure);
                Graphics.Blit(source, destination, material, 3);
            }
            else
            {
                Graphics.Blit(source, destination);
            }
        }
    }
}
