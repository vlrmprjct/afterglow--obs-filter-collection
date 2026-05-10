// -----------------------------------------------
// AfterGlow — Glitch / Datamosh Overlay Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Effects: RGB split, scanline jitter, block shift,
//          digital noise, signal dropout
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// --- Global intensity (master control) ---
#pragma shaderfilter set intensity__description Glitch Intensity (1-100)
#pragma shaderfilter set intensity__default 50
#pragma shaderfilter set intensity__min 0
#pragma shaderfilter set intensity__max 100
uniform int intensity;

// --- RGB Chromatic Aberration ---
#pragma shaderfilter set rgb_split__description RGB Split Amount (1-100)
#pragma shaderfilter set rgb_split__default 12
#pragma shaderfilter set rgb_split__min 0
#pragma shaderfilter set rgb_split__max 100
uniform int rgb_split;

// --- Scanline Jitter ---
#pragma shaderfilter set jitter_strength__description Scanline Jitter Strength (1-100)
#pragma shaderfilter set jitter_strength__default 15
#pragma shaderfilter set jitter_strength__min 0
#pragma shaderfilter set jitter_strength__max 100
uniform int jitter_strength;

#pragma shaderfilter set jitter_speed__description Jitter Speed (1-100)
#pragma shaderfilter set jitter_speed__default 20
#pragma shaderfilter set jitter_speed__min 1
#pragma shaderfilter set jitter_speed__max 100
uniform int jitter_speed;

// --- Block Displacement ---
#pragma shaderfilter set block_size__description Block Size (1-100)
#pragma shaderfilter set block_size__default 17
#pragma shaderfilter set block_size__min 1
#pragma shaderfilter set block_size__max 100
uniform int block_size;

#pragma shaderfilter set block_strength__description Block Shift Strength (1-100)
#pragma shaderfilter set block_strength__default 15
#pragma shaderfilter set block_strength__min 0
#pragma shaderfilter set block_strength__max 100
uniform int block_strength;

// --- Digital Noise ---
#pragma shaderfilter set noise_amount__description Digital Noise Amount (1-100)
#pragma shaderfilter set noise_amount__default 6
#pragma shaderfilter set noise_amount__min 0
#pragma shaderfilter set noise_amount__max 100
uniform int noise_amount;

// --- Signal Dropout (horizontal black bars) ---
#pragma shaderfilter set dropout_chance__description Dropout Chance (1-100)
#pragma shaderfilter set dropout_chance__default 8
#pragma shaderfilter set dropout_chance__min 0
#pragma shaderfilter set dropout_chance__max 100
uniform int dropout_chance;

// -----------------------------------------------
// Hash / noise helpers
// -----------------------------------------------

float hash11(float p)
{
    p = frac(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return frac(p);
}

float hash12(float2 p)
{
    float3 p3 = frac(float3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return frac((p3.x + p3.y) * p3.z);
}

// Returns a value that changes only a few times per second
// to give "frozen block" feel instead of per-frame jitter
float slowHash(float seed, float rate)
{
    return hash11(floor(builtin_elapsed_time * rate) + seed);
}

// -----------------------------------------------
// Main render
// -----------------------------------------------

float4 render(float2 uv)
{
    float t = builtin_elapsed_time;

    // Scale all parameters from 1-100 range to internal values
    float eff             = float(intensity)       / 100.0;
    float rgb_split_f     = float(rgb_split)       / 100.0 * 0.05;
    float jitter_str_f    = float(jitter_strength) / 100.0 * 0.1;
    float jitter_speed_f  = float(jitter_speed)    / 100.0 * 40.0;
    float block_size_f    = max(float(block_size)  / 100.0 * 0.3, 0.001);
    float block_str_f     = float(block_strength)  / 100.0 * 0.2;
    float noise_f         = float(noise_amount)    / 100.0;
    float dropout_f       = float(dropout_chance)  / 100.0 * 0.5;

    // ---- 1. Block displacement ----------------------------------------
    // Divide screen into coarse rows; each row may shift horizontally
    float rowID   = floor(uv.y / block_size_f);
    float blockRnd = hash11(rowID + floor(t * 6.0) * 37.3);

    // Only shift rows that pass a threshold (sparse glitch)
    float blockShift = 0.0;
    if (blockRnd > (1.0 - eff * 0.6))
    {
        blockShift = (blockRnd - 0.5) * 2.0 * block_str_f * eff;
    }

    float2 uvShifted = float2(frac(uv.x + blockShift), uv.y);

    // ---- 2. Scanline jitter -------------------------------------------
    // Fine-grained per-line horizontal wobble
    float lineID  = floor(uv.y * 1080.0);
    float jitter  = (hash11(lineID + floor(t * jitter_speed_f) * 13.7) - 0.5)
                    * jitter_str_f * eff;

    // Jitter only fires on some lines
    float jitterProb = hash11(lineID * 0.3 + floor(t * 4.0));
    if (jitterProb < 0.85) jitter = 0.0;

    uvShifted.x = frac(uvShifted.x + jitter);

    // ---- 3. RGB chromatic split ---------------------------------------
    float splitAmt = rgb_split_f * eff;
    // Vary split direction per glitch burst
    float splitDir = sign(hash11(floor(t * 3.0)) - 0.5);

    float uvR_x = frac(uvShifted.x + splitAmt * splitDir);
    float uvB_x = frac(uvShifted.x - splitAmt * splitDir);

    float r = image.Sample(builtin_texture_sampler, float2(uvR_x,      uvShifted.y)).r;
    float g = image.Sample(builtin_texture_sampler,           uvShifted               ).g;
    float b = image.Sample(builtin_texture_sampler, float2(uvB_x,      uvShifted.y)).b;

    float4 col = float4(r, g, b, 1.0);

    // ---- 4. Digital noise --------------------------------------------
    float noise = hash12(float2(uv.x, uv.y) + float2(t * 127.1, t * 311.7));
    float noiseMask = step(1.0 - noise_f * eff, noise);
    col.rgb = lerp(col.rgb, float3(noise, noise, noise), noiseMask);

    // ---- 5. Signal dropout -------------------------------------------
    // Full horizontal bars that go black/white
    float dropRowID  = floor(uv.y / (block_size_f * 0.3));
    float dropRnd    = hash11(dropRowID + floor(t * 12.0) * 51.9);
    float dropActive = step(1.0 - dropout_f * eff, dropRnd);
    float dropColor  = step(0.5, hash11(dropRowID * 3.7)); // black or white
    col.rgb = lerp(col.rgb, float3(dropColor, dropColor, dropColor), dropActive);

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    col.rgb = lerp(_orig, saturate(col.rgb), float(enabled));
    return col;
}
