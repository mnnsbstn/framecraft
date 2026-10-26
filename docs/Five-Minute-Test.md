# Five-minute recording acceptance — October 26, 2026

FrameCraft **0.3.3, build 7**, same installed binary as the prior reliability test. [SBSTN-85](https://linear.app/mnnsbstn/issue/SBSTN-85) is complete for the documented scope. The previous 179.642-second trial was manually stopped by the user; this repeat reached the full planned duration.

## Result

- Continuous silent window recording: **347.910 seconds** at 1312 × 844.
- Saved the complete project and reopened it through the app, preserving **18,782 cursor samples** and the full timeline.
- Exported the entire selection at **1920 × 1080, 30 fps**, with the same duration and no audio tracks.
- Decoded beginning/middle/end frames from both source and export. Visible text markers distinguish the initial, middle and final recording states.
- No screen-recording permission change, app rebuild or source-code change. The earlier 29 passing automated tests remain the code baseline; they were not repeated for this live acceptance.

## Measurements

Ten-second samples of the FrameCraft process only. RSS is resident memory. CPU percentage can exceed 100% for a multithreaded process; sampled values can miss brief peaks.

| Phase | Samples | RSS min–max (MiB) | CPU median / max (%) |
|---|---:|---:|---:|
| after-export | 2 | 65.95–78.3 | 0.55 / 1.1 |
| capture | 33 | 47.92–62.42 | 35.6 / 40.3 |
| capture-stop-transition | 2 | 55.16–107.08 | 16.95 / 33.9 |
| export | 8 | 71.25–155.42 | 93.05 / 105.3 |
| save-and-preview | 14 | 66.36–129.16 | 0.0 / 20.7 |

Observed export completion upper bound: **79.5 seconds**, including UI/tool latency before the save action. Source samples per second: 57.27; maximum sorted source timestamp gap: 0.2050 seconds. Maximum exported timestamp gap: 0.0333 seconds. The source is a variable-rate ScreenCaptureKit recording; the export is nominally 30 fps.

This is a mostly static original TextEdit window with two deliberate text changes, not a multi-hour or high-motion stress test. Audio, full-display capture, GPU/system-wide memory and energy were not measured. All compressed video samples were enumerated, the entire export was sequentially decoded (10,438 decoded video frames, no reader error), and beginning/middle/end images were checked. This is not a frame-by-frame visual audit.

One initial seek-based image generated with a reused AVAssetImageGenerator showed text artifacts near the end. Sequential decoding and a fresh exact-time image generator both produced clean output at 347.033333 seconds. This was not reproduced as a persistent exported-frame defect; the initial diagnostic image and counterchecks are retained as evidence.

## Evidence

- [Machine-readable acceptance](verification/five-minute-2026-10-26.json)
- [Process resource samples](verification/five-minute-resources-2026-10-26.json)
- [Editable project](../examples/FrameCraft-Fuenfminutentest-2026-10-26.framecraft)
- [Complete MP4 export](../examples/FrameCraft-Fuenfminutentest-2026-10-26.mp4)
- [Earlier implementation and failure tests](Reliability.md)

Diagnostic counterchecks: [initial seek artifact](verification/five-minute-seek-artifact.png), [clean sequentially decoded frame](verification/five-minute-sequential-end.png), [clean fresh exact-time seek](verification/five-minute-fresh-seek-end.png), and [full decode result](verification/five-minute-sequential-decode.txt). The dedicated verification helpers are [sequential decode](../script/verify-full-decode.swift) and [exact seek](../script/verify-exact-frame.swift); their output locations and end-frame timestamp are fixed to this trial.
