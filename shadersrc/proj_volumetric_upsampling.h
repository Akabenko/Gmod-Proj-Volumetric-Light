#include "common_ps_fxc.h"

sampler WPDepth             : register( s0 );
sampler TargetTex           : register( s1 );
const float4 Constants0      : register( c0 );
const float4 Constants1      : register( c1 );
const float4 Constants2      : register( c2 );
const float4 Constants3      : register( c3 );
const float2 TexelSize      : register( c4 );
const float2 TargetSize     : register( c5 );

#define lightMul Constants0.w

struct PS_IN
{
    float2 position : VPOS;
    float2 texcoord : TEXCOORD0;
};

#define lightAdd        Constants1.w
#define lightPos        Constants2.xyz
#define G_SCATTERING    Constants2.w

#define lightColor      Constants0.rgb

const float3 EyePos : register( c15 );

static const float PI       = 3.1415925f;
static const float PI4      = 4.0f * PI;

float ComputeScattering(float lightDotView)
{
    float G_SCATTERING2 = G_SCATTERING * G_SCATTERING;
    float result = 1.0f - G_SCATTERING2;
    result /= (PI4 * pow(1.0f + G_SCATTERING2 - (2.0f * G_SCATTERING) * lightDotView, 1.5) );
    return result;
}

#define SampleTex(tex, coord) tex2Dlod(tex, float4(coord, 0.0, 0.0))

half4 main(PS_IN I) : COLOR0 
{
    float4 wpdepth = tex2Dlod(WPDepth, float4(I.texcoord, 0, 0));
    float depth = wpdepth.a;
    half full_res_viewz = 1/depth;

    #if defined(CSM)
    if (depth == 0.00025) 
    {
        float3 worldPos = 1/wpdepth.xyz;
        float3 eyeVec = EyePos - worldPos;
        float3 lightShadowsDir = lightPos;
        float lightDotView = dot( normalize(eyeVec), lightShadowsDir );
        float fSturation = lightMul * lightDotView + lightAdd;
        half scattering = ComputeScattering(lightDotView);
        return half4(scattering * lightColor, 1);
    }
    #endif
    
    #if defined(QUAD)
    float2 low_res_uv = I.texcoord / TargetSize;
    float2 low_res_base = floor(low_res_uv);
    float2 f = frac(low_res_uv);
    
    float2 sample_base = low_res_base - 0.5;
    float2 sample_f = f + 0.5;
    
    float2 uv00 = (sample_base + float2(-1, -1)) * TargetSize;
    float2 uv10 = (sample_base + float2(0, -1)) * TargetSize;
    float2 uv20 = (sample_base + float2(1, -1)) * TargetSize;
    float2 uv30 = (sample_base + float2(2, -1)) * TargetSize;
    
    float2 uv01 = (sample_base + float2(-1, 0)) * TargetSize;
    float2 uv11 = (sample_base + float2(0, 0)) * TargetSize;
    float2 uv21 = (sample_base + float2(1, 0)) * TargetSize;
    float2 uv31 = (sample_base + float2(2, 0)) * TargetSize;
    
    float2 uv02 = (sample_base + float2(-1, 1)) * TargetSize;
    float2 uv12 = (sample_base + float2(0, 1)) * TargetSize;
    float2 uv22 = (sample_base + float2(1, 1)) * TargetSize;
    float2 uv32 = (sample_base + float2(2, 1)) * TargetSize;
    
    float2 uv03 = (sample_base + float2(-1, 2)) * TargetSize;
    float2 uv13 = (sample_base + float2(0, 2)) * TargetSize;
    float2 uv23 = (sample_base + float2(1, 2)) * TargetSize;
    float2 uv33 = (sample_base + float2(2, 2)) * TargetSize;
    
    half4 s00 = SampleTex(TargetTex, uv00);
    half4 s10 = SampleTex(TargetTex, uv10);
    half4 s20 = SampleTex(TargetTex, uv20);
    half4 s30 = SampleTex(TargetTex, uv30);
    
    half4 s01 = SampleTex(TargetTex, uv01);
    half4 s11 = SampleTex(TargetTex, uv11);
    half4 s21 = SampleTex(TargetTex, uv21);
    half4 s31 = SampleTex(TargetTex, uv31);
    
    half4 s02 = SampleTex(TargetTex, uv02);
    half4 s12 = SampleTex(TargetTex, uv12);
    half4 s22 = SampleTex(TargetTex, uv22);
    half4 s32 = SampleTex(TargetTex, uv32);
    
    half4 s03 = SampleTex(TargetTex, uv03);
    half4 s13 = SampleTex(TargetTex, uv13);
    half4 s23 = SampleTex(TargetTex, uv23);
    half4 s33 = SampleTex(TargetTex, uv33);
    
    // Catmull-Rom
    float2 f2 = sample_f * sample_f;
    float2 f3 = f2 * sample_f;
    
    float4 wx = max(0, float4(
        -0.5f * f3.x + f2.x - 0.5f * sample_f.x,
        1.5f * f3.x - 2.5f * f2.x + 1.0f,
        -1.5f * f3.x + 2.0f * f2.x + 0.5f * sample_f.x,
        0.5f * f3.x - 0.5f * f2.x
    ));
    
    float4 wy = max(0, float4(
        -0.5f * f3.y + f2.y - 0.5f * sample_f.y,
        1.5f * f3.y - 2.5f * f2.y + 1.0f,
        -1.5f * f3.y + 2.0f * f2.y + 0.5f * sample_f.y,
        0.5f * f3.y - 0.5f * f2.y
    ));
    
    float4x4 spatial_weights;
    spatial_weights[0] = wx * wy.x;
    spatial_weights[1] = wx * wy.y;
    spatial_weights[2] = wx * wy.z;
    spatial_weights[3] = wx * wy.w;
    
    float4x4 depths = 1/float4x4(
        s00.a, s10.a, s20.a, s30.a,
        s01.a, s11.a, s21.a, s31.a,
        s02.a, s12.a, s22.a, s32.a,
        s03.a, s13.a, s23.a, s33.a
    );
    
    float4x4 depth_weights = 1.0 / (abs(full_res_viewz - depths) + 1e-4);
    
    float4x4 bilat_weights = spatial_weights * depth_weights;
    
    float4x4 r_channel = float4x4(
        s00.r, s10.r, s20.r, s30.r,
        s01.r, s11.r, s21.r, s31.r,
        s02.r, s12.r, s22.r, s32.r,
        s03.r, s13.r, s23.r, s33.r
    );
    
    float4x4 g_channel = float4x4(
        s00.g, s10.g, s20.g, s30.g,
        s01.g, s11.g, s21.g, s31.g,
        s02.g, s12.g, s22.g, s32.g,
        s03.g, s13.g, s23.g, s33.g
    );
    
    float4x4 b_channel = float4x4(
        s00.b, s10.b, s20.b, s30.b,
        s01.b, s11.b, s21.b, s31.b,
        s02.b, s12.b, s22.b, s32.b,
        s03.b, s13.b, s23.b, s33.b
    );
    
    float3 color_sum = float3(
        dot(r_channel[0], bilat_weights[0]) + dot(r_channel[1], bilat_weights[1]) + 
        dot(r_channel[2], bilat_weights[2]) + dot(r_channel[3], bilat_weights[3]),
        
        dot(g_channel[0], bilat_weights[0]) + dot(g_channel[1], bilat_weights[1]) + 
        dot(g_channel[2], bilat_weights[2]) + dot(g_channel[3], bilat_weights[3]),
        
        dot(b_channel[0], bilat_weights[0]) + dot(b_channel[1], bilat_weights[1]) + 
        dot(b_channel[2], bilat_weights[2]) + dot(b_channel[3], bilat_weights[3])
    );
    
    float weight_sum = 
        dot(bilat_weights[0], 1.0) + dot(bilat_weights[1], 1.0) + 
        dot(bilat_weights[2], 1.0) + dot(bilat_weights[3], 1.0);
    
    float3 color = color_sum / max(weight_sum, 1e-4);
    #else
    // Port of Upsample shader by LVutner from S.T.A.L.K.E.R Anomaly DX11 to Gmod
    float4 low_res_00 = tex2Dlod(TargetTex, float4(I.texcoord, 0, 0));
    float4 low_res_10 = tex2Dlod(TargetTex, float4(I.texcoord + float2(TargetSize.x, 0), 0, 0));
    float4 low_res_01 = tex2Dlod(TargetTex, float4(I.texcoord + float2(0, TargetSize.y), 0, 0));
    float4 low_res_11 = tex2Dlod(TargetTex, float4(I.texcoord + TargetSize, 0, 0));
    
    float4 low_res_viewz = 1/float4(
        low_res_00.a,
        low_res_10.a,
        low_res_01.a,
        low_res_11.a
    );
    
    float2 f = frac(I.texcoord / TargetSize);
    float w_00 = (1.0f - f.x) * (1.0f - f.y);
    float w_10 = f.x * (1.0f - f.y);
    float w_01 = (1.0f - f.x) * f.y;
    float w_11 = f.x * f.y;
    
    float4 bilat_weights = float4(w_00, w_10, w_01, w_11) / (abs(full_res_viewz.xxxx - low_res_viewz) + 1e-4);
    
    float4 low_res_r = float4(low_res_00.r, low_res_10.r, low_res_01.r, low_res_11.r);
    float4 low_res_g = float4(low_res_00.g, low_res_10.g, low_res_01.g, low_res_11.g);
    float4 low_res_b = float4(low_res_00.b, low_res_10.b, low_res_01.b, low_res_11.b);
    
    float total_weight = dot(bilat_weights, 1.0);
    float3 color = float3(
        dot(low_res_r, bilat_weights),
        dot(low_res_g, bilat_weights), 
        dot(low_res_b, bilat_weights)
    ) / total_weight;
    #endif
    
    return half4(color, 1.0);
}