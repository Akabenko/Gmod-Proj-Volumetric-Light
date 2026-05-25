#include "common_ps_packdepth.h"
#include "common_ps_fxc.h"

sampler TexSampler     : register( s0 );
sampler WPDepth        : register( s1 );
float2 TexBaseSize     : register( c4 );

//#define Vertical_
//#define TAP4
//#define TAP8
#define TAP16

const float size              : register( c0 );
const float sigma             : register( c1 );
const float2 ppp              : register( c2 );
#define sigma_pow ppp.x
#define sigma_min ppp.y

struct PS_IN
{
    float2 vTexCoord      : TEXCOORD0;
    float2 pos            : VPOS;
};

float3 cEyePos                 : register( c3 );
const float4x4 g_invViewProjMatrix : register( c15 );

float3 reconstructPosition(float2 uv, float z)
{
    return mad( mul( float4(mad(uv, 2, -1),0,1), g_invViewProjMatrix ), z, cEyePos);
}

float wy_sq_cashed(float distance_sq, float sigma2)
{
    return exp(sigma2*distance_sq);
}
//#define TAP16

#if defined(TAP16)
static const int NUM_SAMPLES = 16;
static const float OFFSETS[16] = {
    -7.5, -6.5, -5.5, -4.5, -3.5, -2.5, -1.5, -0.5,
     0.5,  1.5,  2.5,  3.5,  4.5,  5.5,  6.5,  7.5
};
#elif defined(TAP8)
static const int NUM_SAMPLES = 8;
static const float OFFSETS[8] = {
    -3.5, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5
};
#else
static const int NUM_SAMPLES = 4;
static const float OFFSETS[4] = {
    -1.5, -0.5, 0.5, 1.5
};
#endif

half4 main(PS_IN i ) : COLOR
{   
    float4 TexCoords = float4(i.vTexCoord,0,0);   

    float4 wpdepth = tex2Dlod(TexSampler, TexCoords);
    float4 orig = tex2Dlod(TexSampler, TexCoords);

    if (wpdepth.a == 0.00025) return orig;

    float depth = orig.a;
    float inv_depth = 1/depth;
    
    //float3 worldPos = reconstructPosition(TexCoords.xy, inv_depth);
    float3 worldPos = 1/wpdepth.xyz;

    float2 tex_size = TexBaseSize * size;

    float dist = distance(cEyePos, worldPos);
    
    float powed_si = sigma * pow(dist, sigma_pow);
    float sigma2 = -1/(powed_si*powed_si);
    
    float total_weight = 0.0;
    half3 result = 0;

    [unroll]
    for (int x = 0; x < NUM_SAMPLES; ++x) 
    {
        #if defined(Vertical_)
        float2 sample_offset = float2(0, (OFFSETS[x] + 0.5) * tex_size.y);
        #else
        float2 sample_offset = float2((OFFSETS[x] + 0.5) * tex_size.x, 0);
        #endif

        float4 offset = float4(TexCoords + sample_offset,0,0);

        float4 temp = tex2Dlod(TexSampler, offset);
        float viewz = temp.a;
        if (viewz == 0.00025) continue;

        float diff = ( inv_depth - 1/viewz );
        diff = diff * diff;
        
        float weight = wy_sq_cashed(diff, sigma2);
        result += temp.rgb * weight;
        total_weight += weight;
    }
    
    result = (total_weight > sigma_min) ? (result / total_weight) : orig.rgb;

    return half4(result, depth);
};