// -----------------------------------------------
// AfterGlow — Lens Distortion Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Barrel / pincushion / fisheye distortion
// with optional chromatic aberration at edges
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set distortion__description Distortion Amount (-100=pincushion 100=barrel/fisheye)
#pragma shaderfilter set distortion__default 40
#pragma shaderfilter set distortion__min -100
#pragma shaderfilter set distortion__max 100
uniform int distortion;

#pragma shaderfilter set zoom__description Zoom (compensate edge crop)
#pragma shaderfilter set zoom__default 50
#pragma shaderfilter set zoom__min 0
#pragma shaderfilter set zoom__max 100
uniform int zoom;

#pragma shaderfilter set chroma__description Chromatic Aberration at Edges
#pragma shaderfilter set chroma__default 25
#pragma shaderfilter set chroma__min 0
#pragma shaderfilter set chroma__max 100
uniform int chroma;

#pragma shaderfilter set vignette__description Edge Vignette
#pragma shaderfilter set vignette__default 30
#pragma shaderfilter set vignette__min 0
#pragma shaderfilter set vignette__max 100
uniform int vignette;

float2 distort(float2 uv, float k) {
    float2 p = uv - 0.5;
    p.x *= 1.7778; // aspect correction
    float r2 = dot(p, p);
    float f = 1.0 + k * r2;
    p = p * f;
    p.x /= 1.7778;
    return p + 0.5;
}

float4 render(float2 uv) {
    float k    = float(distortion) / 100.0 * 0.6;
    float zm   = 1.0 - float(zoom) / 100.0 * 0.25;

    // Zoom toward center before distorting
    float2 zUV = (uv - 0.5) * zm + 0.5;
    float2 dUV = distort(zUV, k);

    // Chromatic aberration: distort R and B channels slightly more/less
    float ca   = float(chroma) / 100.0 * 0.04;
    float2 dUV_r = distort(zUV, k + ca);
    float2 dUV_b = distort(zUV, k - ca);

    // Edge clip: if distorted UV is outside 0..1 show black
    float edgeR = float(all(dUV_r >= 0.0) && all(dUV_r <= 1.0));
    float edgeG = float(all(dUV   >= 0.0) && all(dUV   <= 1.0));
    float edgeB = float(all(dUV_b >= 0.0) && all(dUV_b <= 1.0));

    float r = image.Sample(builtin_texture_sampler, saturate(dUV_r)).r * edgeR;
    float g = image.Sample(builtin_texture_sampler, saturate(dUV)).g   * edgeG;
    float b = image.Sample(builtin_texture_sampler, saturate(dUV_b)).b * edgeB;
    float3 col = float3(r, g, b);

    // Vignette
    float vigAmt = float(vignette) / 100.0;
    float2 vc = (uv - 0.5) * float2(1.7778, 1.0);
    float vig = 1.0 - smoothstep(0.35, 1.0, length(vc) * (0.6 + vigAmt * 0.6));
    col *= vig;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
