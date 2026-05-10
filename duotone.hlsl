// -----------------------------------------------
// AfterGlow — Duotone Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Maps image luminance between two colors:
// shadows -> color A, highlights -> color B
// Classic poster / risograph / screen print look
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set color_a__description Shadow Color
#pragma shaderfilter set color_a__default 1A0A2EFF
uniform float4 color_a;

#pragma shaderfilter set color_b__description Highlight Color
#pragma shaderfilter set color_b__default FF6B35FF
uniform float4 color_b;

#pragma shaderfilter set contrast__description Contrast / Midpoint Push
#pragma shaderfilter set contrast__default 50
#pragma shaderfilter set contrast__min 0
#pragma shaderfilter set contrast__max 100
uniform int contrast;

#pragma shaderfilter set mix__description Mix with Original Image
#pragma shaderfilter set mix__default 0
#pragma shaderfilter set mix__min 0
#pragma shaderfilter set mix__max 100
uniform int mix;

#pragma shaderfilter set grain__description Film Grain
#pragma shaderfilter set grain__default 15
#pragma shaderfilter set grain__min 0
#pragma shaderfilter set grain__max 100
uniform int grain;

float hash(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float4 render(float2 uv) {
    float t = builtin_elapsed_time;
    float3 src = image.Sample(builtin_texture_sampler, uv).rgb;

    // Luminance
    float luma = dot(src, float3(0.299, 0.587, 0.114));

    // Contrast curve: push midtones toward extremes
    float c = float(contrast) / 100.0;
    luma = saturate((luma - 0.5) * (1.0 + c * 2.0) + 0.5);

    // Map luma to duotone: 0=color_a, 1=color_b
    float3 duotone = lerp(color_a.rgb, color_b.rgb, luma);

    // Optional mix with original
    float mixAmt = float(mix) / 100.0;
    float3 col = lerp(duotone, src, mixAmt);

    // Film grain
    float ns = float(grain) / 100.0;
    float2 noiseUV = floor(uv * float2(1920.0, 1080.0) + frac(t * float2(1.3, 0.9)) * float2(400.0, 300.0));
    float n = hash(noiseUV);
    col += (n - 0.5) * ns * 0.15;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
