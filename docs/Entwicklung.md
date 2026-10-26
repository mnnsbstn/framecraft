# FrameCraft: development and usage

An independent native macOS screen-video app inspired by the Screen Studio workflow. It uses its own SwiftUI interface and recording/rendering implementation; no Screen Studio assets or program components were copied.

**Status: version 0.3.0 was built and launched on this Mac.** All 17 automated tests pass. Improved camera motion was exported and verified using the saved live click test. Recording was last practically validated in version 0.2. The cursor demo was exported; a real window recording with a manual zoom had already been verified in version 0.1. Screen recording permission was successfully renewed. A real window recording with mouse movement and clicks also passed: 10 clicks, 6 automatic zooms, 590 cursor positions, successful Full HD export, and successful project reopening.

## Start using it

Double-click `dist/FrameCraft.app`. The app remains available in the project folder for future sessions. Source code and the build script are included; using the app does not require an active Codex chat. The interface remains German.

1. Choose **Record** (`Aufnehmen`), select a display or window, and start recording. Alternatively, import a video or choose **Try demo** (`Demo ausprobieren`).
2. Stop recording. Jump to a point in the timeline and choose **Add zoom** (`Zoom hinzufügen`). Under **Zoom & Trim** (`Zoom & Schnitt`), adjust strength, focus, zoom duration, and trim start/end.
3. Under **Appearance** (`Gestaltung`), adjust the format, gradient, padding, and corners.
4. Press **⌘S** to save an editable project. Use **Export video** (`Video exportieren`) to create an MP4.
5. Later, use **Open project** (`Projekt öffnen`) to select the entire `.framecraft` folder. Keep its original video and settings together.

Screen recording permission for version 0.2 was renewed by removing the old FrameCraft entry and adding the current app. Other apps' permissions were unchanged. If macOS asks again after a rebuild, allow FrameCraft in **System Settings → Privacy & Security → Screen & System Audio Recording**, then restart it. Microphone access is needed only when microphone recording is enabled.

The current live test is available as `FrameCraft-Klicktest.mp4` and the editable `FrameCraft-Klicktest.framecraft` project. Other examples include `FrameCraft-Demo.mp4` (portrait) and `FrameCraft-Aufnahmetest.mp4` (a real window recording), each with an editable `.framecraft` project. In this repository, these files are under `examples/`.

## Build and run

Requirements: macOS 15 or later and configured Xcode with a working Swift compiler. There are no third-party package dependencies.

From the project directory:

```sh
./script/build_and_run.sh --test
./script/build_and_run.sh --verify
```

The Codex Run action also starts the build script. It creates `dist/FrameCraft.app`, signs it locally, and opens the bundle. This is not Developer ID signing or notarization for public distribution. If FrameCraft is already running, the script asks you to quit normally to avoid losing an active recording.

Other options: `--build` builds without launching; `--logs` opens the app with log output; `--debug` starts the debugger.

## Features

- Display/window recording through ScreenCaptureKit, system audio, and optional microphone input.
- Stop recording from the window or menu bar. The app itself is excluded from display recordings.
- MP4/MOV import and an original six-second demo for testing without screen recording permission.
- Nondestructive start/end trimming, playback, and scrubbing.
- Manual zoom intervals with strength, start/end, and focus point. New recordings generate zooms automatically from clicks. Nearby repeated clicks extend the same zoom; distant targets receive separate intervals connected by continuous camera motion. Newer targets replace older ones without returning to them later. Manual zooms survive recalculation.
- Separate cursor tracks for new recordings: a custom arrow cursor, adjustable smoothing (0–250 ms), size, visibility, and click indicators. Preview and export use the same rendering.
- Four original gradients, padding, corner radius, and a fixed shadow; 16:9, 9:16, and 1:1 aspect ratios.
- Shared Core Image composition for preview and MP4 export, at 30 fps, with progress and cancellation.
- Project folders containing the original video and JSON editing settings; save and reopen support.

Recordings are saved to `~/Movies/FrameCraft` after an explicit start. The app requests its own screen/microphone permissions. Practical recording tests used only an original TextEdit test window without system audio or microphone input. Mouse data is captured only during recording and restricted to the selected source. Keyboard input is not captured. Save the `.framecraft` project to retain the separate cursor track; original MP4 files from new recordings do not contain a burned-in cursor.

The current version does not include region recording, webcam composition, changing cursor shapes (such as a text cursor), multi-clip editing, subtitles, GIF, cloud sharing, or configurable export quality. Zoom intervals are edited using controls; dragging their timeline edges is not implemented. This is not a complete Screen Studio replica.

## Smooth camera motion (version 0.3)

Rapid click sequences play as an ordered sequence of camera targets. Motion is smoothed over 600 ms; a new click takes over the current motion without a jump in position or velocity. Gaps of up to 300 ms between zoom intervals remain within the same camera movement. Manual zooms retain priority. Calculation is identical for preview and export and deterministic when jumping through the timeline.

The improvement also applies to existing projects. For example, open `FrameCraft-Klicktest.framecraft` and export it again. `FrameCraft-Sanfte-Zooms.mp4` is the new export; `FrameCraft-Klicktest.mp4` is retained for comparison with version 0.2. Very short intervals ease in and out; the tail can continue for up to 600 ms after the last target change.

Four new tests cover prevention of target rebound, continuous movement during rapid target changes, valid crops, short gaps, manual priority, timeline jumps, and very short zooms. Combined with the previous 13 tests, all 17 pass.

## Using click zooms and the cursor

For **new recordings**, zooms are added automatically after stopping. Under **Zoom & Trim → Generate zooms from clicks** (`Zoom & Schnitt → Zooms aus Klicks erzeugen`), they can be recalculated. An edited zoom becomes manual and is preserved.

Under **Appearance → Cursor** (`Gestaltung → Cursor`), show/hide the cursor, change smoothing and size, or disable click indicators. The default smoothing is 120 ms. At click times, smoothing converges to the recorded hit point. Outside the recording source and across longer gaps, the cursor is hidden. The app itself is excluded as a click target.

Older projects and imported videos do not receive invented mouse data: a burned-in cursor cannot be removed or smoothed retroactively. **Try demo** contains a separate cursor track for immediate testing. `FrameCraft-Cursor-Demo.mp4` and its project are available in `examples/`.

## Verified on October 23, 2026

- Release build with Apple Swift 6.4, app launch, and strict local ad hoc signature verification succeeded.
- The original seven tests passed: zoom ramps, automatic zoom selection, project-data round trip, landscape/portrait export, protection of originals/existing targets, and export cancellation.
- Automated video export tests: trimming seconds 1–4 produces a 3-second output at 1920 × 1080 or 1080 × 1920; frames decode successfully.
- UI checks covered loading the demo, trimming, choosing a zoom, changing focus/background/format, saving, exporting, and reopening.
- Portrait demo: 4.8 seconds, 1080 × 1920, with a visible gradient and zoom.
- Real window recording: 11.885 seconds, manual zoom, 1920 × 1080 export. Frames from both exports were decoded and visually inspected; no audio tracks, as intended.
- Reopened demo project retained its title, portrait format, 0.6–5.4-second trim, and two zooms; playback started.

Six additional tests cover measurable smoothing, exact click positions, hidden intervals/gaps, older projects, cursor-track persistence, click grouping, and visible cursor pixels in exports (13 tests in version 0.2). System audio, microphone input, and full-display recording remain unvalidated in practice. The earlier window test had no click data; manual zooms worked.

The final live test with a real mouse/trackpad passed: 10.925 seconds of window recording, 10 clicks, 6 automatic 1.8× zooms, and 590 cursor positions (373 visible within the test window). The six intervals reproduce identically from saved clicks. The smoothed track matches all ten saved click positions exactly. Export: 1920 × 1080, 30 fps, 10.925 seconds, no audio; frames before zooming and at multiple click locations were decoded, with cursor and zoom effects visually checked. Reopening retained all ten clicks and six zooms. Earlier remotely controlled tests produced no global mouse movement, which was a limitation of the test method.

The new demo was exported with a cursor and automatic zooms (6 seconds, 1920 × 1080). Smoothing/size changes made through the UI persisted after reopening (145 ms, 1.4×). Webcam, changing cursor shapes, multi-clip editing, and the other listed features remain absent. Some AVFoundation calls produce deprecation warnings; build and tests pass on this Mac.

## Reference inspection with REA

Screen Studio was not found in the checked application folders, Downloads, or Spotlight results. Instead, the Apple Silicon package `4.1.0-5005` linked from the official download page was downloaded and inspected read-only.

REA inventoried 4,260 DMG content nodes and found nine discrepancies between internal ASAR checksums and observed files. The subsequent package inventory explicitly used `record-and-continue`; mismatching content remains marked untrusted. Strict local macOS signature verification also reported an invalid signature. The disk-image checksum was valid, which does not establish a valid app signature. The reference app was neither run nor installed, and the disk image was ejected.

The package structure indicates an Electron shell (`app.asar`, `dist-electron/index.js`) with native helpers. This does not reveal executed algorithms or exact zoom parameters. Official guides also informed the functional requirements; FrameCraft implements its own algorithms using Apple APIs.

See [REA findings](REA-Befunde.json), [analysis](Analyse.md), and [build status](Build-Status.txt) for sources, evidence, and limitations.

## Development tracking

[FrameCraft project](https://linear.app/mnnsbstn/project/framecraft-00c6db8009c8) · [Development journal and roadmap](https://linear.app/mnnsbstn/document/framecraft-entwicklungsjournal-prufnachweise-und-roadmap-33f00559e3ba)

Previous work, pending acceptance checks, and proposed extensions are tracked as issues. New features, fixes, and technical changes are documented as work continues. `AGENTS.md` preserves this requirement for future sessions; `docs/Linear.md` contains a translated snapshot. There is no automatic background synchronization. GitHub documentation is English; the app, Linear, local German documentation, and user communication remain German.

Installation follow-up — October 24, 2026
Version 0.3.1 packaged, strictly signature-verified, installed at the existing path and launched. Previous bundle backed up. Denied-access notice, disabled source/start controls and settings navigation verified in the UI. ScreenCaptureKit still denies access after launch-only restart while the macOS toggle appears enabled. User renewal and stable identity signing remain open; no new recording was made. App archive 0.3.1 created and ZIP integrity/executable permissions checked; 0.3.0 archive retained.

## Recovery verified — October 24, 2026

After the user unlocked the Mac, FrameCraft 0.3.1 successfully enumerated recording sources. No further permission reset or app rebuild was needed. A new 9.19-second recording captured only the original TextEdit test window, with system audio and microphone disabled. The project was saved and reopened after a normal launch-only restart. Source enumeration still worked after that restart.

AVFoundation read both media files and decoded a frame from each: source 1172 × 976, export 1920 × 1080, duration 9.19 seconds each, zero audio tracks. The exported frame was visually checked for the expected test window, gradient, rounded corners, and framing. The first decoding attempt was blocked in the restricted execution environment; the same reviewed local verifier succeeded outside it. This is a metadata and sampled-frame check, not a complete frame-by-frame quality audit.

This recording contains zero captured clicks and no zoom segments; it verifies permission recovery, recording, persistence, and export, not a new mouse/click/zoom acceptance test. Earlier real-click evidence remains the reference for those features. The app binary and existing 20-test source state were unchanged. Stable signing and permission retention across future changed builds remain open under SBSTN-82; ordinary restart success does not establish update retention.

Evidence: [MP4 export](../examples/FrameCraft-Freigabetest-0.3.1.mp4), [editable project](../examples/FrameCraft-Freigabetest-0.3.1.framecraft), and [installation record](verification/install-0.3.1.json).

## Stable signing accepted — October 24, 2026

Version 0.3.2 build 6 is installed with a persistent local code-signing identity. The private key stays in the user keychain; the build script automatically reuses a saved public certificate selector. No certificate trust overrides, Gatekeeper changes, or direct TCC database edits were made. The setup was rerun successfully using the same identity.

The initial migration from ad hoc signing required one scoped FrameCraft ScreenCapture reset and registration of the current app. The first signed build (5) recorded an original silent TextEdit test window for 11.0 seconds. The next build (6) changed Swift code by adding a version/build tooltip to the footer, and was rebuilt, signed and installed at the same path. Both executable hash and CDHash changed, while the certificate-and-identifier requirement stayed identical. The second build immediately loaded sources and recorded 17.271667 seconds without another permission prompt, reset, toggle or registration. This verifies permission retention across an actual changed-code update on this Mac.

Both original clips are 1312 × 844 with no audio. The second clip exported at 1920 × 1080 with no audio. Metadata and one decoded frame per file were checked; the export frame was visually inspected. These are permission/update checks with zero captured clicks, not a new cursor/zoom acceptance test or full frame-by-frame video audit.

All 20 app tests passed. Native signing checks passed for different executables, mutually compatible requirements, rejection of an ad hoc impostor with the same identifier, and tamper detection. The running-app guard and explicit ad hoc downgrade rejection were also checked. Subsequent updates compare both old/new requirements before replacing the app. A missing key or incompatible identity must fail rather than silently changing identity.

This resolves the local update-related permission loss tracked by SBSTN-82. It does not guarantee that macOS will never request consent after revocation, policy changes, migration to another Mac, or certificate replacement/expiry. Developer ID distribution/notarization remains a separate, unimplemented workflow. Keep the local signing key; see [stable identity guidance](Signing-Identity.md).

Evidence: [machine-readable update test](verification/stable-signing-0.3.2.json), [20-test log](verification/tests-0.3.2.txt), [post-update export](../examples/FrameCraft-Signaturtest-B.mp4), and editable [before](../examples/FrameCraft-Signaturtest-A.framecraft)/[after](../examples/FrameCraft-Signaturtest-B.framecraft) projects.

## Reliability implementation and partial live acceptance — October 24, 2026

Version 0.3.3 build 7 adds background project persistence with staged creation and atomic metadata updates, modern async export progress/completion, propagated cancellation, and a specific full-disk error. All 29 tests pass, including 216,001 cursor samples and failure/retry cases. A 179.642-second original silent window recording was saved, reopened and exported in Full HD. Permission survived the update. See [reliability report](Reliability.md) for measured resources, timing, evidence and the bounded scope of this trial. The planned five-minute capture ended early without an observed agent stop action; its cause remains open in SBSTN-85. Audio/display tests and multi-hour high-motion endurance testing are not claimed.

## Recording-stop clarification — October 26, 2026

The user confirmed that they manually stopped the 179.642-second test recording. The unexplained-stop concern is resolved; this trial does not show an automatic recording failure. Existing save/reopen/export results and 29 passing tests remain valid. SBSTN-85 remains In Progress because the planned five-minute endurance trial has not yet been completed. Documentation-only clarification: no app rebuild, new recording, or new test run.

## Five-minute acceptance completed — October 26, 2026

The same FrameCraft 0.3.3 build 7 completed a 347.910-second silent test-window recording, project save/reopen and full Full-HD export. SBSTN-85 is complete for this scope. See [measured acceptance and limitations](Five-Minute-Test.md). No code change, app rebuild or automated test rerun.
