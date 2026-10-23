# FrameCraft

An independent native macOS app for screen recording, automatic click zooms, smooth cursor movement, and MP4 export. Inspired by the Screen Studio workflow, with its own interface, implementation, and test media.

**Status: 0.3.0 · macOS 15+ · 17 tests passed.** Developed on Apple Silicon with Swift 6.4. Recording was tested on this Mac in version 0.2; version 0.3 exported the same recording. This is not a complete Screen Studio replica.

## Getting started

- [Download the local Apple Silicon build 0.3.0](artifacts/FrameCraft-0.3.0-macos-arm64.zip), extract it, and open FrameCraft.app. The build is locally ad hoc signed, without Developer ID signing or public notarization.
- Alternatively, build from source with a configured Xcode installation:

```sh
git clone https://github.com/mnnsbstn/framecraft.git
cd framecraft
./script/build_and_run.sh --test
./script/build_and_run.sh --verify
```

The app is created at `dist/FrameCraft.app`. If the app is already running, the script asks you to quit it normally to avoid losing a recording. Other options: `--build`, `--logs`, `--debug`.

For a new recording, allow FrameCraft in macOS System Settings → Privacy & Security → Screen & System Audio Recording. Microphone access is required only when microphone recording is enabled. A local rebuild may require permission to be granted again; a new recording has not yet been tested after rebuilding version 0.3.

## Using the app

The app interface remains German. The English instructions below refer to these existing controls.

1. Choose **Record** (`Aufnehmen`) and select a window or display; alternatively, import a video or load the demo.
2. Stop recording to generate click zooms automatically. Under **Zoom & Trim** (`Zoom & Schnitt`), edit focus, zoom strength, and timing.
3. Under **Appearance** (`Gestaltung`), adjust the format, background, frame, and cursor.
4. Press **⌘S** to save a `.framecraft` project; **Export video** (`Video exportieren`) creates an MP4.
5. To resume editing, select the entire project folder using **Open project** (`Projekt öffnen`). Keep the original video and JSON together.

## Features

- Window/display recording, system audio, and optional microphone input; recording can also be stopped from the menu bar.
- Automatic click zooms: new targets replace old ones, with 600 ms camera transitions and no intermediate zoom-out during short gaps.
- Separate cursor track: 0–250 ms smoothing, size, visibility, and click indicators. No keyboard input recording.
- Nondestructive trimming, manual zooms, playback/scrubbing, three aspect ratios, four gradients, frames, and shadows.
- Shared preview/export pipeline, 30 fps MP4 output, progress/cancellation, and overwrite protection.
- Editable projects, including compatibility with older projects without cursor tracks.

## Examples and verification

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

System audio, microphone input, and full-display recording have not yet been practically validated. The cursor currently uses a fixed arrow shape; cursors embedded in imported videos cannot be smoothed. Region recording, webcam overlays, multi-clip editing, subtitles, GIF, cloud sharing, configurable export quality, and draggable zoom edges are in the ideas backlog. Very short zoom intervals may ease out beyond their nominal end.

## Repository contents

Source, tests, local build instructions, documentation, REA evidence, a Linear snapshot, original example projects/videos, and an app archive. Machine-specific paths in published text evidence have been neutralized. Build caches, credentials, and third-party reference binaries are excluded. The [SHA-256 manifest](docs/verification/SHA256SUMS.txt) covers the published files except itself.

## Recording permissions and updates

See [recording permission and update guidance](docs/Recording-Permissions.md) for launch-only mode, safe bundle replacement, and recovery. Version 0.3.1 source passes 20 tests; stable signing remains open.
