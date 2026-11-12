# FrameCraft

An independent native macOS app for screen recording, automatic click zooms, smooth cursor movement, and MP4/GIF export. Inspired by the Screen Studio workflow, with its own interface, implementation, and test media.

**Version 0.8.0 · macOS 15+ · Apple Silicon.** New recordings follow system cursor changes, including text, hand and resize pointers. Select a rectangular region on any connected display before recording. An optional webcam overlay can be positioned and resized in the editor. FrameCraft records either monitor in an extended desktop and places click zooms using the mouse-down location. See the [two-display recording and export measurements](docs/Display-Acceptance.md).

## Getting started

- [Download the local Apple Silicon build 0.8.0](artifacts/FrameCraft-0.8.0-macos-arm64.zip), extract it, and open FrameCraft.app. The build uses a persistent self-signed local identity, without Developer ID signing or public notarization.
- Alternatively, build from source with a configured Xcode installation:

```sh
git clone https://github.com/mnnsbstn/framecraft.git
cd framecraft
python3 script/setup-local-signing.py
./script/build_and_run.sh --test
./script/build_and_run.sh --verify
```

The app is created at `dist/FrameCraft.app`. If the app is already running, the script asks you to quit it normally to avoid losing a recording. Other options: `--build`, `--logs`, `--debug`.

For a new recording, allow FrameCraft in macOS System Settings → Privacy & Security → Screen & System Audio Recording. Microphone access is required only when microphone recording is enabled. The one-time switch from ad hoc to a stable identity may require renewed permission. Version 0.3.2 retained recording access across two builds with different executable code and the same signing identity, without a second permission change. Keep the signing key and bundle identifier stable.

## Using the app

The app interface remains German. The English instructions below refer to these existing controls.

1. Choose **Record** (`Aufnehmen`) and select a window, display or region. You can also import a video or load the demo.
2. Stop recording to generate click zooms automatically. Under **Zoom & Trim** (`Zoom & Schnitt`), edit focus, zoom strength, and timing.
3. Under **Appearance** (`Gestaltung`), adjust the format, background, frame, and cursor.
4. Press **⌘S** to save a `.framecraft` project; **Export video** (`Video exportieren`) opens MP4/GIF settings before choosing a destination.
5. To resume editing, select the entire project folder using **Open project** (`Projekt öffnen`). Keep the original video and JSON together.

## Multi-clip editing and captions

These controls are available in the 0.9.0 source and the [hosted Apple Silicon preview](https://github.com/mnnsbstn/framecraft/actions/runs/43250524759/artifacts/13959700154) (build 17, available through November 26, 2026; sign in to GitHub to download). Extract the artifact and its enclosed ZIP. The hosted build uses an ad hoc signature. Replacing a persistently signed installation with it can require new recording permissions. To keep that identity, build the source with your existing local signing setup. The packaged 0.8.0 download above predates these controls. [Build record](https://github.com/mnnsbstn/framecraft/actions/runs/43250524759)

1. Open a recording or video. Set its trim and desired zoom, cursor and webcam options. Use **Clip hinzufügen …** in the timeline to append videos or saved single-source FrameCraft projects. A saved project carries its separate recording tracks into the edit. The first clip sets the canvas. Background, framing, aspect ratio and master mute remain adjustable.
2. Scrub to the start of the section to remove and press **Teilen**. Repeat at the end. Select the middle section and choose **Abschnitt entfernen**. Move a selected section with **Nach links** or **Nach rechts**. The curved arrow undoes recent edits during the current session.
3. Choose **Untertitel bearbeiten …** at the desired timeline position. Add the text, enter its start and end in seconds on the original movie and choose its placement or larger type. Cues on the same original may not overlap. Each use of the same source shares its captions. Caption entry is manual and offline.
4. Save the project or export MP4/GIF as usual. An edit references original media ranges. The project folder keeps the original videos, separate webcam files and recording metadata, including material cut from the visible timeline. Share the exported movie when only the edited result should be visible.

Packages using a cut list or captions require the 0.9.0 source build. Existing single-source projects can still be opened. Practical save/reopen, playback and export acceptance is pending.

## Sharing an export

For private tutorial review, export the finished movie and put that file in your own iCloud Drive. In Finder, choose **Share → Collaborate**, invite specific people and set view-only access. You control who receives the invitation. You can stop sharing or delete the cloud file later. A recipient who saved a copy can still use that copy. FrameCraft has no upload service. [Apple's Finder sharing guide](https://support.apple.com/en-gb/guide/mac-help/mchl91854a7a/26/mac/26)

## Cursor shapes

Start a recording as usual. When macOS supplies the system cursor separately, FrameCraft stores its image, logical dimensions and hotspot with the mouse track. Repeated shapes share one image in the project. Text insertion, hand and resize pointers use their recorded hotspots as the position moves. **Gestaltung → Cursor** controls visibility, smoothing and size. New shape tracks start at native size (1×). The preview, MP4 and GIF use the same renderer.

If a particular shape is unavailable during editable capture, FrameCraft uses its arrow for those samples. If macOS cannot supply the separate system cursor at the start of capture, ScreenCaptureKit includes the native cursor in the video for that recording. In this mode click zooms remain available, while the cursor itself is part of the video. Apple documents both the scope of the system cursor API and its deprecation. [System cursor](https://developer.apple.com/documentation/appkit/nscursor/currentsystem) · [Hotspot coordinates](https://developer.apple.com/documentation/appkit/nscursor/hotspot)

Projects containing recorded cursor artwork require FrameCraft 0.8.0 or later. Older projects open with their existing cursor behavior. Live cursor changes and export alignment await functional acceptance.

## Region recording

1. In **Aufnehmen**, open **Quelle** and choose **Bereich · Bildschirm …** for the monitor you want.
2. Click **Bereich auswählen …** and drag a rectangle over the live desktop. The highlighted outline and dimensions show the selection in logical display points. Drag again to replace it, press Return to confirm, or press Escape to cancel.
3. Click **Aufnahme starten**. FrameCraft passes the selected rectangle to the screen recorder. Cursor positions and automatic click zooms use the same rectangle. Points outside it are hidden and clicks there are ignored.

Each selection belongs to one display. Output dimensions use that display’s pixel scale and the existing 3840 × 2160 encoding limit. After capture, edit and export the project as usual. Live region capture and cursor alignment on different display scales are awaiting functional testing.

## Webcam overlay

In **Aufnehmen**, enable **Webcam als Overlay aufnehmen** before starting. On first use, allow camera access when macOS asks. FrameCraft uses the default video camera. The microphone and system audio have separate switches.

After recording, open **Gestaltung → Webcam**. Choose a corner, adjust the circular inset from 12% to 45% of the shorter canvas edge, or hide it. The overlay stays fixed during screen zooms. Preview, MP4 and GIF use the same composition.

The local recording includes a separate silent camera movie. Saving a webcam project copies that movie into the project folder, including when the overlay is hidden. Share an exported video to share only the visible result. Projects with camera media require FrameCraft 0.6.0 or later. This release can also open older projects.

## Features

- Window/display recording, system audio, and optional microphone input; recording can also be stopped from the menu bar.
- Direct zoom timeline editing: drag either edge or the whole interval, use 0.1/0.5-second keyboard steps, and edit overlapping zooms in separate rows.
- Automatic click zooms: new targets replace old ones, with 600 ms camera transitions and no intermediate zoom-out during short gaps.
- Separate cursor track: 0–250 ms smoothing, size, visibility, and click indicators. No keyboard input recording.
- Nondestructive trimming, manual zooms, playback/scrubbing, three aspect ratios, four gradients, frames, and shadows.
- Shared preview/export pipeline; MP4 at HD/Full HD/4K, 24/30/60 fps and three quality levels; short looping GIFs; progress/cancellation and overwrite protection.
- Editable projects with background save/load, staged creation, atomic metadata updates, and compatibility with older projects without cursor tracks.

## Examples and verification

- [Reliability — 0.3.3 measurements and failure tests](docs/Reliability.md), [three-minute recording project](examples/FrameCraft-Langzeittest-0.3.3.framecraft), and [Full HD export](examples/FrameCraft-Langzeittest-0.3.3.mp4).

- [Stable signing update test — 0.3.2 export](examples/FrameCraft-Signaturtest-B.mp4) and [editable project](examples/FrameCraft-Signaturtest-B.framecraft).

- [Permission recovery — version 0.3.1 export](examples/FrameCraft-Freigabetest-0.3.1.mp4) and [editable project](examples/FrameCraft-Freigabetest-0.3.1.framecraft).

- [Smooth zooms — current export](examples/FrameCraft-Sanfte-Zooms.mp4)
- [Click test — version 0.2 export](examples/FrameCraft-Klicktest.mp4)
- [Editable click-test project](examples/FrameCraft-Klicktest.framecraft)
- [Cursor demo](examples/FrameCraft-Cursor-Demo.mp4) and [demo project](examples/FrameCraft-Cursor-Demo.framecraft)
- More original test media and projects are available in [examples](examples).

Live click test: 10.925 seconds, 10 clicks, 590 cursor positions, and six automatic zooms. Full HD/30 fps export without audio; smoothed cursor positions match clicks exactly, and the project was reopened successfully. Version 0.3: 17 tests passed, build/start/signature checks succeeded, and the new camera motion was exported. See [verification status](docs/Build-Status.txt), [test log](docs/verification/tests-0.3.0.txt), [analysis](docs/Analyse.md), [development and usage](docs/Entwicklung.md), and [changelog](CHANGELOG.md).

## Planning and documentation

[Linear project](https://linear.app/mnnsbstn/project/framecraft-00c6db8009c8) · [Development journal](https://linear.app/mnnsbstn/document/framecraft-entwicklungsjournal-prufnachweise-und-roadmap-33f00559e3ba)

All existing and future work, including previously unplanned features, is documented in Linear. [AGENTS.md](AGENTS.md) records the workflow. [docs/Linear.md](docs/Linear.md) and [docs/linear](docs/linear) contain readable and machine-readable snapshots; Linear remains the current planning source. No automatic background synchronization is configured.

**Language policy:** all GitHub documentation is maintained in English. The app, Linear, local German documentation, and user communication remain German. Linear snapshots in this repository are English translations, not verbatim exports. Existing artifact filenames, technical identifiers, URLs, and raw evidence are preserved; German UI labels are quoted where needed to locate a control.

## REA and limitations

REA was set up persistently on the local machine and used for read-only reference inspection. See [setup/reuse](docs/rea/REA-Nutzung.md), [verification evidence](docs/rea), and [reference findings](docs/REA-Befunde.json). Provenance and integrity were checked; this is not a full security audit. The reference app was not executed because of checksum/signature issues and is not included in this repository.

System audio and microphone input passed [live window recording and export checks](docs/Audio-Acceptance.md) on this Mac. Full-display capture has been tested on this Mac with its built-in panel and an external LG in extended mode. Older editable tracks retain the original FrameCraft arrow. Embedded cursors in imported videos cannot be smoothed. Very short zoom intervals may ease out beyond their nominal end.

## Repository contents

Source, tests, local build instructions, documentation, REA evidence, a Linear snapshot, original example projects/videos, and an app archive. Machine-specific paths in published text evidence have been neutralized. Build caches, credentials, and third-party reference binaries are excluded. The [SHA-256 manifest](docs/verification/SHA256SUMS.txt) covers the published files except itself.

## Recording permissions and updates

See [recording permission and update guidance](docs/Recording-Permissions.md) for launch-only mode, safe bundle replacement, and recovery. Version 0.6.0 (build 14) adds optional camera access. The previous functional run on November 8 passed all 44 automated tests. The earlier stable-signing acceptance used a real changed-code update and retained recording permission; recordings before and after the update and a Full HD export passed verification. See the [update test](docs/verification/stable-signing-0.3.2.json).


Stable local signing is configured and verified on this Mac. See [identity setup and update continuity](docs/Signing-Identity.md). Future builds use the saved identity automatically; older app archives remain available as historical artifacts.
