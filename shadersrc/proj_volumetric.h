#include "common_ps_bayer.h"
#include "common_ps_packdepth.h"

sampler WPDepth             : register( s0 );
sampler ShadowMap           : register( s1 );
sampler ProjTexture         : register( s2 );

const float4 Constants0     : register( c0 );
const float4 Constants1     : register( c1 );
const float4 Constants2     : register( c2 );
const float4 Constants3     : register( c3 );
const float2 TexelSize      : register( c4 );
const float4x4 ShadowMatrix : register( c11 );

static const float PI       = 3.1415925f;
static const float PI4      = 4.0f * PI;

const float3 EyePos : register( c15 );

struct PS_IN
{
    float2 ppos : VPOS;
    float2 tc0  : TEXCOORD0;
};

#define lightColor      Constants0.rgb
#define lightMul        Constants0.w
#define lightAdd        Constants1.w
#define lightPos        Constants2.xyz

#if defined(_PRESET_ULTRA)
static const uint NB_STEPS = 32;
#else
static const uint NB_STEPS = 16;
#endif
static const float INV_NB_STEPS = 1.0f / NB_STEPS;

#define G_SCATTERING    Constants2.w
#define max_density     Constants3.z
#define inv_zfar        Constants1.x
#define distance        Constants3.x
#define g_bias          Constants3.y

static const float EXTINCTION_COEFF = 0.05;      // Medium thickness (0.05 = haze, 0.5 = thick fog)
static const float SOFT_FADE_RANGE = 64.0;       // World units to fade softly near geometry
static const float SCATTER_G2 = -0.2;            // Backward scatter lobe
static const float SCATTER_BLEND = 0.8;          // Blend between forward and backward lobes
static const float POWDER_STRENGTH = 0.5;        
static const float POWDER_DECAY = 0.8;           
static const float STEP_CURVE_K = 1.0;           // 0 = uniform, 1 = linear growth

// We use now a modified Schlick phase function which is more stable and still captures the forward/backward scattering behavior, instead of the standard Henyey-Greenstein which can produce extreme peaks that are hard to resolve with few samples.
float PhaseSchlick(float cosTheta, float g) {
    float k = 1.55f * g - 0.55f * (g * g * g);
    float kCos = k * cosTheta;
    float denom = 1.0f - kCos;
    return (1.0f - k * k) / (PI4 * denom * denom);
}

// Should work correctly 
float ComputeDualLobeSchlick(float cosTheta, float g1, float g2, float blend) {
    float lobe1 = PhaseSchlick(cosTheta, g1);
    float lobe2 = PhaseSchlick(cosTheta, g2);
    return lerp(lobe2, lobe1, blend);
}

// Fast Interleaved Gradient Noise (replaces bayer4)
float IGN(float2 pixelPos) {
    return frac(52.9829189f * frac(dot(pixelPos, float2(0.06711056f, 0.00583715f))));
}

// Shout out to MCV
float PowderEffect(float density, float cosTheta, float strength, float decay) {
    float powder = 1.0 - exp(-density * decay);
    float forwardWeight = 0.5 + 0.5 * cosTheta;
    return lerp(1.0, powder, strength * (1.0 - forwardWeight));
}

half4 main(PS_IN i) : COLOR0 {
    float2 texcoord = i.tc0;
    float4 wpdepth = tex2Dlod(WPDepth, float4(texcoord, 0, 0));
    
    float depth = wpdepth.a;
    float near = (1.0f / depth / distance);
    float3 worldPos = 1.0f / wpdepth.xyz;

    #if defined(CSM)
    float3 lightShadowsDir = lightPos;
    #else
    float3 lightShadowsDir = normalize(worldPos - lightPos);
    #endif

    float3 eyeVec = EyePos - worldPos;
    float lightDotView = dot(normalize(eyeVec), lightShadowsDir);

    #if defined(CSM)
    float fSturation = lightMul * lightDotView + lightAdd;
    #else
    float fSturation = 1.0f;
    #endif

    half3 shadows = 0;
    
    #if defined(CSM)
    if (depth == 0.00025f) {
        return half4(0.h, 0.h, 0.h, depth);
    }
    #endif

    // Fast Schlick Scattering Phase
    half scattering = ComputeDualLobeSchlick(lightDotView, G_SCATTERING, SCATTER_G2, SCATTER_BLEND);
    
    float rayLength = length(eyeVec);
    float3 rayDirection = eyeVec / rayLength;
    float ditherValue = IGN(i.ppos);
    float transmittance = 1.0f;

    // Proper Inverse Square math (1 / zfar^2)
    float inv_light_radius_sq = inv_zfar * inv_zfar; 

    [loop]
    for (uint s=0; s<NB_STEPS; s++) {
        // Exponential step sizing
        float t_linear = (float(s) + ditherValue) * INV_NB_STEPS;
        float t_exp    = (exp2(t_linear * STEP_CURVE_K) - 1.0f) / (exp2(STEP_CURVE_K) - 1.0f);
        float t_next   = (exp2((t_linear + INV_NB_STEPS) * STEP_CURVE_K) - 1.0f) / (exp2(STEP_CURVE_K) - 1.0f);
        float localStep = (t_next - t_exp) * rayLength;
        
        float3 samplePos = worldPos + rayDirection * (rayLength * t_exp);
        float sampleT = rayLength * t_exp;
        
        // Soft edge fading
        float remainingLength = rayLength - sampleT;
        float geometryFade = saturate(remainingLength / SOFT_FADE_RANGE);
        geometryFade = geometryFade * geometryFade;

        float stepTransmittance = exp(-EXTINCTION_COEFF * localStep);
        float powderScale = PowderEffect(EXTINCTION_COEFF * localStep, lightDotView, POWDER_STRENGTH, POWDER_DECAY);

        float4 shadowCoord = mul(float4(samplePos, 1.0f), ShadowMatrix);
        shadowCoord.xyz /= shadowCoord.w;
        shadowCoord.xyz = mad(shadowCoord.xyz, 0.5f, 0.5f);
        if (dot(shadowCoord.xyz - saturate(shadowCoord.xyz), 1.0f) != 0.0f) continue;
        
        #if defined(SHADOWMAP)
            if (shadowCoord.z < tex2Dlod(ShadowMap, float4(shadowCoord.xy, 0, 0)).r)
            {
        #endif
            #if defined(CSM)
            float3 inScatter = 1.0f;
            float atten = 1.0f;
            #else
            
            // Correct physical Inverse-Square falloff
            float distSq = dot(lightPos - samplePos, lightPos - samplePos);
            float atten = saturate(1.0f / (1.0f + distSq * inv_light_radius_sq));
            
            // Smooth windowing to avoid hard cutoff at edge of light bounds
            // This can add some glitchy artifacts on borders of volume,still need to be tweaked or removed 
            float window = saturate(1.0f - (distSq * inv_light_radius_sq) * (distSq * inv_light_radius_sq));
            atten *= window * window;
            
            float3 inScatter = tex2Dlod(ProjTexture, float4(shadowCoord.xy, 0, 0)).rgb * lightAdd;
            #endif
            
            // Calculate proper direct scatter. 
            float3 directScatter = inScatter * atten * scattering;
            
            // Integrate physically. Using (localStep / rayLength) balances the brightness automatically!
            shadows += directScatter * powderScale * transmittance * geometryFade * (localStep / rayLength);
            
        #if defined(SHADOWMAP)
            }
        #endif
        
        // Degrade light transmittance based on fog thickness
        transmittance *= stepTransmittance;
        if (transmittance < 0.005f) break;
    }

    shadows *= near;
    shadows *= fSturation;

    return half4(shadows * lightColor, depth);
}