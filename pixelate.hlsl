// -----------------------------------------------
// AfterGlow — Pixelate Overlay Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set block_size__description Block Size (0-100)
#pragma shaderfilter set block_size__default 20
#pragma shaderfilter set block_size__min 0
#pragma shaderfilter set block_size__max 100
uniform int block_size;

float4 render(float2 uv) {
    float res = float(block_size) / 100.0 * 0.2 + 0.002;

    float2 snapped = floor(uv / res) * res + res * 0.5;
    float4 _pixelated = image.Sample(builtin_texture_sampler, snapped);
    float4 _original  = image.Sample(builtin_texture_sampler, uv);
    return lerp(_original, _pixelated, float(enabled));
}
