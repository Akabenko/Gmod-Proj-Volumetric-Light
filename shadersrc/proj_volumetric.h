#include "common_ps_bayer.h"
#include "common_ps_packdepth.h"

sampler WPDepth 			: register( s0 );
sampler ShadowMap 			: register( s1 );
sampler ProjTexture         : register( s2 );

const float4 Constants0 	: register( c0 );
const float4 Constants1 	: register( c1 );
const float4 Constants2 	: register( c2 );
const float4 Constants3 	: register( c3 );
const float2 TexelSize 		: register( c4 );
const float4x4 ShadowMatrix	: register( c11 );
static const float PI 		= 3.1415925f;
static const float PI4 		= 4.0f * PI;
//static const float g_bias 	= 0.0001f;

const float3 EyePos : register( c15 );

struct PS_IN
{
	float2 ppos	: VPOS;
	float2 tc0	: TEXCOORD0;
};

//#define _PRESET_ULTRA

#define lightColor 		Constants0.rgb
#define lightMul 		Constants0.w
//#define EyePos			Constants1.xyz

//const float3 EyePos : register(c10);

#define lightAdd 		Constants1.w
#define lightPos		Constants2.xyz

#if defined(_PRESET_ULTRA)
static const uint NB_STEPS = uint(32);
#else
static const uint NB_STEPS = 16;
#endif
static const float INV_NB_STEPS = 1.f / NB_STEPS;

#define G_SCATTERING  Constants2.w

//#define G_SCATTERING_1 	Constants2.w
//#define G_SCATTERING_2	Constants3.x
//#define G_SCATTERING2 	Constants3.y
#define max_density 	Constants3.z
#define inv_zfar        Constants1.x

#define SCATTERING_POW 1.5 //Constants3.x

// TODO: Precalculate
// Mie scaterring approximated with Henyey-Greenstein phase function.
/*float ComputeScattering(float lightDotView)
{
    return G_SCATTERING_1 / (PI4 * pow(1.0f + mad(-G_SCATTERING_2, lightDotView, G_SCATTERING2), 1.5f));
}*/

float ComputeScattering(float lightDotView)
{
    float G_SCATTERING2 = G_SCATTERING * G_SCATTERING;
    float result = 1.0f - G_SCATTERING2;
    result /= (PI4 * pow(1.0f + G_SCATTERING2 - (2.0f * G_SCATTERING) * lightDotView, SCATTERING_POW) );
    return result;
}

#define distance Constants3.x
#define g_bias Constants3.y

// TODO: Add Smoke effect as Source Filmmaker
static const float far_bias = 0.995;

half4 main(PS_IN i) : COLOR0 {
	float2 texcoord = i.tc0;
	float4 wpdepth = tex2Dlod(WPDepth, float4(texcoord,0,0));
	
	float depth = wpdepth.a;

    float near = (1 / depth / distance);

    float3 worldPos = 1/wpdepth.xyz;
    #if defined(CSM)
    float3 lightShadowsDir = lightPos;
    #else
    //float3 lightShadowsDir = normalize(lightPos - worldPos);
    float3 lightShadowsDir = normalize(worldPos - lightPos);
    #endif
    float3 eyeVec = EyePos - worldPos;
    float lightDotView = dot( normalize(eyeVec), lightShadowsDir );

    #if defined(CSM)
    float fSturation = lightMul * lightDotView + lightAdd;
    #else
    float fSturation = 1; // lightAdd
    #endif

    half3 shadows = 0;
    
    #if defined(CSM)
    bool sky = depth == 0.00025;
    if (sky) {
        //shadows = max_density;
        return half4(0.h,0.h,0.h,depth); // Proton crash Fix. Removed discard
        //discard;
    }
    #endif

	half scattering = ComputeScattering(lightDotView);
	
	float rayLength = length(eyeVec);
    float3 rayDirection = eyeVec / rayLength;
    float stepLength = rayLength * INV_NB_STEPS;
    float3 step = rayDirection * stepLength;

    #if !defined(_PRESET_ULTRA)
    float ditherValue = bayer4( i.ppos );
    #endif

    [loop]
    for (int i=0;i<NB_STEPS;i++) {
            #if defined(_PRESET_ULTRA)
            float3 samplePos = worldPos + step * i;
        #else
            float3 samplePos = worldPos + step * (i + ditherValue);
        #endif

        float4 shadowCoord = mul(float4(samplePos, 1), ShadowMatrix);
        shadowCoord.xyz /= shadowCoord.w;
        shadowCoord.xyz = mad(shadowCoord.xyz, 0.5, 0.5);
        if (dot(shadowCoord.xyz - saturate(shadowCoord.xyz), 1.0) != 0.0) continue;
        #if defined(SHADOWMAP)
            if (  shadowCoord.z < tex2D(ShadowMap, shadowCoord.xy ).r )
            {
        #endif
            #if defined(CSM)
            //shadows += tex2Dlod(ProjTexture, float4(shadowCoord.xy, 0, 0)).rgb * scattering;
            shadows += scattering;
            #else
            float lightLength = length(lightPos - samplePos); 
            half atten = saturate(1.0 - lightLength * inv_zfar);
            shadows += tex2Dlod(ProjTexture, float4(shadowCoord.xy, 0, 0)).rgb * atten * lightAdd;
            #endif
        #if defined(SHADOWMAP)
        }
        #endif
    }

    shadows *= INV_NB_STEPS;
    shadows *= near;
    
    //shadows = lerp(shadows, max_density, fog);
    
    shadows *= fSturation;

    return half4(shadows * lightColor, depth);
}

// https://www.alexandre-pestana.com/volumetric-lights/
// https://github.com/OpenXRay/xray-15/blob/ee141793687484ae1bdd21537a48b79e693d0f58/cs/resources/shaders/gl/accum_volumetric_sun.ps#L77

