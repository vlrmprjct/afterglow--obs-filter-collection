// -----------------------------------------------
// AfterGlow — Film Burn Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates old damaged film: edge burn/charring,
// overexposed flares, light leaks, chemical blotches
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

#pragma shaderfilter set edge_burn__description Edge Burn / Charring
#pragma shaderfilter set edge_burn__default 65
#pragma shaderfilter set edge_burn__min 0
#pragma shaderfilter set edge_burn__max 100
uniform int edge_burn;

#pragma shaderfilter set flare__description Overexposure Flares
#pragma shaderfilter set flare__default 45
#pragma shaderfilter set flare__min 0
#pragma shaderfilter set flare__max 100
uniform int flare;

#pragma shaderfilter set light_leak__description Light Leak (colored edge bleed)
#pragma shaderfilter set light_leak__default 40
#pragma shaderfilter set light_leak__min 0
#pragma shaderfilter set light_leak__max 100
uniform int light_leak;

#pragma shaderfilter set blotch__description Chemical Blotches
#pragma shaderfilter set blotch__default 30
#pragma shaderfilter set blotch__min 0
#pragma shaderfilter set blotch__max 100
uniform int blotch;

#pragma shaderfilter set speed__description Animation Speed
#pragma shaderfilter set speed__default 20
#pragma shaderfilter set speed__min 0
#pragma shaderfilter set speed__max 100
uniform int speed;

#pragma shaderfilter set grain__description Film Grain
#pragma shaderfilter set grain__default 30
#pragma shaderfilter set grain__min 0
#pragma shaderfilter set grain__max 100
uniform int grain;

float hash11(float p)        { return frac(sin(p * 127.1) * 43758.5453); }
float hash21(float2 p)       { return frac(sin(dot(p, float2(127.1, 311.7))) * 43758.5453); }

// Smooth noise by interpolating hash values
float noise21(float2 p) {
    float2 i = floor(p);
    float2 f = frac(p);
    f = f * f * (3.0 - 2.0 * f);
    return lerp(
        lerp(hash21(i + float2(0,0)), hash21(i + float2(1,0)), f.x),
        lerp(hash21(i + float2(0,1)), hash21(i + float2(1,1)), f.x),
        f.y);
}

float4 render(float2 uv) {
    float t    = builtin_elapsed_time;
    float spd  = float(speed) / 100.0 * 2.0 + 0.1;
    float3 col = image.Sample(builtin_texture_sampler, uv).rgb;

    // --- Edge burn: dark charred border, irregular ---
    float burnAmt = float(edge_burn) / 100.0;
    float2 ec = (uv - 0.5) * float2(1.7778, 1.0);
    float edgeDist = length(ec);
    // Irregular edge via noise
    float edgeNoise = noise21(uv * 4.0 + float2(t * 0.1, 0.0)) * 0.15;
    float burn = smoothstep(0.35 + edgeNoise, 0.65 + edgeNoise, edgeDist);
    burn *= burnAmt;
    // Charred color: deep brown/black
    float3 charColor = float3(0.08, 0.03, 0.01);
    col = lerp(col, charColor, burn);

    // --- Overexposure flares: bright white/yellow blobs ---
    float flareAmt = float(flare) / 100.0;
    float flare1 = noise21(uv * 2.5 + float2(t * spd * 0.3, 0.7));
    float flare2 = noise21(uv * 3.5 - float2(0.3, t * spd * 0.2));
    float flareMask = pow(max(flare1 * flare2, 0.0), 3.0) * flareAmt * 3.0;
    float3 flareColor = lerp(float3(1.0, 0.95, 0.7), float3(1.0, 1.0, 1.0), flareMask);
    col = lerp(col, flareColor, saturate(flareMask));

    // --- Light leak: warm red/orange bleed from one edge ---
    float leakAmt = float(light_leak) / 100.0;
    float leak = noise21(float2(uv.y * 1.5 + t * spd * 0.15, 0.5)) * (1.0 - uv.x);
    leak = pow(saturate(leak), 1.5) * leakAmt;
    float3 leakColor = float3(1.0, 0.35, 0.05);
    col += leakColor * leak * 0.7;

    // Add secondary cool leak from opposite edge
    float leak2 = noise21(float2(uv.y * 2.0 - t * spd * 0.1, 1.3)) * uv.x;
    leak2 = pow(saturate(leak2), 2.0) * leakAmt * 0.4;
    col += float3(0.1, 0.2, 0.6) * leak2;

    // --- Chemical blotches: semi-transparent dark/discolored spots ---
    float blotchAmt = float(blotch) / 100.0;
    float2 bUV = uv * 5.0 + float2(t * spd * 0.05, 0.0);
    float b1 = noise21(bUV);
    float b2 = noise21(bUV * 1.7 + float2(3.1, 1.4));
    float blotchMask = pow(b1 * b2, 2.0) * blotchAmt * 6.0;
    float3 blotchColor = lerp(float3(0.6, 0.45, 0.2), float3(0.1, 0.05, 0.02),
                              hash21(floor(bUV)));
    col = lerp(col, blotchColor, saturate(blotchMask) * 0.6);

    // --- Film grain ---
    float ns = float(grain) / 100.0;
    float2 noiseUV = floor(uv * float2(1920.0, 1080.0) + frac(t * float2(2.1, 1.3)) * 400.0);
    float n = hash21(noiseUV);
    col += (n - 0.5) * ns * 0.14;

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
