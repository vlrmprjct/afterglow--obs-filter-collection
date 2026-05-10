// -----------------------------------------------
// AfterGlow — ASCII Art Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Renders the image as a grid of ASCII characters
// approximated by luminance-mapped block patterns
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set cell_size__description Cell Size (character grid)
#pragma shaderfilter set cell_size__default 12
#pragma shaderfilter set cell_size__min 4
#pragma shaderfilter set cell_size__max 40
uniform int cell_size;

#pragma shaderfilter set colored__description Colored Output (0=monochrome)
#pragma shaderfilter set colored__default 1
#pragma shaderfilter set colored__min 0
#pragma shaderfilter set colored__max 1
uniform int colored;

#pragma shaderfilter set bg_dark__description Dark Background Intensity
#pragma shaderfilter set bg_dark__default 10
#pragma shaderfilter set bg_dark__min 0
#pragma shaderfilter set bg_dark__max 100
uniform int bg_dark;

// -----------------------------------------------
// ASCII character approximation via 5x5 bitmask
// 10 levels: space . : - = + * # % @
// -----------------------------------------------
float charPattern(float2 cp, int level) {
    // cp: 0..1 within the cell, level: 0..9
    int px = int(cp.x * 5.0);
    int py = int(cp.y * 5.0);
    int bit = py * 5 + px;

    // Each character encoded as a 25-bit mask (stored in two ints)
    // 0: space
    if (level == 0) return 0.0;
    // 1: .  (single center dot)
    if (level == 1) { int2 p = int2(px,py); return float(p.x==2 && p.y==2); }
    // 2: :  (two dots)
    if (level == 2) { return float((px==2&&py==1)||(px==2&&py==3)); }
    // 3: -  (horizontal bar)
    if (level == 3) { return float(py==2 && px>=1 && px<=3); }
    // 4: =  (two horizontal bars)
    if (level == 4) { return float((py==1||py==3) && px>=1 && px<=3); }
    // 5: +  (cross)
    if (level == 5) { return float(px==2||py==2); }
    // 6: *  (diagonal + center cross)
    if (level == 6) { return float(px==2||py==2||(px==py)||(px+py==4)); }
    // 7: #  (grid)
    if (level == 7) { return float(px==1||px==3||py==1||py==3); }
    // 8: %  (dense)
    if (level == 8) { return float((px%2==0)||(py%2==0)); }
    // 9: @  (full block)
    if (level == 9) { return 1.0; }
    return 0.0;
}

float4 render(float2 uv) {
    float cs = float(cell_size);

    // Snap UV to cell center for sampling
    float2 cellUV = floor(uv * (1.0 / cs * 1000.0)) / (1.0 / cs * 1000.0);

    // Use uv_size builtin isn't available; approximate cell in UV space
    // We work purely in UV: cell size relative to a 1920-wide image guess
    float cellW = cs / 1920.0;
    float cellH = cs / 1080.0;

    float2 snapped = (floor(uv / float2(cellW, cellH)) + 0.5) * float2(cellW, cellH);
    float3 src = image.Sample(builtin_texture_sampler, saturate(snapped)).rgb;
    float luma = dot(src, float3(0.299, 0.587, 0.114));

    // Map luma to character level 0..9
    int level = int(saturate(luma) * 9.9);

    // Position within cell (0..1)
    float2 cellPos = frac(uv / float2(cellW, cellH));

    float pattern = charPattern(cellPos, level);

    // Output color
    float3 bg    = float3(float(bg_dark) / 100.0 * 0.15, float(bg_dark) / 100.0 * 0.15, float(bg_dark) / 100.0 * 0.15);
    float3 fg    = (colored > 0) ? src : float3(luma, luma, luma);

    float3 col = lerp(bg, fg, pattern);
    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, col, float(enabled)), 1.0);
}
