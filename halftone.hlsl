// -----------------------------------------------
// AfterGlow — Halftone Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Renders image as a dot raster like newspaper
// print, offset printing or pop-art / comic look
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set dot_size__description Dot / Cell Size
#pragma shaderfilter set dot_size__default 20
#pragma shaderfilter set dot_size__min 4
#pragma shaderfilter set dot_size__max 60
uniform int dot_size;

#pragma shaderfilter set angle__description Screen Angle (0-100 maps to 0-45 deg)
#pragma shaderfilter set angle__default 25
#pragma shaderfilter set angle__min 0
#pragma shaderfilter set angle__max 100
uniform int angle;

#pragma shaderfilter set colored__description Colored Dots (0=monochrome)
#pragma shaderfilter set colored__default 0
#pragma shaderfilter set colored__min 0
#pragma shaderfilter set colored__max 1
uniform int colored;

#pragma shaderfilter set bg_white__description White Background (0=black)
#pragma shaderfilter set bg_white__default 1
#pragma shaderfilter set bg_white__min 0
#pragma shaderfilter set bg_white__max 1
uniform int bg_white;

#pragma shaderfilter set softness__description Dot Edge Softness
#pragma shaderfilter set softness__default 20
#pragma shaderfilter set softness__min 0
#pragma shaderfilter set softness__max 100
uniform int softness;

float4 render(float2 uv) {
    float cs = float(dot_size);
    float cellW = cs / 1920.0;
    float cellH = cs / 1080.0;

    // Rotation angle
    float a = float(angle) / 100.0 * 0.785398; // 0..45 degrees
    float cosA = cos(a);
    float sinA = sin(a);

    // Rotate UV for screen angle
    float2 p = uv - 0.5;
    p.x *= 1.7778;
    float2 rp = float2(cosA * p.x - sinA * p.y, sinA * p.x + cosA * p.y);
    rp.x /= 1.7778;

    // Snap to grid cell center
    float2 cellUV = float2(cellW, cellH);
    float2 snapped = (floor(rp / cellUV) + 0.5) * cellUV;

    // Un-rotate to get original UV for sampling
    float2 sp = snapped;
    sp.x *= 1.7778;
    float2 sOrig = float2(cosA * sp.x + sinA * sp.y, -sinA * sp.x + cosA * sp.y);
    sOrig.x /= 1.7778;
    sOrig += 0.5;

    float3 src = image.Sample(builtin_texture_sampler, saturate(sOrig)).rgb;
    float luma = dot(src, float3(0.299, 0.587, 0.114));

    // Dot radius proportional to luminance
    // For white bg: dark areas = big dots; bright areas = small dots
    float dotR = (bg_white > 0) ? (1.0 - luma) : luma;
    dotR = dotR * 0.5; // max radius = 0.5 cell

    // Distance from cell center (in rotated cell space)
    float2 diff = rp - snapped;
    diff.x *= 1.7778;
    float dist = length(diff) / (cs / 1920.0 * 0.5);

    float soft = float(softness) / 100.0 * 0.3 + 0.02;
    float dot_ = 1.0 - smoothstep(dotR - soft, dotR + soft, dist * 0.5);

    float3 fg = colored > 0 ? src : (bg_white > 0 ? float3(0,0,0) : float3(1,1,1));
    float3 bg = bg_white > 0 ? float3(1,1,1) : float3(0,0,0);

    float3 col = lerp(bg, fg, dot_);
    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
