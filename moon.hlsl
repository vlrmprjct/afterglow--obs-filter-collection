// -----------------------------------------------
// AfterGlow — Moon Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Flat matte monochrome — desaturated, slightly
// lifted blacks, reduced contrast. Classic "Moon"
// filter look from photo apps.
// -----------------------------------------------

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set fade__description Matte Fade (lift blacks)
#pragma shaderfilter set fade__default 45
#pragma shaderfilter set fade__min 0
#pragma shaderfilter set fade__max 100
uniform int fade;

#pragma shaderfilter set contrast__description Contrast
#pragma shaderfilter set contrast__default 28
#pragma shaderfilter set contrast__min 0
#pragma shaderfilter set contrast__max 100
uniform int contrast;

#pragma shaderfilter set brightness__description Brightness
#pragma shaderfilter set brightness__default 50
#pragma shaderfilter set brightness__min 0
#pragma shaderfilter set brightness__max 100
uniform int brightness;

#pragma shaderfilter set tint__description Cold/Warm Tint (-100=cold blue 100=warm amber)
#pragma shaderfilter set tint__default 0
#pragma shaderfilter set tint__min -100
#pragma shaderfilter set tint__max 100
uniform int tint;

#pragma shaderfilter set mix__description Mix with Original
#pragma shaderfilter set mix__default 0
#pragma shaderfilter set mix__min 0
#pragma shaderfilter set mix__max 100
uniform int mix;

#pragma shaderfilter set glow__description Glow / Bloom on Highlights
#pragma shaderfilter set glow__default 35
#pragma shaderfilter set glow__min 0
#pragma shaderfilter set glow__max 100
uniform int glow;

float4 render(float2 uv) {
    float3 src = image.Sample(builtin_texture_sampler, uv).rgb;

    // Desaturate to luminance
    float luma = dot(src, float3(0.299, 0.587, 0.114));
    float3 col = float3(luma, luma, luma);

    // Brightness offset (center at 50 = neutral)
    float br = (float(brightness) - 50.0) / 100.0 * 0.4;
    col += br;

    // Contrast: pull toward / away from midgray
    float ct = 1.0 + (float(contrast) - 50.0) / 100.0 * 1.6;
    col = (col - 0.5) * ct + 0.5;

    // Fade: lift blacks (matte finish)
    float fadeAmt = float(fade) / 100.0 * 0.32;
    col = col * (1.0 - fadeAmt) + fadeAmt;

    // Cold/warm tint on midtones
    float tintAmt = float(tint) / 100.0;
    float3 coldShift = float3(-0.04, -0.01, 0.08);   // blue-gray
    float3 warmShift = float3( 0.06,  0.02, -0.04);  // amber-gray
    float3 tintColor = tintAmt > 0.0
        ? lerp(float3(0,0,0), warmShift, tintAmt)
        : lerp(float3(0,0,0), coldShift, -tintAmt);
    col += tintColor * luma * (1.0 - luma) * 4.0;  // apply to midtones only

    // Optional blend with original
    col = lerp(col, src, float(mix) / 100.0);

    // Glow: sample a blurred version by averaging neighbors and add to highlights
    float glowAmt = float(glow) / 100.0;
    float3 blur = float3(0, 0, 0);
    float r = glowAmt * 0.03;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2( r,  0))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2(-r,  0))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2( 0,  r))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2( 0, -r))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2( r,  r))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2(-r,  r))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2( r, -r))).rgb;
    blur += image.Sample(builtin_texture_sampler, saturate(uv + float2(-r, -r))).rgb;
    blur /= 8.0;
    float blurLuma = dot(blur, float3(0.299, 0.587, 0.114));
    // Only add glow to bright areas
    float highlight = smoothstep(0.55, 1.0, blurLuma);
    col += float3(blurLuma, blurLuma, blurLuma) * highlight * glowAmt * 0.5;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
