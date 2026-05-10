// -----------------------------------------------
// AfterGlow — Night Vision Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Effects: phosphor green tint, vignette,
//          scanlines, noise, image boost
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// --- Brightness boost (amplify dark areas) ---
#pragma shaderfilter set amplify__description Brightness Amplify
#pragma shaderfilter set amplify__default 60
#pragma shaderfilter set amplify__min 0
#pragma shaderfilter set amplify__max 100
uniform int amplify;

// --- Green phosphor tint intensity ---
#pragma shaderfilter set tint__description Phosphor Tint Intensity
#pragma shaderfilter set tint__default 80
#pragma shaderfilter set tint__min 0
#pragma shaderfilter set tint__max 100
uniform int tint;

// --- Vignette radius ---
#pragma shaderfilter set vignette__description Vignette Strength
#pragma shaderfilter set vignette__default 55
#pragma shaderfilter set vignette__min 0
#pragma shaderfilter set vignette__max 100
uniform int vignette;

// --- Scanline intensity ---
#pragma shaderfilter set scanlines__description Scanline Intensity
#pragma shaderfilter set scanlines__default 25
#pragma shaderfilter set scanlines__min 0
#pragma shaderfilter set scanlines__max 100
uniform int scanlines;

// --- Noise / grain ---
#pragma shaderfilter set grain__description Noise / Grain
#pragma shaderfilter set grain__default 30
#pragma shaderfilter set grain__min 0
#pragma shaderfilter set grain__max 100
uniform int grain;

// --- Lens blur (circular softness at edges) ---
#pragma shaderfilter set blur__description Lens Blur at Edges
#pragma shaderfilter set blur__default 20
#pragma shaderfilter set blur__min 0
#pragma shaderfilter set blur__max 100
uniform int blur;

// --- Noise helper ---
float hash(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float4 render(float2 uv) {
    float t = builtin_elapsed_time;

    // Lens blur: shift UV slightly toward center at edges
    float blurAmt = float(blur) / 100.0 * 0.015;
    float2 center = uv - 0.5;
    float2 blurredUV = uv - center * length(center) * blurAmt * 6.0;
    blurredUV = saturate(blurredUV);

    // Sample luminance only (night vision is monochrome input)
    float3 src = image.Sample(builtin_texture_sampler, blurredUV).rgb;
    float luma = dot(src, float3(0.299, 0.587, 0.114));

    // Amplify: push mid-tones up (simulate image intensifier tube)
    float amp = 1.0 + float(amplify) / 100.0 * 3.0;
    luma = saturate(pow(luma, 1.0 / amp));

    // Phosphor green tint: map luma to green channel with slight blue/red bleed
    float tintAmt = float(tint) / 100.0;
    float3 phosphor = float3(luma * 0.15, luma, luma * 0.25);  // classic NV green
    float3 col = lerp(float3(luma, luma, luma), phosphor, tintAmt);

    // Scanlines
    float sl = float(scanlines) / 100.0;
    float scanline = sin(blurredUV.y * 480.0 * 3.14159) * 0.5 + 0.5;
    col *= 1.0 - sl * 0.4 * (1.0 - scanline);

    // Grain / noise
    float ns = float(grain) / 100.0;
    float2 noiseUV = float2(uv.x + frac(t * 1.7), uv.y + frac(t * 0.9));
    float n = hash(floor(noiseUV * float2(400.0, 300.0)));
    col += (n - 0.5) * ns * 0.3;

    // Vignette: circular darkening toward edges
    float vigAmt = float(vignette) / 100.0;
    float dist = length(center) * 1.414;  // normalize to 0..1 at corner
    float vig = 1.0 - smoothstep(0.3, 1.1, dist * (0.5 + vigAmt));
    col *= vig;

    // Subtle circular tube edge cutoff
    float tube = smoothstep(0.72, 0.68, length(center));
    col *= tube;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
