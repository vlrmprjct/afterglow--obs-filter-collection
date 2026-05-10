# AfterGlow - OBS Shader Filter Collection

> A handcrafted collection of HLSL shader filters for OBS Studio - distortion, retro aesthetics, analog artifacts, audio visualization and cinematic looks, all controllable live via OBS or a WebSocket browser dashboard.

**Author:** Thomas Meschke / [vlrm.prjct](https://github.com/vlrm-prjct)
**License:** [CC BY-SA 4.0](LICENSE) - free to use, share and adapt with attribution

---

## Contents

- [Description](#description)
- [Short Demo](#short-demo)
- [Requirements](#requirements)
- [Usage in OBS](#usage-in-obs)
- [Filters](#filters)
  - [VHS](#vhs-vhshlsl)
  - [CRT](#crt-crthlsl)
  - [Glitch](#glitch-glitchhlsl)
  - [RGB Split](#rgb-split-rgb_splithlsl)
  - [Pixelate](#pixelate-pixelatehlsl)
  - [Interlace](#interlace-interlacehlsl)
  - [Analog Interference](#analog-interference-analog_interferencehlsl)
  - [Lens Distortion](#lens-distortion-lens_distortionhlsl)
  - [Night Vision](#night-vision-nightvisionhlsl)
  - [Viewfinder](#viewfinder-viewfinderhlsl)
  - [Timecode](#timecode-timecodehlsl)
  - [Waveform](#waveform-waveformhlsl)
  - [Spectrum Analyzer](#spectrum-analyzer-spectrumanalyzerhlsl)
  - [ASCII Art](#ascii-art-ascii_arthlsl)
  - [Dithering](#dithering-ditheringhlsl)
  - [CGA Palette](#cga-palette-cga_palettehlsl)
  - [Halftone](#halftone-halftonehlsl)
  - [Duotone](#duotone-duotonehlsl)
  - [Moon](#moon-moonhlsl)
  - [Lomo](#lomo-lomohlsl)
  - [Cross Process](#cross-process-cross_processhlsl)
  - [Film Burn](#film-burn-film_burnhlsl)
- [Tips](#tips)
- [Roadmap](#roadmap)
- [License](#license)

---

## Description

This collection provides 22 custom shader filters built for the [obs-shaderfilter-plus](https://github.com/Limeth/obs-shaderfilter-plus) plugin. Each filter exposes its parameters directly in OBS as integer sliders or color pickers - no scripting required. Filters are organized into four categories:

| Category | Filters |
|---|---|
| **Retro / Analog** | VHS, CRT, Interlace, Analog Interference, CGA Palette |
| **Optics / Lens** | RGB Split, Lens Distortion, Glitch, Pixelate |
| **Film / Darkroom** | Film Burn, Cross Process, Lomo, Duotone, Moon, Halftone, Dithering |
| **Overlay / HUD** | Viewfinder, Night Vision, Timecode, Waveform, Spectrum Analyzer, ASCII Art |

All filters include an **Enable Effect** toggle (0 = bypass, 1 = active) so you can switch them on and off without removing the filter from OBS.

→ [Watch the full settings and demo](docs/readme.md)

---

## Short Demo

→ [demo.mp4](docs/demo.mp4)

### Original Video

→ [original.mp4](docs/original.mp4)

Original Video from Ray.: https://www.pexels.com/de-de/video/stadt-strasse-verkehr-skyline-17701662/

---

## Requirements

- [OBS Studio](https://obsproject.com/) 28 or later
- [obs-shaderfilter-plus plugin](https://github.com/Limeth/obs-shaderfilter-plus) (install via OBS Tools → Script/Plugin manager or manually)
- DirectX 11 / OpenGL capable GPU (any modern system)

Optional - for the live browser controller:

- OBS WebSocket v5 (built into OBS 28+, enabled via Tools → WebSocket Server Settings)

---

## Usage in OBS

1. **Install obs-shaderfilter-plus** - download the latest release from the [releases page](https://github.com/Limeth/obs-shaderfilter-plus/releases) and place the plugin files in your OBS plugins folder.
2. **Clone or download this repository** to a folder on your machine (e.g. `C:/AfterGlow/`).
3. In OBS, right-click a **Source** → **Filters** → click **+** → choose **User-defined shader**.
4. In the filter settings, click **Browse** and select the `.hlsl` file you want.
5. The parameters (sliders, color pickers) will appear automatically in the filter panel.
6. Use the **Enable Effect** slider (0 = off, 1 = on) to toggle the filter without removing it.

**Optional - import all 22 filters at once:**
The included `collection/afterglow-collection.json` is a ready-made OBS scene collection with all filters pre-configured on a demo source. If your shader folder is not `C:/AfterGlow/`, open the file in a text editor and do a single Find & Replace: `C:/AfterGlow` → your actual path. Then import via **Scene Collection → Import** in OBS. You can then copy the filters from the demo source onto your own sources.

> **Tip:** Stack multiple shader filters on a single source. OBS applies them in order from top to bottom.

### Live Browser Controller ( Absolute Optional )

Run the included start script to launch a local server and open the controller automatically:

```
npm start
```

> **Note:** The controller must be served via HTTP — opening `afterglow.html` directly from the filesystem (`file://`) will not work, as browsers block WebSocket connections from file URLs. Any HTTP server works: VS Code Live Server, `npx serve`, nginx, etc. — as long as the HTML file is delivered over `http://`.

---

## Filters

### VHS `vhs.hlsl`
Simulates a worn VHS tape: chroma bleed, scanlines, tape noise, horizontal wobble, color washout and head-switch artifacts at the bottom of the frame.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle (0/1) |
| Chroma Bleed | Color channel smear horizontally |
| Scanline Intensity | Horizontal scanline darkening |
| Tape Noise | Random luminance noise |
| Tape Wobble | Horizontal warp / sync instability |
| Color Washout | Desaturation and lifted blacks |
| Head Switch Artifact | Glitch line at the bottom edge |

---

### CRT `crt.hlsl`
Classic cathode-ray tube monitor look with scanlines, barrel-like screen curvature and an amber phosphor tint.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Scanline Intensity | Strength of horizontal scanlines |
| CRT Curvature | Edge darkening / screen warp feel |
| Amber CRT Strength | Warm amber phosphor color cast |

---

### Glitch `glitch.hlsl`
Digital datamosh / signal corruption: RGB chromatic split, scanline jitter, block displacement, pixel noise and signal dropout bars.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Glitch Intensity | Master intensity for all effects |
| RGB Split Amount | Horizontal channel separation |
| Scanline Jitter Strength | Per-line vertical shake |
| Jitter Speed | Rate of jitter changes |
| Block Size | Size of displaced pixel blocks |
| Block Shift Strength | How far blocks are displaced |
| Digital Noise Amount | Random pixel noise overlay |
| Dropout Chance | Black/white horizontal dropout bars |

---

### RGB Split `rgbsplit.hlsl`
Isolated chromatic aberration - separates the red and blue channels horizontally with optional animated direction oscillation.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| RGB Split Amount | Channel separation distance |
| Animate Direction | Toggle oscillation on/off (0/1) |
| Animation Speed | Speed of direction oscillation |

---

### Pixelate `pixelate.hlsl`
Simple block pixelation - snaps UV coordinates to a grid.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Block Size | Pixel block size (larger = more pixelated) |

---

### Interlace `interlace.hlsl`
Simulates interlaced video: alternating lines are shifted, dimmed and optionally rolling.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Interlace Intensity | Overall interlace strength |
| Horizontal Line Shift | Even/odd line horizontal offset |
| Field Flicker | Alternating field brightness flicker |
| Scanline Gap Darkness | Darkness of the gaps between lines |
| Rolling Bar Speed | Speed of a rolling interference bar (0 = off) |

---

### Analog Interference `analoginterference.hlsl`
Bad TV / antenna reception: horizontal tearing, rolling bars, static noise, color bleed and signal dropout flashes.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Horizontal Tearing / Sync Loss | Torn horizontal slices |
| Rolling Bar Intensity | Brightness of the rolling bar |
| Rolling Bar Speed | Speed the bar travels vertically |
| Static Noise Amount | White noise overlay |
| Color Bleed | Horizontal color smear |
| Signal Dropout | Random white flash dropout events |

---

### Lens Distortion `lensdistortion.hlsl`
Barrel, pincushion or fisheye lens distortion with edge chromatic aberration and vignette.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Distortion Amount | Negative = pincushion, positive = barrel/fisheye |
| Zoom | Compensate for edge cropping |
| Chromatic Aberration at Edges | RGB fringing at distorted edges |
| Edge Vignette | Darkening toward corners |

---

### Night Vision `nightvision.hlsl`
Green phosphor night-vision goggles look with brightness amplification, scanlines, grain and a tube vignette.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Brightness Amplify | Boosts dark areas |
| Phosphor Tint Intensity | Strength of green tint |
| Vignette Strength | Circular tube edge darkening |
| Scanline Intensity | Horizontal scanlines |
| Noise / Grain | Random luminance noise |
| Lens Blur at Edges | Soft blur toward the outer ring |

---

### Viewfinder `viewfinder.hlsl`
Old camcorder eyepiece HUD: corner brackets, blinking REC indicator, battery meter, exposure scale, running timecode and center reticle.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| HUD Color | RGBA color of all HUD elements |
| HUD Opacity | Overall HUD transparency |
| HUD Glow Intensity | Soft glow around HUD lines |
| Viewfinder Vignette | Edge darkening |
| Scanline Intensity | Subtle scanlines on the image |
| REC Blink Speed | Speed of the blinking REC dot |
| Battery Level | Battery meter fill (0–100) |
| Exposure Level Indicator | Marker position on exposure scale |
| Show Center Reticle | Toggle crosshair (0/1) |

---

### Timecode `timecode.hlsl`
HH:MM:SS elapsed-time overlay rendered as a 7-segment display. Starts counting when the filter is applied.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Digit Color | RGBA color of the digits |
| Background Color | RGBA color of the backing box |
| Position X / Y | Overlay position (0–100) |
| Digit Height | Size of the digits |
| Background Padding | Box padding around digits |

---

### Waveform `waveform.hlsl`
Audio waveform line overlay driven by the FFT of the selected audio source.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Waveform Color | RGBA line color |
| Vertical Position | Vertical center of the waveform |
| Amplitude Scale | Height of the waveform |
| Line Thickness | Width of the drawn line |
| Glow Softness | Soft halo around the line |
| Background Dimming | Dim the video behind the waveform |
| Background Bar Height | Opaque backing bar height |
| Frequency Range Min/Max | FFT band range to visualize |

---

### Spectrum Analyzer `spectrumanalyzer.hlsl`
FFT frequency bar graph overlaid on the source with per-bar glow/bloom and temporal smoothing.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Spectrum Color | RGBA bar color |
| Frequency Range Min/Max | Bass to treble band selection |
| Number of Bars | Bar count (1 = continuous fill) |
| Gap Between Bars | Space between bars |
| Frequency Smoothing | Temporal smoothing of bar heights |
| Bar Glow / Bloom | Additive glow above bar tops |
| Bar Opacity | Transparency of the bars |

---

### ASCII Art `ascii.hlsl`
Renders the image as a grid of ASCII-style block patterns approximated from luminance, with optional color output.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Cell Size | Size of each character cell (pixels) |
| Colored Output | 1 = use source colors, 0 = monochrome |
| Dark Background Intensity | Background fill darkness |

---

### Dithering `dithering.hlsl`
Bayer ordered dithering - quantizes color depth and applies a classic 2×2, 4×4 or 8×8 threshold matrix.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Color Levels per Channel | Quantization steps (2–16) |
| Dither Matrix Size | 0–33 = 2×2, 34–66 = 4×4, 67–100 = 8×8 |
| Pixel Block Size | Upscaled pixel grid size |
| Colored | 1 = color, 0 = monochrome |

---

### CGA Palette `cgapalette.hlsl`
Reduces the image to a classic CGA, EGA or Nintendo Game Boy color palette with optional dithering.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Palette | 0=CGA1, 1=CGA2, 2=CGA3, 3=EGA16, 4=Game Boy |
| Pixel Block Size | Upscaled pixel size |
| Dither Strength | Ordered dither before palette snap |

---

### Halftone `halftone.hlsl`
Newspaper dot-raster / pop-art look using rotated halftone dot grids.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Dot / Cell Size | Size of halftone dots |
| Screen Angle | Grid rotation (0–45°) |
| Colored Dots | Use source colors or monochrome |
| White Background | White or black background |
| Dot Edge Softness | Anti-aliasing on dot edges |

---

### Duotone `duotone.hlsl`
Maps image luminance between two colors - shadows to color A, highlights to color B. Classic risograph / poster look.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Shadow Color | RGBA color for dark tones |
| Highlight Color | RGBA color for bright tones |
| Contrast / Midpoint Push | Pushes luminance toward extremes |
| Mix with Original | Blend back to the original image |
| Film Grain | Animated noise overlay |

---

### Moon `moon.hlsl`
Flat matte monochrome look: desaturated, lifted blacks, reduced contrast, optional cold/warm tint and highlight glow.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Matte Fade | Lift blacks (matte feel) |
| Contrast | Overall contrast |
| Brightness | Overall brightness |
| Cold/Warm Tint | Negative = cold blue, positive = warm amber |
| Mix with Original | Blend back to color image |
| Glow / Bloom on Highlights | Soft bloom on bright areas |

---

### Lomo `lomo.hlsl`
Lomography camera characteristics: heavy oval vignette, saturation boost, S-curve contrast, shadow lift and color shift.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Vignette Strength | Oval edge darkening |
| Saturation Boost | Color intensity increase |
| S-Curve Contrast | Non-linear contrast push |
| Shadow Lift (matte) | Lifted black point |
| Color Shift | Warm reds / cool blues in shadows |
| Film Grain | Animated noise |

---

### Cross Process `crossprocess.hlsl`
Film cross-processing: per-channel tone curves applied as if developed in the wrong chemistry.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Effect Strength | Blend between original and processed |
| Preset | 0=E6inC41, 1=C41inE6, 2=ECN2, 3=Custom |
| Contrast | Additional contrast |
| Saturation | Additional saturation |
| Film Grain | Animated noise |

---

### Film Burn `filmburn.hlsl`
Animated film damage: edge charring, overexposure flares, colored light leaks, chemical blotches and grain.

| Parameter | Description |
|---|---|
| Enable Effect | Bypass toggle |
| Edge Burn / Charring | Dark burn toward corners |
| Overexposure Flares | Bright blown-out patches |
| Light Leak | Colored edge bleed |
| Chemical Blotches | Random dark blotch overlay |
| Animation Speed | Rate of animated elements |
| Film Grain | Animated noise |

---

## Tips

- **Stacking order matters** - put Lens Distortion before CRT, or VHS before Glitch for realistic layering.
- **Enable Effect = 0** lets you keep a filter ready in OBS and flip it on via the WebSocket controller without touching the OBS UI.
- **Color parameters** (RGBA hex) can be set in OBS by clicking the color picker that appears next to the filter.
- The **Spectrum Analyzer** and **Waveform** filters require an audio source - apply the filter to a source that has audio or use OBS audio monitoring.

---

## Roadmap

More filters are planned - this collection is actively growing. Have an idea for a shader or a look you'd like to see? Open an issue or start a discussion, suggestions are very welcome.

---

## License

[CC BY-SA 4.0](LICENSE) © 2026 Thomas Meschke / vlrm.prjct
