// -----------------------------------------------
// AfterGlow — Cross Process Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates cross-processing (E-6 slide film
// developed in C-41 chemistry): unnatural color
// shifts, high contrast, boosted greens/blues,
// crushed shadows in red channel
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set strength__description Effect Strength
#pragma shaderfilter set strength__default 80
#pragma shaderfilter set strength__min 0
#pragma shaderfilter set strength__max 100
uniform int strength;

#pragma shaderfilter set preset__description Preset (0=E6inC41 1=C41inE6 2=ECN2 3=Custom)
#pragma shaderfilter set preset__default 0
#pragma shaderfilter set preset__min 0
#pragma shaderfilter set preset__max 3
uniform int preset;

#pragma shaderfilter set contrast__description Contrast
#pragma shaderfilter set contrast__default 60
#pragma shaderfilter set contrast__min 0
#pragma shaderfilter set contrast__max 100
uniform int contrast;

#pragma shaderfilter set saturation__description Saturation
#pragma shaderfilter set saturation__default 70
#pragma shaderfilter set saturation__min 0
#pragma shaderfilter set saturation__max 100
uniform int saturation;

#pragma shaderfilter set grain__description Film Grain
#pragma shaderfilter set grain__default 25
#pragma shaderfilter set grain__min 0
#pragma shaderfilter set grain__max 100
uniform int grain;

float hash(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

// Per-channel curve using a simple gamma-style push
float curve(float x, float lift, float gamma, float gain) {
    x = x * gain + lift;
    return saturate(pow(max(x, 0.0), gamma));
}

float4 render(float2 uv) {
    float t   = builtin_elapsed_time;
    float str = float(strength) / 100.0;
    float3 src = image.Sample(builtin_texture_sampler, uv).rgb;

    // --- Per-channel curves based on preset ---
    float3 col;

    if (preset == 0) {
        // E-6 in C-41: crushed red shadows, boosted green, shifted blue
        col.r = curve(src.r, -0.05, 1.6,  1.1);   // crush shadows, lift mids
        col.g = curve(src.g,  0.02, 0.75, 1.15);  // boost, brighten
        col.b = curve(src.b,  0.08, 0.85, 0.95);  // shift blue toward cyan
    } else if (preset == 1) {
        // C-41 in E-6: orange/red cast, desaturated greens, strong blue shadows
        col.r = curve(src.r,  0.05, 0.8,  1.2);
        col.g = curve(src.g, -0.03, 1.2,  0.9);
        col.b = curve(src.b, -0.08, 1.4,  1.1);
    } else if (preset == 2) {
        // ECN-2 (cinema film in photo chemistry): muted, brownish cast
        col.r = curve(src.r,  0.06, 0.9,  1.05);
        col.g = curve(src.g,  0.03, 1.0,  0.95);
        col.b = curve(src.b, -0.06, 1.3,  0.85);
    } else {
        // Custom: aggressive split — cyan shadows, yellow highlights
        col.r = curve(src.r, -0.08, 1.8,  1.0);
        col.g = curve(src.g,  0.04, 0.7,  1.2);
        col.b = curve(src.b,  0.10, 0.65, 1.1);
    }

    // --- Contrast (S-curve) ---
    float ct = float(contrast) / 100.0;
    col = lerp(col, smoothstep(0.0, 1.0, col), ct);

    // --- Saturation ---
    float luma = dot(col, float3(0.299, 0.587, 0.114));
    float sat = 1.0 + float(saturation) / 100.0 * 1.0;
    col = lerp(float3(luma, luma, luma), col, sat);

    // --- Blend with original by strength ---
    col = lerp(src, col, str);

    // --- Film grain ---
    float ns = float(grain) / 100.0;
    float2 noiseUV = floor(uv * float2(1920.0, 1080.0) + frac(t * float2(1.7, 1.1)) * 400.0);
    float n = hash(noiseUV);
    col += (n - 0.5) * ns * 0.12;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
