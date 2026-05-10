// -----------------------------------------------
// AfterGlow — VHS-Look Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Effects: chroma bleed, scanlines, noise,
//          tape wobble, washed colors
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set chroma_bleed__description Chroma Bleed
#pragma shaderfilter set chroma_bleed__default 40
#pragma shaderfilter set chroma_bleed__min 0
#pragma shaderfilter set chroma_bleed__max 100
uniform int chroma_bleed;

#pragma shaderfilter set scanlines__description Scanline Intensity
#pragma shaderfilter set scanlines__default 30
#pragma shaderfilter set scanlines__min 0
#pragma shaderfilter set scanlines__max 100
uniform int scanlines;

#pragma shaderfilter set noise__description Tape Noise
#pragma shaderfilter set noise__default 25
#pragma shaderfilter set noise__min 0
#pragma shaderfilter set noise__max 100
uniform int noise;

#pragma shaderfilter set wobble__description Tape Wobble (Horizontal Warp)
#pragma shaderfilter set wobble__default 20
#pragma shaderfilter set wobble__min 0
#pragma shaderfilter set wobble__max 100
uniform int wobble;

#pragma shaderfilter set washout__description Color Washout
#pragma shaderfilter set washout__default 35
#pragma shaderfilter set washout__min 0
#pragma shaderfilter set washout__max 100
uniform int washout;

#pragma shaderfilter set head_switch__description Head Switch Artifact (bottom)
#pragma shaderfilter set head_switch__default 20
#pragma shaderfilter set head_switch__min 0
#pragma shaderfilter set head_switch__max 100
uniform int head_switch;

// --- helpers ---
float hash(float2 p) {
    return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453);
}

float4 render(float2 uv) {
    float t = builtin_elapsed_time;
    float2 origUV = uv; // save before any distortion

    // --- tape wobble ---
    float wob = float(wobble) / 100.0 * 0.012;
    float wobFreq = 8.0;
    float wobSpeed = 3.0;
    uv.x += wob * sin(uv.y * wobFreq + t * wobSpeed);
    // stronger wobble near bottom (head-switch zone)
    float hs = float(head_switch) / 100.0;
    float hsZone = smoothstep(0.88, 1.0, uv.y);
    uv.x += hs * 0.04 * sin(uv.y * 80.0 + t * 20.0) * hsZone;

    // --- chroma bleed: sample R/G/B with horizontal offset ---
    float bleed = float(chroma_bleed) / 100.0 * 0.018;
    float r = image.Sample(builtin_texture_sampler, uv + float2(-bleed * 1.5, 0)).r;
    float g = image.Sample(builtin_texture_sampler, uv + float2(-bleed * 0.5, 0)).g;
    float b = image.Sample(builtin_texture_sampler, uv + float2( bleed,       0)).b;
    float4 col = float4(r, g, b, 1.0);

    // additional horizontal smear for chroma (accumulate neighbors)
    float smear = bleed * 3.0;
    int steps = 6;
    float4 blurred = col;
    for (int i = 1; i <= steps; i++) {
        float off = smear * float(i) / float(steps);
        blurred += image.Sample(builtin_texture_sampler, uv - float2(off, 0));
    }
    col = lerp(col, blurred / float(steps + 1), float(chroma_bleed) / 100.0 * 0.8);

    // --- washout: lift blacks, desaturate slightly ---
    float wo = float(washout) / 100.0;
    float luma = dot(col.rgb, float3(0.299, 0.587, 0.114));
    col.rgb = lerp(col.rgb, float3(luma, luma, luma) * 0.5 + 0.5, wo * 0.4);
    col.rgb += wo * 0.08; // lift blacks

    // --- scanlines ---
    float sl = float(scanlines) / 100.0;
    float scanline = sin(uv.y * 240.0 * 3.14159) * 0.5 + 0.5;
    col.rgb *= 1.0 - sl * 0.35 * (1.0 - scanline);

    // --- tape noise ---
    float ns = float(noise) / 100.0;
    float2 noiseUV = float2(uv.x + frac(t * 1.3), uv.y + frac(t * 0.7));
    float n = hash(floor(noiseUV * float2(320.0, 240.0)));
    col.rgb += (n - 0.5) * ns * 0.25;

    // random horizontal noise bands
    float bandNoise = hash(float2(floor(uv.y * 60.0 + t * 8.0), t));
    col.rgb += (bandNoise - 0.5) * ns * 0.15 * step(0.92, bandNoise);

    col.rgb = saturate(col.rgb);

    float3 _orig = image.Sample(builtin_texture_sampler, origUV).rgb;
    col.rgb = lerp(_orig, col.rgb, float(enabled));
    return col;
}
