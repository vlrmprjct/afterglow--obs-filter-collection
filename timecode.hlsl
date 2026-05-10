// -----------------------------------------------
// AfterGlow — Timecode / Clock Overlay Shader for OBS Studio
// Requires: obs-shaderfilter plugin
// Displays time elapsed since filter load as
// HH:MM:SS using a 7-segment display overlay
// -----------------------------------------------

uniform float builtin_elapsed_time;

#pragma shaderfilter set enabled__description Enable Effect
#pragma shaderfilter set enabled__default 1
#pragma shaderfilter set enabled__min 0
#pragma shaderfilter set enabled__max 1
uniform int enabled;

// Digit color (RRGGBBAA)
#pragma shaderfilter set tc_color__description Digit Color
#pragma shaderfilter set tc_color__default FFFFFFFF
uniform float4 tc_color;

// Background box color (RRGGBBAA)
#pragma shaderfilter set bg_color__description Background Color
#pragma shaderfilter set bg_color__default 000000C0
uniform float4 bg_color;

// Top-left position (0 = left/top, 100 = right/bottom)
#pragma shaderfilter set pos_x__description Position X (0-100)
#pragma shaderfilter set pos_x__default 2
#pragma shaderfilter set pos_x__min 0
#pragma shaderfilter set pos_x__max 100
uniform int pos_x;

#pragma shaderfilter set pos_y__description Position Y (0-100)
#pragma shaderfilter set pos_y__default 2
#pragma shaderfilter set pos_y__min 0
#pragma shaderfilter set pos_y__max 100
uniform int pos_y;

// Digit height (1 = tiny, 100 = 30% of screen height)
#pragma shaderfilter set digit_height__description Digit Height (0-100)
#pragma shaderfilter set digit_height__default 23
#pragma shaderfilter set digit_height__min 1
#pragma shaderfilter set digit_height__max 100
uniform int digit_height;

// Padding around digits for the background box
#pragma shaderfilter set padding__description Background Padding (0-100)
#pragma shaderfilter set padding__default 16
#pragma shaderfilter set padding__min 0
#pragma shaderfilter set padding__max 100
uniform int padding;

// -----------------------------------------------
// 7-Segment rendering helpers
// Coordinate system: p in [0,1]x[0,1], y=0=bottom, y=1=top
// -----------------------------------------------

float inRect(float2 p, float x0, float x1, float y0, float y1)
{
    return step(x0, p.x) * step(p.x, x1)
         * step(y0, p.y) * step(p.y, y1);
}

//  Segment layout:
//   _        a = top bar
//  |_|       f = top-left,  b = top-right,  g = middle
//  |_|       e = bot-left,  c = bot-right,  d = bottom
//
//  Bit encoding: a=1 b=2 c=4 d=8 e=16 f=32 g=64
int digitMask(int d)
{
    if (d == 0) return 63;   // a b c d e f
    if (d == 1) return 6;    // b c
    if (d == 2) return 91;   // a b d e g
    if (d == 3) return 79;   // a b c d g
    if (d == 4) return 102;  // b c f g
    if (d == 5) return 109;  // a c d f g
    if (d == 6) return 125;  // a c d e f g
    if (d == 7) return 7;    // a b c
    if (d == 8) return 127;  // all
    return 111;              // 9: a b c d f g
}

float drawDigit(float2 p, int d)
{
    int mask = digitMask(d);
    float sw = 0.18;          // segment thickness
    float sg = 0.08;          // corner gap (gives diagonal-cut look)
    float r  = 0.0;

    if ((mask & 1)  != 0) r = max(r, inRect(p, sg,     1.0-sg,  1.0-sw,       1.0          )); // a top
    if ((mask & 2)  != 0) r = max(r, inRect(p, 1.0-sw, 1.0,     0.5+sg,       1.0-sg       )); // b top-right
    if ((mask & 4)  != 0) r = max(r, inRect(p, 1.0-sw, 1.0,     sg,           0.5-sg       )); // c bot-right
    if ((mask & 8)  != 0) r = max(r, inRect(p, sg,     1.0-sg,  0.0,          sw           )); // d bottom
    if ((mask & 16) != 0) r = max(r, inRect(p, 0.0,    sw,      sg,           0.5-sg       )); // e bot-left
    if ((mask & 32) != 0) r = max(r, inRect(p, 0.0,    sw,      0.5+sg,       1.0-sg       )); // f top-left
    if ((mask & 64) != 0) r = max(r, inRect(p, sg,     1.0-sg,  0.5-sw*0.5,   0.5+sw*0.5  )); // g middle

    return r;
}

// Two square dots at 1/3 and 2/3 height
float drawColon(float2 p)
{
    float r  = 0.18;
    float cx = 0.5;
    float m  = 0.0;
    m = max(m, inRect(p, cx-r, cx+r, 0.62, 0.62 + r * 2.0));
    m = max(m, inRect(p, cx-r, cx+r, 0.22, 0.22 + r * 2.0));
    return m;
}

// -----------------------------------------------
// Main render
// -----------------------------------------------

float4 render(float2 uv)
{
    float4 video = image.Sample(builtin_texture_sampler, uv);

    // Scale parameters from 0-100 to internal UV values
    float pos_x_f        = float(pos_x)        / 100.0;         // 0.0 - 1.0
    float pos_y_f        = float(pos_y)        / 100.0;         // 0.0 - 1.0
    float digit_height_f = float(digit_height) / 100.0 * 0.30; // 0.0 - 0.30
    float padding_f      = float(padding)      / 100.0 * 0.05; // 0.0 - 0.05

    // --- Compute HH:MM:SS ---
    float t     = builtin_elapsed_time;
    int hours   = min(int(floor(t / 3600.0)), 99);
    int minutes = int(floor(fmod(t, 3600.0) / 60.0));
    int seconds = int(floor(fmod(t, 60.0)));

    int H1 = hours   / 10;        int H2 = hours   - H1 * 10;
    int M1 = minutes / 10;        int M2 = minutes - M1 * 10;
    int S1 = seconds / 10;        int S2 = seconds - S1 * 10;

    // --- Layout (in units of digit_height) ---
    float dw  = 0.55;   // digit width
    float gap = 0.05;   // gap between characters
    float cw  = 0.30;   // colon width

    float xH1 = 0.0;
    float xH2 = xH1 + dw + gap;         // 0.60
    float xC1 = xH2 + dw + gap;         // 1.20
    float xM1 = xC1 + cw + gap;         // 1.55
    float xM2 = xM1 + dw + gap;         // 2.15
    float xC2 = xM2 + dw + gap;         // 2.75
    float xS1 = xC2 + cw + gap;         // 3.10
    float xS2 = xS1 + dw + gap;         // 3.70
    float totalW = xS2 + dw;            // 4.25

    float dh    = digit_height_f;
    float dispW = totalW * dh;

    // --- Background box ---
    float inBox = step(pos_x_f - padding_f, uv.x) * step(uv.x, pos_x_f + dispW + padding_f)
                * step(pos_y_f - padding_f, uv.y) * step(uv.y, pos_y_f + dh   + padding_f);

    float4 result = lerp(video, float4(bg_color.rgb, 1.0), bg_color.a * inBox);

    // --- Local coordinates within the display ---
    // lx: 0 at left edge, totalW at right edge
    // ly: 1 at top, 0 at bottom  (for 7-seg drawing)
    float lx = (uv.x - pos_x_f) / dh;
    float ly = 1.0 - (uv.y - pos_y_f) / dh;

    // --- Draw all characters ---
    // Out-of-range pixels naturally return 0 via inRect bounds checks
    float seg = 0.0;

    seg = max(seg, drawDigit(float2((lx - xH1) / dw, ly), H1));
    seg = max(seg, drawDigit(float2((lx - xH2) / dw, ly), H2));
    seg = max(seg, drawColon(float2((lx - xC1) / cw, ly)));
    seg = max(seg, drawDigit(float2((lx - xM1) / dw, ly), M1));
    seg = max(seg, drawDigit(float2((lx - xM2) / dw, ly), M2));
    seg = max(seg, drawColon(float2((lx - xC2) / cw, ly)));
    seg = max(seg, drawDigit(float2((lx - xS1) / dw, ly), S1));
    seg = max(seg, drawDigit(float2((lx - xS2) / dw, ly), S2));

    result.rgb = lerp(result.rgb, tc_color.rgb, tc_color.a * seg);

    float3 _orig = image.Sample(builtin_texture_sampler, uv).rgb;
    return float4(lerp(_orig, result.rgb, float(enabled)), 1.0);
}
