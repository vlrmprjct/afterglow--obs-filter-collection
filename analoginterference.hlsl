// -----------------------------------------------
// AfterGlow — Analog Interference Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates bad TV/antenna reception:
// rolling bars, horizontal tearing, signal dropout,
// color bleeding, static noise
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set tear__description Horizontal Tearing / Sync Loss
#pragma shaderfilter set tear__default 40
#pragma shaderfilter set tear__min 0
#pragma shaderfilter set tear__max 100
uniform int tear;

#pragma shaderfilter set roll__description Rolling Bar Intensity
#pragma shaderfilter set roll__default 35
#pragma shaderfilter set roll__min 0
#pragma shaderfilter set roll__max 100
uniform int roll;

#pragma shaderfilter set roll_speed__description Rolling Bar Speed
#pragma shaderfilter set roll_speed__default 30
#pragma shaderfilter set roll_speed__min 1
#pragma shaderfilter set roll_speed__max 100
uniform int roll_speed;

#pragma shaderfilter set static_noise__description Static Noise Amount
#pragma shaderfilter set static_noise__default 20
#pragma shaderfilter set static_noise__min 0
#pragma shaderfilter set static_noise__max 100
uniform int static_noise;

#pragma shaderfilter set color_bleed__description Color Bleed
#pragma shaderfilter set color_bleed__default 25
#pragma shaderfilter set color_bleed__min 0
#pragma shaderfilter set color_bleed__max 100
uniform int color_bleed;

#pragma shaderfilter set dropout__description Signal Dropout (white flash)
#pragma shaderfilter set dropout__default 10
#pragma shaderfilter set dropout__min 0
#pragma shaderfilter set dropout__max 100
uniform int dropout;

float hash11(float p) { return frac(sin(p * 127.1) * 43758.5453); }
float hash21(float2 p) { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

float4 render(float2 uv) {
    float t = builtin_elapsed_time;

    // --- Horizontal tearing: random line shifts ---
    float tearAmt = float(tear) / 100.0 * 0.04;
    float lineY   = floor(uv.y * 1080.0);
    float tearOff = (hash11(lineY + floor(t * 8.0)) - 0.5)
                  * tearAmt
                  * step(0.85, hash11(lineY * 0.1 + floor(t * 3.0)));
    float2 sampUV = float2(uv.x + tearOff, uv.y);

    // --- Color bleed: separate channel offsets ---
    float bleed = float(color_bleed) / 100.0 * 0.025;
    float r = image.Sample(builtin_texture_sampler, saturate(sampUV + float2(-bleed, 0))).r;
    float g = image.Sample(builtin_texture_sampler, saturate(sampUV)).g;
    float b = image.Sample(builtin_texture_sampler, saturate(sampUV + float2( bleed, 0))).b;
    float3 col = float3(r, g, b);

    // --- Rolling interference bar ---
    float rollAmt   = float(roll) / 100.0;
    float rollSpeed = float(roll_speed) / 100.0 * 0.5;
    float barPos    = frac(t * rollSpeed);
    float barWidth  = 0.08 + rollAmt * 0.12;
    float barEdge   = smoothstep(0.0, 0.015, abs(frac(uv.y - barPos) - 0.5) - barWidth * 0.5 + 0.5);
    // Inside bar: shift + darken
    float inBar = 1.0 - barEdge;
    float barShift = inBar * rollAmt * 0.03 * sin(uv.y * 200.0 + t * 40.0);
    float3 barSrc = image.Sample(builtin_texture_sampler, saturate(float2(uv.x + barShift, uv.y))).rgb;
    col = lerp(col, barSrc * (1.0 - rollAmt * 0.6), inBar * rollAmt);

    // --- Static noise ---
    float ns = float(static_noise) / 100.0;
    float2 noiseUV = float2(uv.x + frac(t * 2.3), uv.y + frac(t * 1.7));
    float n = hash21(floor(noiseUV * float2(320.0, 240.0)));
    col += (n - 0.5) * ns * 0.35;

    // Occasional full static band
    float bandNoise = hash21(float2(floor(uv.y * 30.0 + t * 6.0), floor(t)));
    col = lerp(col, float3(n, n, n), ns * step(0.93, bandNoise) * 0.8);

    // --- Signal dropout: sudden white/noise flash ---
    float dropAmt = float(dropout) / 100.0;
    float dropNoise = hash11(floor(t * 4.0) * 13.7 + floor(uv.y * 5.0));
    float dropFlash = step(1.0 - dropAmt * 0.3, dropNoise);
    col = lerp(col, float3(n, n, n), dropFlash);

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
