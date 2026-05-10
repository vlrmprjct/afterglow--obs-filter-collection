// -----------------------------------------------
// AfterGlow — CRT Monitor Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates a CRT monitor: scanlines, screen
// curvature darkening, amber phosphor tint
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// Scanline intensity
#pragma shaderfilter set intensity__description Scanline Intensity (0-100)
#pragma shaderfilter set intensity__default 15
#pragma shaderfilter set intensity__min 0
#pragma shaderfilter set intensity__max 100
uniform int intensity;

// Screen curvature
#pragma shaderfilter set curvature__description CRT Curvature (0-100)
#pragma shaderfilter set curvature__default 30
#pragma shaderfilter set curvature__min 0
#pragma shaderfilter set curvature__max 100
uniform int curvature;

// Amber strength
#pragma shaderfilter set amber__description Amber CRT Strength (0-100)
#pragma shaderfilter set amber__default 60
#pragma shaderfilter set amber__min 0
#pragma shaderfilter set amber__max 100
uniform int amber;

float4 render(float2 uv)
{
    float2 origUV = uv; // save before curvature distortion

    // Scale parameters from 0-100 to internal values
    float intensity_f  = float(intensity)  / 100.0;          // 0.0 - 1.0
    float curvature_f  = float(curvature)  / 100.0 * 0.1;   // 0.0 - 0.1
    float amber_f      = float(amber)      / 100.0;          // 0.0 - 1.0

    // CRT curvature
    float2 centered = uv * 2.0 - 1.0;
    centered *= 1.0 + curvature_f * dot(centered, centered);
    uv = centered * 0.5 + 0.5;

    // Outside screen -> black
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0)
    {
        return float4(0.0, 0.0, 0.0, 1.0);
    }

    float4 color = image.Sample(builtin_texture_sampler, uv);

    // Scanlines
    float scanline = sin(uv.y * 1080.0 * 3.14159);
    color.rgb -= scanline * intensity_f;

    // Vignette
    float vignette = 1.0 - dot(centered * 0.35, centered * 0.35);
    color.rgb *= vignette;

    // -----------------------------
    // 🟠 AMBER CRT LOOK
    // -----------------------------

    // Reduce blue heavily, green slightly
    float3 amberTint = float3(1.0, 0.75, 0.35);

    color.rgb = lerp(color.rgb, color.rgb * amberTint, amber_f);

    // phosphor glow (very subtle bloom feel)
    float brightness = dot(color.rgb, float3(0.3, 0.59, 0.11));
    color.rgb += brightness * brightness * 0.15 * amber_f;

    float3 _orig = image.Sample(builtin_texture_sampler, origUV).rgb;
    color.rgb = lerp(_orig, saturate(color.rgb), float(enabled));
    return color;
}

