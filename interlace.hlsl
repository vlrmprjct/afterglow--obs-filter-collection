// -----------------------------------------------
// AfterGlow — Interlace Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates interlaced video: alternating lines
// shifted, dimmed or offset — old TV/video signal
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set intensity__description Interlace Intensity
#pragma shaderfilter set intensity__default 60
#pragma shaderfilter set intensity__min 0
#pragma shaderfilter set intensity__max 100
uniform int intensity;

#pragma shaderfilter set line_shift__description Horizontal Line Shift
#pragma shaderfilter set line_shift__default 20
#pragma shaderfilter set line_shift__min 0
#pragma shaderfilter set line_shift__max 100
uniform int line_shift;

#pragma shaderfilter set flicker__description Field Flicker
#pragma shaderfilter set flicker__default 30
#pragma shaderfilter set flicker__min 0
#pragma shaderfilter set flicker__max 100
uniform int flicker;

#pragma shaderfilter set scanline_gap__description Scanline Gap Darkness
#pragma shaderfilter set scanline_gap__default 40
#pragma shaderfilter set scanline_gap__min 0
#pragma shaderfilter set scanline_gap__max 100
uniform int scanline_gap;

#pragma shaderfilter set rolling__description Rolling Bar Speed (0=off)
#pragma shaderfilter set rolling__default 0
#pragma shaderfilter set rolling__min 0
#pragma shaderfilter set rolling__max 100
uniform int rolling;

float4 render(float2 uv) {
    float t = builtin_elapsed_time;

    // Determine even/odd line (per pixel row, ~1080 lines)
    float lineIndex = floor(uv.y * 1080.0);
    float isOdd = fmod(lineIndex, 2.0);

    // Horizontal shift for odd lines
    float shift = float(line_shift) / 100.0 * 0.008;
    float2 sampUV = uv;
    sampUV.x += isOdd * shift;

    // Field-based flicker (alternates at ~25Hz)
    float flickerAmt = float(flicker) / 100.0;
    float field = step(0.5, frac(t * 25.0));
    float fieldDim = 1.0 - flickerAmt * 0.25 * field * isOdd;

    float3 col = image.Sample(builtin_texture_sampler, saturate(sampUV)).rgb;
    col *= fieldDim;

    // Scanline gap: darken every other line
    float gap = float(scanline_gap) / 100.0;
    col *= 1.0 - gap * 0.6 * isOdd;

    // Intensity blend with original
    float amt = float(intensity) / 100.0;
    float3 orig = image.Sample(builtin_texture_sampler, uv).rgb;
    col = lerp(orig, col, amt);

    // Rolling interference bar (horizontal dark band scrolling down)
    if (rolling > 0) {
        float rollSpeed = float(rolling) / 100.0 * 0.4;
        float barPos = frac(t * rollSpeed);
        float barWidth = 0.06;
        float bar = smoothstep(0.0, 0.01, abs(uv.y - barPos) - barWidth * 0.5);
        bar = 1.0 - (1.0 - bar) * 0.7;
        col *= bar;
    }

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
