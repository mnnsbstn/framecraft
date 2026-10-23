# Reference analysis and implementation decisions

As of October 23, 2026. Earlier verification sections describe their respective versions; later sections record subsequent acceptance checks.

## REA observations

The inspected package was linked from https://screen.studio/download:

`https://screenstudioassets.com/releases/4.1.0-5005/Screen%20Studio%204.1.0-5005%20Apple%20Silicon.dmg`

SHA-256: `65cd607bbf598767faf3f9498819f423b0efbb9195ec5476b7fa9d05ddbd8b71`.

- Inventory: `ev_500e3a7f3f22305bf542ebaea5071d2dc4904883f23c951792063cfe7e15c4a7`
- Inspection: `ev_867e753db43741578063dfaeaef46ae6c42eeff0320efb758ffc21152d0767cd`
- 4,260 content nodes, nine integrity contradictions. Completeness refers to the completed inventory, not behavioral analysis.
- An ASAR container with a JavaScript entry point and native helper files. The separately read package descriptor specifies `main: ./dist-electron/index.js` and version `4.1.0-5005`.
- Strict local signature verification: `invalid signature (code or signature have been modified)`. This result is not treated as evidence of malware.
- The app was not launched, no protections or export licenses were bypassed, and no reference content was copied into the independent app.

The complete REA evidence export is retained internally at `work/screenstudio-reference/rea-evidence.json`; the usable summary, including all nine checksum contradictions, is in [REA-Befunde.json](REA-Befunde.json).

## Documented behavioral reference

| Question | Officially documented | Independent implementation |
| --- | --- | --- |
| What is recorded? | Display, window, or region | Display/window via ScreenCaptureKit; no region support |
| How are zooms created? | Automatically from clicks or manually | Independent click/manual intervals; no recovery of the original algorithm |
| How are zooms edited? | Dedicated track, duration/focus/strength | Dedicated selection track and duration/focus/strength controls |
| How is appearance configured? | Background, padding, rounded corners, shadows | Four original gradients, padding/corners, and a fixed shadow |
| How is footage edited? | Trim, split, remove | Start/end trim; no multi-clip editing |
| How do projects remain editable? | Save and reopen | Custom JSON format plus a copy of the original video |
| How is output produced? | MP4/GIF and additional export settings | Local MP4 export with a fixed 30 fps composition |

Official sources:

- [Display recording](https://screen.studio/guide/recording-entire-display)
- [Window recording](https://screen.studio/guide/recording-single-window)
- [Automatic zooms](https://screen.studio/guide/auto-zoom)
- [Editing zooms](https://screen.studio/guide/adding-editing-zooms)
- [Manual zoom](https://screen.studio/guide/manual-zoom)
- [Background](https://screen.studio/guide/background)
- [Trimming](https://screen.studio/guide/trimming)
- [Aspect ratio](https://screen.studio/guide/aspect-ratio)
- [Importing video](https://screen.studio/guide/creating-project-from-existing-video)
- [Saving projects](https://screen.studio/guide/saving-your-project)
- [Export](https://screen.studio/guide/exporting-the-video)

## Independent technical decisions

FrameCraft uses SwiftUI with a small AVPlayerView bridge, ScreenCaptureKit for recording, AVFoundation for media management/export, and Core Image for the shared preview/export composition. It has no Electron or FFmpeg dependency.

A zoom is an interval with normalized focus and magnification. The initial implementation used its own Smoothstep entry/exit ramp and continuously blended the focus of overlapping intervals; version 0.3 replaces this behavior as described below. Generated click intervals start 0.45 seconds before a click and end 1.65 seconds after it. Spatially close repeated clicks extend the zoom. Distant targets create separate intervals; manual intervals have priority. These are independent design values, not parameters extracted from Screen Studio.

Project files reference a local copy of the original inside the selected project folder. Import validation bounds time values, focus coordinates, zoom strength, and appearance settings. Export writes a temporary file first and overwrites neither the original nor existing destination files.

Apple sources:

- [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- [SCRecordingOutput](https://developer.apple.com/documentation/screencapturekit/screcordingoutput)
- [AVVideoComposition](https://developer.apple.com/documentation/avfoundation/avvideocomposition)

## Initial verification status

- Provenance link, DMG CRC, and REA package inventory checked; integrity discrepancies documented.
- Build script, Swift compilation, release-app launch, and strict local ad hoc signature verification succeeded.
- Seven automated tests passed, including real landscape/portrait MP4 exports with trim verification, original-file protection, and cancellation.
- UI and preview practically tested; layout and unsaved-changes indication corrected.
- Original TextEdit window recording after user approval: 11.885 seconds, followed by a manual zoom and successful 1920 × 1080 MP4 export.
- Demo project saved/reopened with portrait format, trim, title, and zooms preserved. Portrait MP4: 4.8 seconds, 1080 × 1920.
- Export frames decoded and visually inspected. Microphone/system audio intentionally disabled; full-display recording and real click capture had not yet been validated at this stage.

Usage and limitations are documented in [README](../README.md).

## Version 0.2: cursor tracks and click zooms

ScreenCaptureKit records new sources with `showsCursor = false`. A 60 Hz timer captures normalized mouse positions and Quartz click counters; AppKit monitors add precise click events. After recording, times are normalized against the first video PTS. Window frames and occlusion are accounted for using the Quartz window list.

Symmetric temporal Gaussian smoothing is calculated once per composition. Near clicks, it fades in favor of the original position; gaps and hidden sections are not bridged. Rendering draws the custom arrow and optional click pulse before applying the same zoom transformation as the video. Cursor tracks and options are saved with the project; older projects without tracks remain readable.

Limitations: one arrow shape instead of changing original cursor shapes; window geometry refreshes every 100 ms, so rapid window movement may cause brief deviations. The timer provides no hard real-time guarantee. Smoothing does not reconstruct cursor tracks from imported video pixels.

Apple documentation: [Stream cursor](https://developer.apple.com/documentation/screencapturekit/scstreamconfiguration/showscursor), [Quartz event state](https://developer.apple.com/documentation/coregraphics/cgeventsourcestateid), [Event source](https://developer.apple.com/documentation/coregraphics/cgeventsource).

## Live acceptance of click zooms and cursor (October 23, 2026)

After renewing only FrameCraft's screen recording permission, a TextEdit window recording controlled by the user with a real mouse/trackpad was verified. `FrameCraft-Klicktest.framecraft` contains 10 clicks, 590 cursor samples, and 6 automatic 1.8× zooms. Saved intervals reproduce identically from the clicks; the track smoothed by the unchanged app model matches every click point exactly. The project was reopened through the UI with data intact.

`FrameCraft-Klicktest.mp4`: 10.925 s, 1920 × 1080, 30 fps, no audio. Multiple frames before/during zooms decoded successfully; the custom cursor and magnification are visible. No app rebuild was required for this check. The original 13 automated tests remained passed for this unchanged code. Earlier remote UI clicks produced no global mouse movement and therefore were not a valid cursor-track test.

## Smooth camera transitions in version 0.3

The earlier weighted blend of all active zoom regions could reactivate outdated targets. `CameraPath` plans the target sequence once per composition. Within connected automatic zoom groups, the latest target remains authoritative; short gaps of up to 300 ms connect groups. Manual zooms are resolved as higher-priority targets before smoothing.

A causal filter with a 600 ms finite response and a quintic Smoothstep function jointly smooths crop width and center. Superposition of target changes preserves position, velocity, and acceleration during retargeting; a new move does not restart at zero velocity. Target crops are clamped to image boundaries beforehand. The shared filter keeps intermediate crops within the source too. Time-based, stateless evaluation with binary search gives identical results for preview, scrubbing, and export without evaluating all regions every frame. Very short intervals may ease out beyond their nominal end.

Verification: 17 tests passed, including a rebound regression for overlapping regions of different lengths, 16 target changes 90 ms apart, continuous position/velocity, valid crops, manual priority, short gaps, and short zoom intervals. The unchanged live click project was loaded through the UI and exported as `FrameCraft-Sanfte-Zooms.mp4` (10.925 s, 1920 × 1080, 30 fps, no audio); multiple frames were decoded and visually inspected.
