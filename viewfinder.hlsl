// -----------------------------------------------
// AfterGlow — Camcorder Viewfinder HUD Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Simulates looking through an old camcorder eyepiece:
// corner brackets, REC indicator, battery meter,
// exposure scale, running timecode, center reticle
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// --- HUD color (white by default, change for amber/green tint) ---
#pragma shaderfilter set hud_color__description HUD Color
#pragma shaderfilter set hud_color__default FFAA00FF
uniform float4 hud_color;

// --- HUD opacity ---
#pragma shaderfilter set hud_opacity__description HUD Opacity
#pragma shaderfilter set hud_opacity__default 50
#pragma shaderfilter set hud_opacity__min 0
#pragma shaderfilter set hud_opacity__max 100
uniform int hud_opacity;

// --- Glow / bloom on HUD elements ---
#pragma shaderfilter set glow_amount__description HUD Glow Intensity
#pragma shaderfilter set glow_amount__default 50
#pragma shaderfilter set glow_amount__min 0
#pragma shaderfilter set glow_amount__max 100
uniform int glow_amount;

// --- Viewfinder oval vignette ---
#pragma shaderfilter set vignette__description Viewfinder Vignette
#pragma shaderfilter set vignette__default 60
#pragma shaderfilter set vignette__min 0
#pragma shaderfilter set vignette__max 100
uniform int vignette;

// --- Scanlines ---
#pragma shaderfilter set scanlines__description Scanline Intensity
#pragma shaderfilter set scanlines__default 15
#pragma shaderfilter set scanlines__min 0
#pragma shaderfilter set scanlines__max 100
uniform int scanlines;

// --- REC indicator blink speed ---
#pragma shaderfilter set blink_speed__description REC Blink Speed
#pragma shaderfilter set blink_speed__default 50
#pragma shaderfilter set blink_speed__min 1
#pragma shaderfilter set blink_speed__max 100
uniform int blink_speed;

// --- Battery level ---
#pragma shaderfilter set battery__description Battery Level (0-100)
#pragma shaderfilter set battery__default 75
#pragma shaderfilter set battery__min 0
#pragma shaderfilter set battery__max 100
uniform int battery;

// --- Exposure / gain level indicator (right scale) ---
#pragma shaderfilter set exposure__description Exposure Level Indicator
#pragma shaderfilter set exposure__default 55
#pragma shaderfilter set exposure__min 0
#pragma shaderfilter set exposure__max 100
uniform int exposure;

// --- Center reticle ---
#pragma shaderfilter set reticle__description Show Center Reticle
#pragma shaderfilter set reticle__default 1
#pragma shaderfilter set reticle__min 0
#pragma shaderfilter set reticle__max 1
uniform int reticle;

// -----------------------------------------------
// Helpers
// -----------------------------------------------

float inRect(float2 uv, float x, float y, float w, float h) {
    return float(uv.x >= x && uv.x <= x + w && uv.y >= y && uv.y <= y + h);
}

// Soft glowing rectangle: returns > 0 near the rect
float glowRect(float2 uv, float x, float y, float w, float h, float gw) {
    float2 c = float2(x + w * 0.5, y + h * 0.5);
    float dx = max(abs(uv.x - c.x) - w * 0.5, 0.0);
    float dy = max(abs(uv.y - c.y) - h * 0.5, 0.0);
    float d = sqrt(dx * dx + dy * dy);
    return exp(-d / max(gw, 0.0001));
}

// Aspect-corrected circle (16:9)
float glowCircle(float2 uv, float cx, float cy, float r, float gw) {
    float2 d = uv - float2(cx, cy);
    d.x *= 1.7778;
    float dist = length(d);
    return exp(-max(dist - r, 0.0) / max(gw, 0.0001));
}

float inCircle(float2 uv, float cx, float cy, float r) {
    float2 d = uv - float2(cx, cy);
    d.x *= 1.7778;
    return float(length(d) < r);
}

// -----------------------------------------------
// 7-segment display
// -----------------------------------------------

float seg(float2 uv, float2 p, float2 sz) {
    return inRect(uv, p.x, p.y, sz.x, sz.y);
}

float drawDigit(float2 uv, float2 pos, float ds, int d) {
    float sw = ds * 0.12;
    float sl = ds * 0.42;
    float w  = sl + sw;
    float h  = ds;

    // Segment positions
    float a = seg(uv, float2(pos.x + sw,         pos.y),                    float2(sl, sw));  // top
    float b = seg(uv, float2(pos.x + w - sw,      pos.y + sw),               float2(sw, sl));  // top-right
    float c = seg(uv, float2(pos.x + w - sw,      pos.y + h * 0.5 + sw * 0.5), float2(sw, sl)); // bot-right
    float dd = seg(uv, float2(pos.x + sw,          pos.y + h - sw),           float2(sl, sw));  // bottom
    float e = seg(uv, float2(pos.x,               pos.y + h * 0.5 + sw * 0.5), float2(sw, sl)); // bot-left
    float f = seg(uv, float2(pos.x,               pos.y + sw),               float2(sw, sl));  // top-left
    float g = seg(uv, float2(pos.x + sw,          pos.y + h * 0.5 - sw * 0.5), float2(sl, sw)); // mid

    if (d == 0) return saturate(a + b + c + dd + e + f);
    if (d == 1) return saturate(b + c);
    if (d == 2) return saturate(a + b + g + e + dd);
    if (d == 3) return saturate(a + b + g + c + dd);
    if (d == 4) return saturate(f + g + b + c);
    if (d == 5) return saturate(a + f + g + c + dd);
    if (d == 6) return saturate(a + f + g + e + c + dd);
    if (d == 7) return saturate(a + b + c);
    if (d == 8) return saturate(a + b + c + dd + e + f + g);
    if (d == 9) return saturate(a + b + c + dd + f + g);
    return 0.0;
}

float drawColon(float2 uv, float2 pos, float ds) {
    float sw = ds * 0.12;
    float dot = sw * 1.5;
    float r1 = inRect(uv, pos.x, pos.y + ds * 0.27, dot, dot);
    float r2 = inRect(uv, pos.x, pos.y + ds * 0.62, dot, dot);
    return saturate(r1 + r2);
}

// -----------------------------------------------
// Main render
// -----------------------------------------------

float4 render(float2 uv) {
    float t   = builtin_elapsed_time;
    float3 col = image.Sample(builtin_texture_sampler, uv).rgb;

    // --- Vignette ---
    float vigAmt = float(vignette) / 100.0;
    float2 vc = (uv - 0.5) * float2(1.7778, 1.0);
    float vig = 1.0 - smoothstep(0.38, 0.9, length(vc) * (0.55 + vigAmt * 0.55));
    col *= vig;

    // --- Scanlines ---
    float sl   = float(scanlines) / 100.0;
    float sval = sin(uv.y * 480.0 * 3.14159) * 0.5 + 0.5;
    col *= 1.0 - sl * 0.35 * (1.0 - sval);

    // ---- HUD accumulation buffers ----
    float gw      = float(glow_amount) / 100.0 * 0.007 + 0.001;
    float hudMask = 0.0;
    float glowMsk = 0.0;

    float mg = 0.040;   // margin from edge
    float bk = 0.070;   // bracket arm length
    float bt = 0.003;   // line thickness

    // --- Corner brackets ---
    // Top-left
    hudMask += inRect(uv, mg,           mg,           bk, bt);
    hudMask += inRect(uv, mg,           mg,           bt, bk);
    // Top-right
    hudMask += inRect(uv, 1.0-mg-bk,   mg,           bk, bt);
    hudMask += inRect(uv, 1.0-mg-bt,   mg,           bt, bk);
    // Bottom-left
    hudMask += inRect(uv, mg,           1.0-mg-bt,   bk, bt);
    hudMask += inRect(uv, mg,           1.0-mg-bk,   bt, bk);
    // Bottom-right
    hudMask += inRect(uv, 1.0-mg-bk,   1.0-mg-bt,   bk, bt);
    hudMask += inRect(uv, 1.0-mg-bt,   1.0-mg-bk,   bt, bk);

    // Bracket glow
    glowMsk += glowRect(uv, mg,         mg,         bk, bt, gw) * 0.5;
    glowMsk += glowRect(uv, mg,         mg,         bt, bk, gw) * 0.5;
    glowMsk += glowRect(uv, 1.0-mg-bk, mg,         bk, bt, gw) * 0.5;
    glowMsk += glowRect(uv, 1.0-mg-bt, mg,         bt, bk, gw) * 0.5;
    glowMsk += glowRect(uv, mg,         1.0-mg-bt, bk, bt, gw) * 0.5;
    glowMsk += glowRect(uv, mg,         1.0-mg-bk, bt, bk, gw) * 0.5;
    glowMsk += glowRect(uv, 1.0-mg-bk, 1.0-mg-bt, bk, bt, gw) * 0.5;
    glowMsk += glowRect(uv, 1.0-mg-bt, 1.0-mg-bk, bt, bk, gw) * 0.5;

    // --- REC indicator (top-left, next to bracket) ---
    float blinkSpeed = float(blink_speed) / 100.0 * 3.0 + 0.5;
    float blink = step(0.5, frac(t * blinkSpeed));

    float rdX  = mg + bk + 0.018;
    float rdY  = mg + 0.014;
    float rdR  = 0.011;

    float recDot  = inCircle(uv, rdX, rdY, rdR) * blink;
    float recGlow = glowCircle(uv, rdX, rdY, rdR, gw * 2.0) * blink;

    // Small "REC" label: three equal-height bars side by side
    float lbX = rdX + rdR * 1.6;
    float lbY = rdY - rdR * 0.7;
    float lbH = rdR * 1.4;
    float lbW = rdR * 0.5;
    float lbG = rdR * 0.28;
    float recLabel = 0.0;
    recLabel += inRect(uv, lbX,           lbY, lbW, lbH);
    recLabel += inRect(uv, lbX+lbW+lbG,  lbY, lbW, lbH);
    recLabel += inRect(uv, lbX+2.0*(lbW+lbG), lbY, lbW, lbH);
    recLabel *= blink;

    // --- Battery indicator (top-right) ---
    float batX = 1.0 - mg - bk - 0.065;
    float batY = mg + 0.012;
    float batW = 0.050;
    float batH = 0.020;
    float btt  = 0.0025;

    // Outline
    hudMask += inRect(uv, batX,           batY,           batW, btt);
    hudMask += inRect(uv, batX,           batY+batH-btt,  batW, btt);
    hudMask += inRect(uv, batX,           batY,           btt,  batH);
    hudMask += inRect(uv, batX+batW-btt,  batY,           btt,  batH);
    // Positive terminal nub
    hudMask += inRect(uv, batX+batW,      batY+batH*0.3, btt*2.0, batH*0.4);
    // Fill
    float fillW  = (batW - btt * 2.0) * saturate(float(battery) / 100.0);
    float batFill = inRect(uv, batX+btt, batY+btt, fillW, batH-btt*2.0);
    float batLow  = float(battery < 25);

    // --- Exposure scale (right side, vertical bar) ---
    float expX  = 1.0 - mg - 0.020;
    float expY  = 0.32;
    float expH  = 0.36;
    float expW  = btt;
    // Outline bar
    hudMask += inRect(uv, expX,           expY,           expW,   expH);
    // Fill marker
    float expFill = saturate(float(exposure) / 100.0);
    float mrkY = expY + expH * (1.0 - expFill) - btt;
    hudMask += inRect(uv, expX - 0.008,  mrkY,           0.008,  btt * 2.0); // tick mark left
    // Center zero mark
    float zeroY = expY + expH * 0.5 - btt * 0.5;
    hudMask += inRect(uv, expX - 0.005,  zeroY,          0.005,  btt);

    glowMsk += glowRect(uv, expX, expY, expW, expH, gw) * 0.3;
    glowMsk += glowRect(uv, expX - 0.008, mrkY, 0.008, btt * 2.0, gw) * 0.6;

    // --- Center reticle ---
    if (reticle > 0) {
        float rcX  = 0.5;
        float rcY  = 0.5;
        float arms = 0.028;
        float gap  = 0.009;

        hudMask += inRect(uv, rcX-arms-gap, rcY-bt*0.5,   arms, bt);  // left
        hudMask += inRect(uv, rcX+gap,      rcY-bt*0.5,   arms, bt);  // right
        hudMask += inRect(uv, rcX-bt*0.5,  rcY-arms-gap,  bt, arms);  // top
        hudMask += inRect(uv, rcX-bt*0.5,  rcY+gap,       bt, arms);  // bottom
        hudMask += inRect(uv, rcX-bt,      rcY-bt,        bt*2.0, bt*2.0); // center dot

        glowMsk += glowRect(uv, rcX-arms-gap, rcY-bt*0.5, arms, bt, gw) * 0.4;
        glowMsk += glowRect(uv, rcX+gap,      rcY-bt*0.5, arms, bt, gw) * 0.4;
        glowMsk += glowRect(uv, rcX-bt*0.5,  rcY-arms-gap, bt, arms, gw) * 0.4;
        glowMsk += glowRect(uv, rcX-bt*0.5,  rcY+gap,      bt, arms, gw) * 0.4;
    }

    // --- Timecode (bottom center, running from elapsed time) ---
    float ds       = 0.030;
    float dsp      = ds * 0.72;
    float colonW   = ds * 0.20;
    float tcTotalW = 6.0 * dsp + 2.0 * (colonW + 0.004);
    float tcX      = 0.5 - tcTotalW * 0.5;
    float tcY      = 1.0 - mg - bk * 0.5 - ds;

    int totalSec = int(t);
    int hrs  = (totalSec / 3600) % 24;
    int mins = (totalSec / 60) % 60;
    int secs = totalSec % 60;

    float cx = tcX;
    hudMask += drawDigit(uv, float2(cx, tcY), ds, hrs / 10);   cx += dsp;
    hudMask += drawDigit(uv, float2(cx, tcY), ds, hrs % 10);   cx += dsp;
    hudMask += drawColon(uv, float2(cx, tcY), ds);              cx += colonW + 0.004;
    hudMask += drawDigit(uv, float2(cx, tcY), ds, mins / 10);  cx += dsp;
    hudMask += drawDigit(uv, float2(cx, tcY), ds, mins % 10);  cx += dsp;
    hudMask += drawColon(uv, float2(cx, tcY), ds);              cx += colonW + 0.004;
    hudMask += drawDigit(uv, float2(cx, tcY), ds, secs / 10);  cx += dsp;
    hudMask += drawDigit(uv, float2(cx, tcY), ds, secs % 10);

    // -----------------------------------------------
    // Composite all layers
    // -----------------------------------------------
    float3 hudCol = hud_color.rgb;
    float  hudA   = hud_color.a * (float(hud_opacity) / 100.0);
    float  glowI  = float(glow_amount) / 100.0;

    hudMask = saturate(hudMask);
    glowMsk = saturate(glowMsk);

    // HUD elements in chosen color
    col = lerp(col, hudCol, hudMask * hudA);
    // Additive glow
    col += hudCol * glowMsk * glowI;

    // REC dot: always red
    float3 recRed = float3(1.0, 0.08, 0.04);
    col = lerp(col, recRed, recDot * hudA);
    col += recRed * recGlow * glowI * 0.6;
    // REC label bars in hud color
    col = lerp(col, hudCol, saturate(recLabel) * hudA);

    // Battery fill: green or red
    float3 batColor = lerp(float3(0.2, 1.0, 0.3), float3(1.0, 0.15, 0.1), batLow);
    col = lerp(col, batColor, batFill * hudA);

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, saturate(col), float(enabled)), 1.0);
}
