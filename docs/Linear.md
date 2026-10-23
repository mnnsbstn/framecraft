# FrameCraft in Linear

Project: [FrameCraft](https://linear.app/mnnsbstn/project/framecraft-00c6db8009c8)

English translation of the October 23, 2026 snapshot: 25 issues, 12 Done and 13 Backlog; five milestones. Read Linear for the current state before starting further work. The subsequent documentation-language task is tracked in [SBSTN-96](https://linear.app/mnnsbstn/issue/SBSTN-96).

All GitHub documentation is maintained in English. The live Linear project and its issues/journal, the app, local German documentation, and user communication remain German. IDs, URLs, and artifact filenames are preserved. The JSON snapshots include translation metadata and retain original source timestamps.

# FrameCraft – Development journal and next steps

English translation of the German Linear journal snapshot from October 23, 2026. Linear remains German. Source timestamps describe the original snapshot, not the translation.

## Goal and current status

Independent macOS app for screen recording, automatic click zooms, smooth cursor movement, and video export. User priorities: recording, zoom, and export. Screen Studio is a functional reference; no third-party assets or program components were copied.

As of October 23, 2026: version 0.3.0 built and launched locally; 17 automated tests passed. The app remains usable on this Mac independently of the chat. Minimum macOS 15; SwiftPM/SwiftUI with Apple frameworks and no third-party package dependencies.

## Development and evidence

### Foundation and version 0.1

REA 6.4.0 configured persistently: provenance and relevant installation paths reviewed; npm SHA-512 and 1,161 files compared. CLI/MCP, 170 tools and 6 prompts, archive analysis, and static JavaScript analysis verified. Official sources: [repository](https://github.com/morluto/rea), [website](https://rea.tools), [npm](https://www.npmjs.com/package/rea-agents). A missing native decompilation provider and failed plist/file test remain documented limitations.

Screen Studio package 4.1.0-5005 inspected read-only: 4,260 nodes, nine ASAR contradictions, and an invalid strict app signature. The reference app was neither run nor installed. Xcode setup and licensing were completed by the user.

Independent native app: ScreenCaptureKit recording, window/display selection, start/stop, menu bar, and error handling; system audio/microphone implemented. Editor with MP4/MOV import, demo, playback, scrubbing, trimming, manual zooms, focus/strength, three formats, four gradients, padding/corners/shadow. Shared preview/export pipeline, 30 fps MP4, progress/cancellation, and overwrite protection. Project folders contain originals and JSON; reopening verified. Silent real window test of 11.885 seconds and portrait demo exported.

### Version 0.2 – Clicks and cursor

Mouse movement and clicks captured only during recording and relative to the selected source; no keyboard input. Cursor rendered separately from the original video, smoothing 0–250 ms, adjustable size/visibility and click indicators. Exact click points despite smoothing; gaps and hidden regions respected. Nearby clicks group zoom intervals; manual changes survive recalculation.

After a rebuild, only the FrameCraft entry had to be renewed in macOS; authorized by the user, with Touch ID/password entered by the user. Remote UI clicks produced no global mouse movement. A real user mouse test therefore followed: 10.925 seconds, 10 clicks, 590 cursor positions (373 visible), six automatic 1.8× zooms. Export: 1920×1080, 30 fps, no audio; frames checked, click positions exact, saved project reopened. 13 tests passed.

### Version 0.3 – Smooth camera motion

A new ordered target sequence prevents returns to older overlapping zooms. Crop width and center are smoothed over 600 ms; new targets preserve continuous movement. Gaps of up to 300 ms connect camera moves; manual zooms have priority. Stateless evaluation gives reproducible preview, timeline jumps, and export.

Four new camera tests, 17 passed in total. Release build, launch, and strict local ad hoc signature verification succeeded. The same live project was loaded through the UI and exported with the new camera motion: 10.925 seconds, Full HD, 30 fps, no audio. Multiple frames decoded and visually inspected. Very short zoom intervals may ease out beyond their nominal end.

## Limitations and next steps

- Recording permission has not been retested after rebuilding 0.3; strengthen the update/signing workflow.
- System audio, microphone input, and full-display recording are implemented but not yet practically validated.
- Check multi-monitor/Retina coordinates, longer recordings, resource use, and failure cases.
- Currently a fixed arrow cursor; burned-in cursors in imported videos cannot be smoothed retroactively.
- No region recording, webcam, multi-clip editing, subtitles, GIF, cloud sharing, or configurable export quality; zoom edges are not draggable yet.
- Additional features are backlog proposals. Dates and implementation are not automatically committed.

## Issue index

- [SBSTN-71: Set up REA persistently and verify provenance](https://linear.app/mnnsbstn/issue/SBSTN-71/rea-dauerhaft-einrichten-und-herkunft-prufen) — Done
- [SBSTN-72: Inspect the Screen Studio reference read-only with REA](https://linear.app/mnnsbstn/issue/SBSTN-72/screen-studio-referenz-mit-rea-lesend-untersuchen) — Done
- [SBSTN-73: Set up the native app, local build environment, and reuse](https://linear.app/mnnsbstn/issue/SBSTN-73/native-app-lokale-build-umgebung-und-wiederverwendung-aufsetzen) — Done
- [SBSTN-74: Implement display and window recording](https://linear.app/mnnsbstn/issue/SBSTN-74/bildschirm-und-fensteraufnahme-implementieren) — Done
- [SBSTN-75: Build the editor with import, preview, trimming, and appearance controls](https://linear.app/mnnsbstn/issue/SBSTN-75/editor-mit-import-vorschau-schnitt-und-gestaltung-bauen) — Done
- [SBSTN-76: Validate the shared preview/export pipeline and MP4 export](https://linear.app/mnnsbstn/issue/SBSTN-76/gemeinsame-vorschau-exportpipeline-und-mp4-export-absichern) — Done
- [SBSTN-77: Save and reopen editable projects](https://linear.app/mnnsbstn/issue/SBSTN-77/editierbare-projekte-speichern-und-wieder-offnen) — Done
- [SBSTN-78: Generate automatic zooms from recorded mouse clicks](https://linear.app/mnnsbstn/issue/SBSTN-78/automatische-zooms-aus-aufgezeichneten-mausklicks-erzeugen) — Done
- [SBSTN-79: Add a separate cursor track, smoothing, and click indicators](https://linear.app/mnnsbstn/issue/SBSTN-79/separate-mausspur-glattung-und-klickmarkierungen-erganzen) — Done
- [SBSTN-80: Renew screen recording permission and validate a real click test](https://linear.app/mnnsbstn/issue/SBSTN-80/bildschirmfreigabe-erneuern-und-echten-klicktest-abnehmen) — Done
- [SBSTN-81: Implement smooth camera motion for rapid click sequences](https://linear.app/mnnsbstn/issue/SBSTN-81/sanfte-kamerafahrten-bei-schnellen-klickfolgen-implementieren) — Done
- [SBSTN-82: Keep screen recording permission reliable across app updates](https://linear.app/mnnsbstn/issue/SBSTN-82/bildschirmfreigabe-bei-app-updates-zuverlassig-erhalten) — Backlog
- [SBSTN-83: Test system audio and microphone input in practice](https://linear.app/mnnsbstn/issue/SBSTN-83/systemton-und-mikrofon-praktisch-testen) — Backlog
- [SBSTN-84: Validate display and multi-monitor recording with cursor coordinates](https://linear.app/mnnsbstn/issue/SBSTN-84/display-und-mehrmonitoraufnahme-samt-mauskoordinaten-abnehmen) — Backlog
- [SBSTN-85: Test stability with long recordings and failure cases](https://linear.app/mnnsbstn/issue/SBSTN-85/lange-aufnahmen-und-fehlerfalle-auf-stabilitat-prufen) — Backlog
- [SBSTN-86: Edit zoom intervals directly in the timeline](https://linear.app/mnnsbstn/issue/SBSTN-86/zoomintervalle-direkt-in-der-zeitleiste-bearbeiten) — Backlog
- [SBSTN-87: Add export options for quality, resolution, and GIF](https://linear.app/mnnsbstn/issue/SBSTN-87/exportoptionen-fur-qualitat-auflosung-und-gif-erganzen) — Backlog
- [SBSTN-88: Add region recording](https://linear.app/mnnsbstn/issue/SBSTN-88/bereichsaufnahme-erganzen) — Backlog
- [SBSTN-89: Support changing cursor shapes](https://linear.app/mnnsbstn/issue/SBSTN-89/wechselnde-cursorformen-unterstutzen) — Backlog
- [SBSTN-90: Add webcam composition](https://linear.app/mnnsbstn/issue/SBSTN-90/webcam-komposition-erganzen) — Backlog
- [SBSTN-91: Add multi-clip editing and internal cuts](https://linear.app/mnnsbstn/issue/SBSTN-91/mehrclip-schnitt-und-innere-schnitte-erganzen) — Backlog
- [SBSTN-92: Add subtitles](https://linear.app/mnnsbstn/issue/SBSTN-92/untertitel-erganzen) — Backlog
- [SBSTN-93: Evaluate cloud sharing as an optional extension](https://linear.app/mnnsbstn/issue/SBSTN-93/cloud-sharing-als-optionale-erweiterung-bewerten) — Backlog
- [SBSTN-94: Complete optional REA analysis capabilities](https://linear.app/mnnsbstn/issue/SBSTN-94/optionale-rea-analysearten-vervollstandigen) — Backlog
- [SBSTN-95: Publish source, documentation, and verification data to GitHub](https://linear.app/mnnsbstn/issue/SBSTN-95/quellcode-dokumentation-und-prufdaten-in-github-veroffentlichen) — Done

## Reuse and local evidence

The local project is under `outputs/FrameCraft` in the Codex workspace. Start `dist/FrameCraft.app`; build/test through `script/build_and_run.sh`. Local ad hoc signing, no public notarization.

Important files in the original output folder:

- `FrameCraft-App.zip`, `FrameCraft-Quellprojekt.zip`
- `FrameCraft-Klicktest.framecraft` (original, clicks, cursor, six zooms)
- `FrameCraft-Klicktest.mp4` (version 0.2) and `FrameCraft-Sanfte-Zooms.mp4` (version 0.3)
- `FrameCraft-Cursor-Demo.mp4/.framecraft` and earlier demo/recording test files
- `FrameCraft/README.md`, `FrameCraft/docs/Build-Status.txt`, `FrameCraft/docs/Analyse.md`
- `REA-Nutzung.md` and REA verification evidence

These references identify local files, not attachments uploaded to Linear.

## Required ongoing documentation

The user explicitly requested that previously unplanned features and all other new steps be documented carefully here too.

1. Before each new FrameCraft task, search the project for a matching issue; update it or create a new one. Include fixes, technical changes, research, and tests.
2. Record the goal, reason, scope, and verifiable acceptance criteria. Distinguish ideas from authorized implementation.
3. Set work to In Progress when starting; record decisions and material limitations as things change.
4. After implementation, document actual results, version, relevant tests, artifacts, and remaining risks. Mark Done only when acceptance criteria are met; otherwise record open work explicitly.
5. Update the journal and project summary for relevant releases or scope changes. Add unknown future work when it arises; do not claim completeness for requirements not yet known.
6. If Linear access is temporarily unavailable, record progress locally and submit pending updates once access returns. Do not claim synchronization before verifying it.

The rule is also recorded in the local project. No automatic background monitoring is configured; maintenance happens during subsequent work.

## GitHub publication — October 23, 2026

[FrameCraft repository](https://github.com/mnnsbstn/framecraft), branch main. [SBSTN-95](https://linear.app/mnnsbstn/issue/SBSTN-95) completed. At this snapshot: 25 documented issues, 12 Done and 13 Backlog.

[First complete project revision](https://github.com/mnnsbstn/framecraft/commit/19297da23cfb5075f2297ef1694ce30c2a99770f): source, tests, build instructions, development documentation, REA evidence, original example projects/videos, and the 0.3.0 app archive. The remote tree of 55 files was checked after pushing. Sources and tests match the tested local state; app archive integrity checked, SHA-256 manifest included. No build caches, credentials, or third-party reference binaries; personal machine paths in text evidence were neutralized.

GitHub contains a snapshot of the project, issues, and journal under docs/linear. Linear remains the current planning source. Further features, fixes, tests, and decisions are documented during the relevant work; no automatic background synchronization. The original example media referred to above as local files are also in GitHub under examples, and the app under artifacts. They were not uploaded as Linear attachments.

## Current development follow-up — October 24, 2026

[SBSTN-82](https://linear.app/mnnsbstn/issue/SBSTN-82) is now In Progress. Version 0.3.1 source adds permission recovery and safer local updates; 20 tests and release compilation pass. Installing the new bundle and live UI checks await closure of the running app. Stable signing remains unavailable. See [implementation and verification](Recording-Permissions.md). The older translated snapshot above is retained as historical context.
