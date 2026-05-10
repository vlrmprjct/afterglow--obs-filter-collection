// -----------------------------------------------
// AfterGlow — Spectrum Analyzer for OBS Studio
// Requires: obs-shaderfilter plugin
// Displays the audio frequency spectrum as bars
// overlaid on the source image.
// -----------------------------------------------

// --- Audio input ---
#pragma shaderfilter set main__mix__description Audio Mix/Track
#pragma shaderfilter set main__channel__description Audio Channel
#pragma shaderfilter set main__dampening_factor_attack 0.0
#pragma shaderfilter set main__dampening_factor_release 0.6
uniform texture2d builtin_texture_fft_main;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// --- Bar color (RGBA color picker in OBS) ---
#pragma shaderfilter set fft_color__description Spectrum Color
#pragma shaderfilter set fft_color__default 00E5CCFF
uniform float4 fft_color;

// --- Frequency range ---
#pragma shaderfilter set freq_min__description Frequency Range Min (0=bass)
#pragma shaderfilter set freq_min__default 0
#pragma shaderfilter set freq_min__min 0
#pragma shaderfilter set freq_min__max 100
uniform int freq_min;

#pragma shaderfilter set freq_max__description Frequency Range Max (100=treble)
#pragma shaderfilter set freq_max__default 60
#pragma shaderfilter set freq_max__min 0
#pragma shaderfilter set freq_max__max 100
uniform int freq_max;

// --- Discrete bars (HiFi analyzer style) ---
#pragma shaderfilter set bar_count__description Number of Bars (1 = continuous)
#pragma shaderfilter set bar_count__default 32
#pragma shaderfilter set bar_count__min 1
#pragma shaderfilter set bar_count__max 100
uniform int bar_count;

#pragma shaderfilter set bar_gap__description Gap Between Bars (0-80)
#pragma shaderfilter set bar_gap__default 20
#pragma shaderfilter set bar_gap__min 0
#pragma shaderfilter set bar_gap__max 80
uniform int bar_gap;

// --- Smoothing ---
#pragma shaderfilter set smooth_level__description Frequency Smoothing
#pragma shaderfilter set smooth_level__default 20
#pragma shaderfilter set smooth_level__min 0
#pragma shaderfilter set smooth_level__max 100
uniform int smooth_level;

// --- Glow / Bloom ---
#pragma shaderfilter set glow__description Bar Glow / Bloom Intensity
#pragma shaderfilter set glow__default 40
#pragma shaderfilter set glow__min 0
#pragma shaderfilter set glow__max 100
uniform int glow;

// --- Bar opacity ---
#pragma shaderfilter set opacity__description Bar Opacity
#pragma shaderfilter set opacity__default 90
#pragma shaderfilter set opacity__min 0
#pragma shaderfilter set opacity__max 100
uniform int opacity;

// --- Helper: linear remap ---
float remap(float x, float2 from, float2 to) {
    float normalized = (x - from[0]) / (from[1] - from[0]);
    return normalized * (to[1] - to[0]) + to[0];
}

// --- Sample FFT amplitude at a given frequency (0..1), with smoothing ---
float sampleFFT(float freq, float smoothWidth) {
    if (smoothWidth <= 0.001) {
        return builtin_texture_fft_main.Sample(builtin_texture_sampler, float2(freq, 0.5)).r;
    }
    float sum = 0.0;
    int steps = 32;
    for (int i = 0; i < steps; i++) {
        float offset = smoothWidth * (float(i) / float(steps - 1) - 0.5);
        float s = builtin_texture_fft_main.Sample(builtin_texture_sampler, float2(saturate(freq + offset), 0.5)).r;
        sum += s;
    }
    return sum / float(steps);
}

float4 render(float2 uv) {
    float fmin = float(freq_min) / 100.0;
    float fmax = float(freq_max) / 100.0;
    if (fmax <= fmin) fmax = fmin + 0.01;

    float smoothWidth = float(smooth_level) / 100.0 * 0.8;  // 0 .. 0.8 across spectrum

    // Map UV.x to the selected frequency range
    float freq = lerp(fmin, fmax, uv.x);

    // Snap to discrete bar if bar_count > 1
    float barUV = uv.x; // position within bar (0..1)
    if (bar_count > 1) {
        float n = float(bar_count);
        float barIndex = floor(uv.x * n);
        barUV = frac(uv.x * n); // 0..1 within the bar
        freq = lerp(fmin, fmax, (barIndex + 0.5) / n);
    }

    float amplitude = sampleFFT(freq, smoothWidth);

    // Convert to dB, remap to 0..1
    float db = 20.0 * log(amplitude / 0.5) / log(10.0);
    float db_norm = saturate(remap(db, float2(-50.0, 0.0), float2(0.0, 1.0)));

    // Gap mask: cut left/right edges of each bar
    float gapFrac = float(bar_gap) / 100.0 * 0.5;
    float gapMask = (bar_count > 1) ? float(barUV > gapFrac && barUV < 1.0 - gapFrac) : 1.0;

    // Pixel lights up when below bar height, and within bar (not in gap)
    float lit = float(1.0 - uv.y < db_norm) * gapMask;

    // Glow: soft falloff above and around the bar edge
    float glowAmt = float(glow) / 100.0;
    float distToEdge = abs((1.0 - uv.y) - db_norm);  // distance from bar top
    float glowFalloff = exp(-distToEdge * 30.0) * glowAmt * gapMask;
    // Horizontal glow within bar gap zone
    float edgeDist = min(barUV - gapFrac, (1.0 - gapFrac) - barUV);
    float hGlow = (bar_count > 1) ? saturate(edgeDist * 8.0) : 1.0;
    float totalGlow = glowFalloff * hGlow;

    float alpha = fft_color.a * (float(opacity) / 100.0) * saturate(lit + totalGlow);
    float3 bg = image.Sample(builtin_texture_sampler, uv).rgb;
    // Additive blend for the glow portion for a luminous look
    float3 col = lerp(bg, fft_color.rgb, alpha) + fft_color.rgb * totalGlow * fft_color.a * 0.5;
    return float4(lerp(bg, saturate(col), float(enabled)), 1.0);
}

