// -----------------------------------------------
// AfterGlow — CGA Palette Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Reduces image to classic CGA/EGA color palettes
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set palette__description Palette (0=CGA1 1=CGA2 2=CGA3 3=EGA16 4=GameBoy)
#pragma shaderfilter set palette__default 0
#pragma shaderfilter set palette__min 0
#pragma shaderfilter set palette__max 4
uniform int palette;

#pragma shaderfilter set pixel_scale__description Pixel Block Size
#pragma shaderfilter set pixel_scale__default 3
#pragma shaderfilter set pixel_scale__min 1
#pragma shaderfilter set pixel_scale__max 12
uniform int pixel_scale;

#pragma shaderfilter set dither__description Dither Strength
#pragma shaderfilter set dither__default 30
#pragma shaderfilter set dither__min 0
#pragma shaderfilter set dither__max 100
uniform int dither;

// -----------------------------------------------
// Palettes (all colors as float3 RGB 0..1)
// -----------------------------------------------

// CGA Palette 1 (cyan/magenta/white + black)
float3 cga1(int i) {
    if (i == 0) return float3(0.0,  0.0,  0.0);
    if (i == 1) return float3(0.33, 1.0,  1.0);
    if (i == 2) return float3(1.0,  0.33, 1.0);
    return              float3(1.0,  1.0,  1.0);
}

// CGA Palette 2 (green/red/yellow + black)
float3 cga2(int i) {
    if (i == 0) return float3(0.0,  0.0,  0.0);
    if (i == 1) return float3(0.33, 1.0,  0.33);
    if (i == 2) return float3(1.0,  0.33, 0.33);
    return              float3(1.0,  1.0,  0.33);
}

// CGA Palette 3 (cyan/red/white high intensity)
float3 cga3(int i) {
    if (i == 0) return float3(0.0,  0.0,  0.0);
    if (i == 1) return float3(0.0,  1.0,  1.0);
    if (i == 2) return float3(1.0,  0.0,  0.0);
    return              float3(1.0,  1.0,  1.0);
}

// EGA 16 color
float3 ega16(int i) {
    if (i == 0)  return float3(0.0,  0.0,  0.0);
    if (i == 1)  return float3(0.0,  0.0,  0.67);
    if (i == 2)  return float3(0.0,  0.67, 0.0);
    if (i == 3)  return float3(0.0,  0.67, 0.67);
    if (i == 4)  return float3(0.67, 0.0,  0.0);
    if (i == 5)  return float3(0.67, 0.0,  0.67);
    if (i == 6)  return float3(0.67, 0.33, 0.0);
    if (i == 7)  return float3(0.67, 0.67, 0.67);
    if (i == 8)  return float3(0.33, 0.33, 0.33);
    if (i == 9)  return float3(0.33, 0.33, 1.0);
    if (i == 10) return float3(0.33, 1.0,  0.33);
    if (i == 11) return float3(0.33, 1.0,  1.0);
    if (i == 12) return float3(1.0,  0.33, 0.33);
    if (i == 13) return float3(1.0,  0.33, 1.0);
    if (i == 14) return float3(1.0,  1.0,  0.33);
    return              float3(1.0,  1.0,  1.0);
}

// GameBoy (4 greens)
float3 gameboy(int i) {
    if (i == 0) return float3(0.06, 0.22, 0.06);
    if (i == 1) return float3(0.19, 0.38, 0.19);
    if (i == 2) return float3(0.55, 0.67, 0.06);
    return              float3(0.61, 0.73, 0.06);
}

// Bayer 4x4 dither
float bayer4(int x, int y) {
    int m[16] = { 0,8,2,10, 12,4,14,6, 3,11,1,9, 15,7,13,5 };
    return float(m[(y%4)*4+(x%4)]) / 16.0 - 0.5;
}

float colDist(float3 a, float3 b) {
    float3 d = a - b;
    return dot(d, d);
}

float3 nearestColor(float3 col, int pal) {
    float3 best = float3(0,0,0);
    float bestD = 1e9;
    int count = (pal == 3) ? 16 : (pal == 4 ? 4 : 4);
    for (int i = 0; i < 16; i++) {
        if (i >= count) break;
        float3 c;
        if (pal == 0) c = cga1(i);
        else if (pal == 1) c = cga2(i);
        else if (pal == 2) c = cga3(i);
        else if (pal == 3) c = ega16(i);
        else               c = gameboy(i);
        float d = colDist(col, c);
        if (d < bestD) { bestD = d; best = c; }
    }
    return best;
}

float4 render(float2 uv) {
    float ps  = float(pixel_scale);
    float cellW = ps / 1920.0;
    float cellH = ps / 1080.0;

    float2 snapped = (floor(uv / float2(cellW, cellH)) + 0.5) * float2(cellW, cellH);
    float3 src = image.Sample(builtin_texture_sampler, saturate(snapped)).rgb;

    // Optional dither offset
    int ix = int(uv.x / cellW);
    int iy = int(uv.y / cellH);
    float ditherOffset = bayer4(ix, iy) * (float(dither) / 100.0) * 0.3;
    float3 dithered = saturate(src + ditherOffset);

    float3 col = nearestColor(dithered, palette);
    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, col, float(enabled)), 1.0);
}
