// -----------------------------------------------
// AfterGlow — Dithering Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Bayer ordered dithering — classic 1-bit or
// palette-quantized look (old Mac, Atari, GameBoy)
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set levels__description Color Levels per Channel
#pragma shaderfilter set levels__default 4
#pragma shaderfilter set levels__min 2
#pragma shaderfilter set levels__max 16
uniform int levels;

#pragma shaderfilter set matrix_size__description Dither Matrix Size (2/4/8)
#pragma shaderfilter set matrix_size__default 50
#pragma shaderfilter set matrix_size__min 0
#pragma shaderfilter set matrix_size__max 100
uniform int matrix_size;  // 0-33=2x2, 34-66=4x4, 67-100=8x8

#pragma shaderfilter set pixel_scale__description Pixel Block Size
#pragma shaderfilter set pixel_scale__default 2
#pragma shaderfilter set pixel_scale__min 1
#pragma shaderfilter set pixel_scale__max 8
uniform int pixel_scale;

#pragma shaderfilter set colored__description Colored (0 = monochrome)
#pragma shaderfilter set colored__default 1
#pragma shaderfilter set colored__min 0
#pragma shaderfilter set colored__max 1
uniform int colored;

// 8x8 Bayer matrix, normalized to 0..1
float bayer8(int x, int y) {
    int m[64] = {
         0, 32,  8, 40,  2, 34, 10, 42,
        48, 16, 56, 24, 50, 18, 58, 26,
        12, 44,  4, 36, 14, 46,  6, 38,
        60, 28, 52, 20, 62, 30, 54, 22,
         3, 35, 11, 43,  1, 33,  9, 41,
        51, 19, 59, 27, 49, 17, 57, 25,
        15, 47,  7, 39, 13, 45,  5, 37,
        63, 31, 55, 23, 61, 29, 53, 21
    };
    return float(m[(y % 8) * 8 + (x % 8)]) / 64.0;
}

float bayer4(int x, int y) {
    int m[16] = { 0,8,2,10, 12,4,14,6, 3,11,1,9, 15,7,13,5 };
    return float(m[(y % 4) * 4 + (x % 4)]) / 16.0;
}

float bayer2(int x, int y) {
    int m[4] = { 0,2, 3,1 };
    return float(m[(y % 2) * 2 + (x % 2)]) / 4.0;
}

float4 render(float2 uv) {
    float ps = float(pixel_scale);
    float cellW = ps / 1920.0;
    float cellH = ps / 1080.0;

    // Snap to pixel block
    float2 snapped = (floor(uv / float2(cellW, cellH)) + 0.5) * float2(cellW, cellH);
    float3 src = image.Sample(builtin_texture_sampler, saturate(snapped)).rgb;

    // Integer pixel coordinate for dither matrix lookup
    int ix = int(uv.x / cellW);
    int iy = int(uv.y / cellH);

    // Pick dither threshold
    float threshold;
    int ms = matrix_size;
    if (ms < 34)       threshold = bayer2(ix, iy);
    else if (ms < 67)  threshold = bayer4(ix, iy);
    else               threshold = bayer8(ix, iy);

    // Quantize each channel
    float n = float(levels) - 1.0;
    float3 quantized;
    float3 ch = colored > 0 ? src : float3(dot(src, float3(0.299,0.587,0.114)).xxx);
    quantized.r = floor(ch.r * n + threshold) / n;
    quantized.g = floor(ch.g * n + threshold) / n;
    quantized.b = floor(ch.b * n + threshold) / n;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(quantized), float(enabled)), 1.0);
}
