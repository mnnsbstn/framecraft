# Reliability: long recordings, project storage and export

FrameCraft 0.3.3 (build 7), October 24, 2026. Implements [SBSTN-85](https://linear.app/mnnsbstn/issue/SBSTN-85/lange-aufnahmen-und-fehlerfalle-auf-stabilitat-prufen), selected after stable local signing because reliable saving and export protect the recording workflow before more editing features are added.

## Changes

- Project encoding, decoding and media copies run in a dedicated persistence actor instead of the UI actor. Saving displays `Projekt wird gespeichert …` and guards conflicting editor actions and application exit.
- New projects are assembled in a sibling staging folder. They become visible at the destination only after media and metadata have been written. Failure removes staging data, preserves the source, and does not replace a destination that appears during the operation. Metadata-only saves use atomic file replacement.
- Compact JSON reduces whitespace overhead for large cursor tracks. The project schema remains version 1, so existing projects remain compatible.
- Export uses `AVAssetExportSession.export(to:as:)` and `states(updateInterval:)` for completion and progress. Both the UI cancel action and parent-task cancellation propagate to the actual export task. Temporary output is removed before the service becomes reusable. Original media and existing destination files remain protected.
- Nested filesystem errors indicating a full disk receive a specific German recovery message. This does not reserve space or guarantee that an external disk will remain connected.

## Automated verification

All 29 tests passed. The nine added cases cover:

1. Round-trip persistence of 216,001 cursor samples, representing one hour at 60 samples/second, including metadata-only resave.
2. Simulated disk-full failure during a new save, cleanup, unchanged original and successful retry.
3. Failed resave preserving the prior project metadata and video.
4. Another process creating the destination during save, without overwriting it.
5. UI actor responsiveness while a background metadata writer is deliberately blocked.
6. A nested POSIX ENOSPC error wrapped in an AVFoundation-style error.
7. Cancellation after export progress is observed, followed by successful reuse of the same exporter.
8. Parent-task cancellation removing temporary output.
9. Export failure with a missing destination directory, followed by successful reuse.

The disk-full test injects a write error; it does not fill the user's disk. The missing-directory export test is a real filesystem failure. These tests are separate from the live recording below.

## Scope and remaining limitations

The live trial uses one mostly static, original TextEdit window without audio. The one-hour cursor dataset is synthetic; it is not a one-hour real recording. Process RSS and sampled CPU percentages do not measure total system/GPU memory, energy, or performance on other Macs. Three decoded images per video check the beginning, middle and end; compressed sample timestamps check media continuity, not a full visual audit of every frame. A static ScreenCaptureKit source may have a variable source frame rate; the exported timeline is 30 fps.

Audio, full-display and multi-display recording acceptance remain separate Linear tasks. Unexpected process termination during a save can leave a hidden staging folder; the previous completed project is protected, but there is no automatic crash-recovery UI. Disk disconnection, physical media corruption, multi-hour high-motion workloads and memory-leak profiling remain outside this bounded trial.

This update modernizes export completion and progress. The existing Core Image video-composition initializer and one capture callback still produce SDK migration warnings; they are not hidden or claimed to be resolved by this release.

## Reproduce

Run `./script/build_and_run.sh --test`. Build using the existing stable signing identity after saving and closing FrameCraft. Select only an original test window, explicitly disable both audio options, record for at least five minutes, then save, reopen and export the full selection. Keep recording duration separate from export wall time, and state the sample interval and process scope for any resource measurements. Do not reset screen-recording permission merely to update the app.

## Live acceptance results

The planned five-minute recording ended at 179.642 seconds before the agent issued a stop action. The app showed no recording error and imported a finalized file. The cause is not yet established; user clarification is pending. The full five-minute endurance acceptance therefore remains open in SBSTN-85. The text visible inside the original test window describes the planned duration, not the achieved duration.

The app recorded the original silent test window for **179.642 seconds** and saved/reopened the project with **10,564 cursor samples**. The full selection exported as **1920 × 1080 at 30 fps**, with no audio tracks. No screen permission reset, toggle or additional grant was required for the update.

Measured resource samples (10-second interval, FrameCraft process only):

| Phase | Samples | RSS min–max (MiB) | CPU median / max (%) |
|---|---:|---:|---:|
| after-export | 2 | 133.67–138.94 | 0.0 / 0.0 |
| after-unobserved-stop | 4 | 105.59–109.08 | 0.0 / 0.0 |
| capture | 18 | 66.75–84.72 | 29.5 / 33.7 |
| export | 3 | 151.02–201.14 | 90.5 / 93.7 |
| save-and-preview | 4 | 117.19–135.33 | 0.3 / 1.3 |

The export completed within 35.7 seconds of the pre-click observation (including UI/tool latency); file creation to last modification took 29.2 seconds. The source contained 10,307 compressed video samples (57.38 samples/second overall), with a maximum sorted timestamp gap of 126.7 ms. The export was nominally 30 fps and had a maximum timestamp gap of 33.33 ms. Exact timing is in the machine-readable evidence. CPU percentages may exceed 100% for a multithreaded process. Sampling may miss short peaks.

Evidence: [media and acceptance](verification/reliability-0.3.3.json), [resource samples](verification/resources-0.3.3.json), [test log](verification/tests-0.3.3.txt), [editable project](../examples/FrameCraft-Langzeittest-0.3.3.framecraft), and [full export](../examples/FrameCraft-Langzeittest-0.3.3.mp4).

The standalone [media inspection helper](../script/verify-recording-media.swift) can be compiled with `xcrun swiftc -parse-as-library script/verify-recording-media.swift -o /tmp/framecraft-verify-media`. Create a local `work/` directory first, then pass the source and exported MP4 paths. It writes JSON and sample PNGs under `work/`; its filenames are fixed for this verification workflow. This helper is separate from the shipped app.
