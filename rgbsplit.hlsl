// -----------------------------------------------
// AfterGlow — RGB Chromatic Aberration Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Splits the red and blue color channels
// horizontally for a chromatic aberration look
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// Split amount (0 = off, 100 = maximum)
#pragma shaderfilter set rgb_split__description RGB Split Amount (0-100)
#pragma shaderfilter set rgb_split__default 12
#pragma shaderfilter set rgb_split__min 0
#pragma shaderfilter set rgb_split__max 100
uniform int rgb_split;

// Animate the split direction over time
#pragma shaderfilter set animate__description Animate Direction
#pragma shaderfilter set animate__default 1
#pragma shaderfilter set animate__min 0
#pragma shaderfilter set animate__max 1
uniform int animate;

// Animation speed (1 = slow, 100 = fast)
#pragma shaderfilter set anim_speed__description Animation Speed (0-100)
#pragma shaderfilter set anim_speed__default 30
#pragma shaderfilter set anim_speed__min 1
#pragma shaderfilter set anim_speed__max 100
uniform int anim_speed;

// -----------------------------------------------
// Hash helper
// -----------------------------------------------

float hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

// -----------------------------------------------
// Main render
// -----------------------------------------------

float4 render(float2 uv)
{
    float splitAmt = float(rgb_split) / 100.0 * 0.05;

    // Direction: static (+1) or animated (alternates with time)
    float splitDir = 1.0;
    if (animate != 0)
    {
        float speed = float(anim_speed) / 100.0 * 10.0;
        splitDir = sign(hash11(floor(builtin_elapsed_time * speed)) - 0.5);
    }

    float uvR_x = frac(uv.x + splitAmt * splitDir);
    float uvB_x = frac(uv.x - splitAmt * splitDir);

    float r = image.Sample(builtin_texture_sampler, float2(uvR_x, uv.y)).r;
    float g = image.Sample(builtin_texture_sampler, uv).g;
    float b = image.Sample(builtin_texture_sampler, float2(uvB_x, uv.y)).b;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, float3(r, g, b), float(enabled)), 1.0);
}
