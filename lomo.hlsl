// -----------------------------------------------
// AfterGlow — Lomo Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates Lomography camera characteristics:
// heavy vignette, boosted saturation, slight color
// shift, lifted shadows, gentle S-curve contrast
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set vignette__description Vignette Strength
#pragma shaderfilter set vignette__default 70
#pragma shaderfilter set vignette__min 0
#pragma shaderfilter set vignette__max 100
uniform int vignette;

#pragma shaderfilter set saturation__description Saturation Boost
#pragma shaderfilter set saturation__default 65
#pragma shaderfilter set saturation__min 0
#pragma shaderfilter set saturation__max 100
uniform int saturation;

#pragma shaderfilter set contrast__description S-Curve Contrast
#pragma shaderfilter set contrast__default 55
#pragma shaderfilter set contrast__min 0
#pragma shaderfilter set contrast__max 100
uniform int contrast;

#pragma shaderfilter set fade__description Shadow Lift (matte)
#pragma shaderfilter set fade__default 15
#pragma shaderfilter set fade__min 0
#pragma shaderfilter set fade__max 100
uniform int fade;

#pragma shaderfilter set color_shift__description Color Shift (0=none 100=warm-red/cool-blue)
#pragma shaderfilter set color_shift__default 40
#pragma shaderfilter set color_shift__min 0
#pragma shaderfilter set color_shift__max 100
uniform int color_shift;

#pragma shaderfilter set grain__description Film Grain
#pragma shaderfilter set grain__default 20
#pragma shaderfilter set grain__min 0
#pragma shaderfilter set grain__max 100
uniform int grain;

float hash(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Simple S-curve via smoothstep
float scurve(float x, float strength) {
    float s = lerp(x, smoothstep(0.0, 1.0, x), strength);
    return s;
}

float4 render(float2 uv) {
    float t = builtin_elapsed_time;
    float3 col = image.Sample(builtin_texture_sampler, uv).rgb;

    // --- S-curve contrast per channel ---
    float ct = float(contrast) / 100.0;
    col.r = scurve(col.r, ct);
    col.g = scurve(col.g, ct);
    col.b = scurve(col.b, ct);

    // --- Shadow lift ---
    float fadeAmt = float(fade) / 100.0 * 0.15;
    col = col * (1.0 - fadeAmt) + fadeAmt;

    // --- Saturation boost ---
    float luma = dot(col, float3(0.299, 0.587, 0.114));
    float sat = 1.0 + float(saturation) / 100.0 * 1.2;
    col = lerp(float3(luma, luma, luma), col, sat);

    // --- Lomo color shift: warm reds/yellows, cooler blues in shadows ---
    float cs = float(color_shift) / 100.0;
    col.r += cs * 0.06 * (1.0 - luma);   // warm shadows
    col.g -= cs * 0.02 * luma;            // slight green pull in highlights
    col.b += cs * 0.05 * luma;            // cool blue highlights
    col.b -= cs * 0.04 * (1.0 - luma);   // remove blue from shadows

    // --- Heavy vignette (characteristic Lomo oval) ---
    float vigAmt = float(vignette) / 100.0;
    float2 vc = (uv - 0.5) * float2(1.4, 1.0);
    float vig = 1.0 - smoothstep(0.3, 0.85, length(vc) * (0.6 + vigAmt * 0.7));
    col *= vig;

    // --- Film grain ---
    float ns = float(grain) / 100.0;
    float2 noiseUV = floor(uv * float2(1920.0, 1080.0) + frac(t * float2(1.3, 0.9)) * 400.0);
    float n = hash(noiseUV);
    col += (n - 0.5) * ns * 0.12;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
