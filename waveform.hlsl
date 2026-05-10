// -----------------------------------------------
// AfterGlow — Audio Waveform Overlay Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// -----------------------------------------------

// Audio source settings
#pragma shaderfilter set main__mix__description Main Mix/Track
#pragma shaderfilter set main__channel__description Main Channel
#pragma shaderfilter set main__dampening_factor_attack 0.05
#pragma shaderfilter set main__dampening_factor_release 0.2
uniform texture2d builtin_texture_fft_main;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// Waveform color (RGBA hex)
#pragma shaderfilter set wave_color__description Waveform Color
#pragma shaderfilter set wave_color__default 00FF88FF
uniform float4 wave_color;

// Vertical center position (0 = top, 100 = bottom)
#pragma shaderfilter set center_y__description Vertical Position (0-100)
#pragma shaderfilter set center_y__default 80
#pragma shaderfilter set center_y__min 0
#pragma shaderfilter set center_y__max 100
uniform int center_y;

// Amplitude scale (how tall the wave can get)
#pragma shaderfilter set amplitude__description Amplitude Scale (0-100)
#pragma shaderfilter set amplitude__default 30
#pragma shaderfilter set amplitude__min 1
#pragma shaderfilter set amplitude__max 100
uniform int amplitude;

// Line thickness
#pragma shaderfilter set thickness__description Line Thickness (0-100)
#pragma shaderfilter set thickness__default 8
#pragma shaderfilter set thickness__min 1
#pragma shaderfilter set thickness__max 100
uniform int thickness;

// Glow/blur softness around the line
#pragma shaderfilter set glow__description Glow Softness (0-100)
#pragma shaderfilter set glow__default 16
#pragma shaderfilter set glow__min 0
#pragma shaderfilter set glow__max 100
uniform int glow;

// Background video opacity below the waveform bar
#pragma shaderfilter set bg_dim__description Background Dimming (0-100)
#pragma shaderfilter set bg_dim__default 0
#pragma shaderfilter set bg_dim__min 0
#pragma shaderfilter set bg_dim__max 100
uniform int bg_dim;

// Height of the waveform background bar (0 = off)
#pragma shaderfilter set bar_height__description Background Bar Height (0-100)
#pragma shaderfilter set bar_height__default 0
#pragma shaderfilter set bar_height__min 0
#pragma shaderfilter set bar_height__max 100
uniform int bar_height;

// Frequency range (0 = 0 Hz, 100 = Nyquist ~22 kHz)
// Typical speech/music: 0 to 15 (covers ~0-3300 Hz)
#pragma shaderfilter set freq_min__description Frequency Range Min (0-100)
#pragma shaderfilter set freq_min__default 0
#pragma shaderfilter set freq_min__min 0
#pragma shaderfilter set freq_min__max 100
uniform int freq_min;

#pragma shaderfilter set freq_max__description Frequency Range Max (0-100)
#pragma shaderfilter set freq_max__default 15
#pragma shaderfilter set freq_max__min 0
#pragma shaderfilter set freq_max__max 100
uniform int freq_max;

float4 render(float2 uv)
{
    float4 video = image.Sample(builtin_texture_sampler, uv);

    // Scale parameters from 0-100 to internal values
    float center_y_f   = float(center_y)   / 100.0;          // 0.0 - 1.0
    float amplitude_f  = float(amplitude)  / 100.0 * 0.5;   // 0.0 - 0.5
    float thickness_f  = float(thickness)  / 100.0 * 0.05;  // 0.0 - 0.05
    float glow_f       = float(glow)       / 100.0 * 0.05;  // 0.0 - 0.05
    float bg_dim_f     = float(bg_dim)     / 100.0;          // 0.0 - 1.0
    float bar_height_f = float(bar_height) / 100.0 * 0.5;   // 0.0 - 0.5
    float freq_min_f   = float(freq_min)   / 100.0;          // 0.0 - 1.0
    float freq_max_f   = float(freq_max)   / 100.0;          // 0.0 - 1.0

    // Map uv.x to the configured frequency range
    float freq_uv = lerp(freq_min_f, freq_max_f, uv.x);

    // Sample FFT amplitude at this horizontal frequency position
    float fft_amplitude = builtin_texture_fft_main.Sample(builtin_texture_sampler, float2(freq_uv, 0.5)).r;

    // Remap from [0,1] to [-1,1] so the line oscillates above and below center
    // FFT bins near 0 are quiet → line stays flat; louder → line deflects
    float wave_signal = (fft_amplitude - 0.5) * 2.0;

    // Compute the Y position of the waveform line at this X
    float wave_y = center_y_f + wave_signal * amplitude_f;

    // Distance from current pixel to the waveform line
    float dist = abs(uv.y - wave_y);

    // Hard line mask
    float line_mask = step(dist, thickness_f);

    // Soft glow mask (additive halo around the line)
    float glow_mask = 0.0;
    if (glow_f > 0.0)
    {
        glow_mask = smoothstep(thickness_f + glow_f, thickness_f, dist) * 0.5;
    }

    float wave_mask = saturate(line_mask + glow_mask);

    // Optional background bar behind the waveform
    float4 result = video;
    if (bar_height_f > 0.0)
    {
        float bar_top    = center_y_f - bar_height_f;
        float bar_bottom = center_y_f + bar_height_f;
        float in_bar = step(bar_top, uv.y) * step(uv.y, bar_bottom);
        result.rgb = lerp(result.rgb, result.rgb * (1.0 - bg_dim_f), in_bar);
    }

    // Blend waveform color onto video
    result.rgb = lerp(result.rgb, wave_color.rgb, wave_color.a * wave_mask);

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, result.rgb, float(enabled)), 1.0);
}
