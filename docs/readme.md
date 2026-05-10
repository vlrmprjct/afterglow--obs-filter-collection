# AfterGlow — Demo

<video src="https://github-production-user-asset-6210df.s3.amazonaws.com/1859497/590078444-1e0a49b0-471b-4bd9-bfc7-f2d939d4294b.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20260510%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20260510T081514Z&X-Amz-Expires=300&X-Amz-Signature=d2826023d15dcde41b470f467b061680a56e4676f84e4bbce3e21fef8ae70967&X-Amz-SignedHeaders=host&response-content-type=video%2Fmp4" controls width="100%"></video>

Original Video von Ray.: https://www.pexels.com/de-de/video/stadt-strasse-verkehr-skyline-17701662/

## Filters used in this demo

| Filter | File |
|---|---|
| Viewfinder | `viewfinder.hlsl` |
| CRT | `crt.hlsl` |
| Glitch | `glitch.hlsl` |
| RGB Split | `rgb_split.hlsl` |


## Usage in OBS

![OBS filter stack](obs.png)

<video src="https://github-production-user-asset-6210df.s3.amazonaws.com/1859497/590078410-7fa565a5-7997-4e03-abc7-1911cbd3b803.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAVCODYLSA53PQK4ZA%2F20260510%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20260510T081913Z&X-Amz-Expires=300&X-Amz-Signature=51a3781505f9764f4581e2540fd678b5228ab6788f294fa8cb047d5c6246914c&X-Amz-SignedHeaders=host&response-content-type=video%2Fmp4" controls width="100%"></video>

Original Video from Efrem Efre: https://www.pexels.com/de-de/video/35652450/

## About the setup

All four filters are stacked on a single webcam source in OBS. The **Enable Effect** parameter on each filter is set to `1` or `0` to switch them on and off live — without removing or re-adding the filter.

The [AfterGlow browser controller](../web/afterglow.html) (`web/afterglow.html`) was used to adjust parameters in real time via OBS WebSocket while recording.

![Browser Control](browser.png)

→ [Back to main readme](../readme.md)
