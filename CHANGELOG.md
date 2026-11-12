# Changelog

## 0.9.0 source — November 12, 2026

- Append movies and saved single-source projects to a timeline. Split at the playhead, remove an interior section, move sections and undo edits.
- Preserve original source time for zooms, pointer artwork and movement, captions, webcam and audio through edits. Save the sources alongside the project manifest.
- Add editable offline captions with timing, placement and size. Preview and MP4/GIF export use the same caption renderer.
- Document user-controlled iCloud sharing of finished exports. Functional acceptance remains deferred.

## 0.8.0 — November 12, 2026

- Capture system cursor artwork and hotspots with the editable pointer track. Apply shape changes at the recorded timestamps in preview, MP4 and GIF.
- Fall back to a single embedded native cursor if separate system cursor capture is unavailable at recording start.

## 0.7.0 — November 12, 2026

- Drag to select and preview a capture region on a single display, then confirm with Return. ScreenCaptureKit captures the selected rectangle. Cursor positions and click zooms use region-relative coordinates.

## 0.6.0 — November 12, 2026

- Add optional local webcam capture. Edit visibility, corner and size independently of screen zooms. Camera frames use the screen recording’s host clock for alignment.
- Include camera media when saving a project. Render the overlay through the shared preview, MP4 and GIF pipeline.

## 0.5.1 — November 8, 2026

- Use native mouse-down locations for click zooms and retain counter sampling as a fallback when no native mouse-down events arrive.
- Resolve inspector edits by zoom ID so a project change or zoom deletion can safely retire old slider bindings.
- Verify two full-display recordings against independent click markers and HD exports. [Display acceptance](docs/Display-Acceptance.md)

## November 8, 2026 — Audio acceptance on 0.5.0

- Verify live window recordings with system audio alone, microphone alone, and both together. Check saved projects, audible and muted MP4s, sync, levels, permission denial and local listening. [Results](docs/Audio-Acceptance.md)

## 0.5.0 — November 6, 2026

- Add export settings for MP4 resolution (HD/Full HD/4K), frame rate (24/30/60 fps) and three bitrate-based quality levels with an estimated file size.
- Add silent looping GIF export for clips up to ten seconds, at 480/720-pixel long edge and 10/20 fps.
- Preserve trim, styling, zooms and cursor rendering in both formats; mix available audio for MP4 or omit it when muted.
- Isolate encoder temporary files and retain cancellation, overwrite protection and recovery. All 40 tests pass, including synthetic audio, configured MP4 and GIF output. See [export options](docs/Export-Options.md).

## 0.4.0 — November 6, 2026

- Edit zoom boundaries and move whole intervals directly in the timeline, with live timing, keyboard/accessibility controls and separate rows for overlaps.
- Clamp edits to valid video bounds and retain manual changes through automatic regeneration and project storage.
- Change the app icon symbols from #e5ff42 to #FFFFFF, preserving the black tile and lime interface.
- Pass 35 tests; verify drag/keyboard input, project save/reopen, six-second Full HD export (180 decoded frames), icon display and stable signing. See [timeline editing](docs/Timeline-Editing.md).

## 0.3.5 — November 6, 2026

- Match the interface to the app icon with near-black surfaces and the shared #e5ff42 accent.
- Style primary actions, disabled states, welcome view, timeline selections, inspector and recording sheet with readable contrast.
- Keep media palettes and semantic recording/error colors independent of the interface theme.
- Pass all 29 existing tests; verify main UI states, source access after update, stable signing and the extracted app archive. See [interface theme](docs/Interface-Theme.md).

## 0.3.4 — November 6, 2026

- Add an original black and #e5ff42 screen-frame/recording-dot app icon.
- Generate all macOS icon sizes from the committed PNG and embed the ICNS before signing.
- Verify the installed About panel, archive contents and unchanged signing identity. No runtime behavior changes; previous functional acceptance remains the baseline. See [icon documentation](docs/App-Icon.md).

## Documentation — October 26, 2026

- Complete the full five-minute repeat: 347.910-second silent recording, project save/reopen, unchanged original media and complete Full HD export. Publish resource samples and sequential/exact-seek decode counterchecks; close SBSTN-85 for the documented scope.

- Record user confirmation that the three-minute recording was manually stopped. The unexplained-stop concern is resolved; the five-minute endurance trial remains outstanding. No app code or binary changes.

## 0.3.3 — October 24, 2026

- Move large project encoding/decoding and media copies off the UI actor, with a saving indicator.
- Stage new projects, update metadata atomically, and preserve originals/previous saves on failure.
- Modernize export completion/progress and propagate both explicit and parent-task cancellation.
- Explain nested full-disk errors and verify failure recovery without filling the user disk.
- Pass 29 tests, including a one-hour synthetic cursor track; verify a three-minute silent window recording and Full HD export with resource measurements. See [reliability evidence](docs/Reliability.md).

## 0.3.2 — October 24, 2026

- Persist a local signing identity in the user keychain and reuse its certificate selector across builds.
- Refuse silent ad hoc fallback, require an explicit initial migration, and validate old/new signing requirements before replacing the app.
- Add native regression checks for changed executables, same-identifier impostors, and tampering.
- Verify recording permission across builds 5 and 6 with changed executable code, with no permission changes between builds; save original test projects and a Full HD export.
- Add a version/build tooltip for diagnostics. All 20 app tests and native signing counterchecks pass.

## 0.3.1 — October 24, 2026

- Add specific screen permission recovery, a settings link, and source refresh on return.
- Clear stale sources after failed refresh; reject duplicate refreshes and recording starts during refresh.
- Add launch-only and signing-diagnostic modes, optional explicit signing identity, verified staging, recoverable backups, and protection against replacing a running app.
- Pass 20 tests; stable signing and permission retention across changed builds remain open.

## Documentation — October 23, 2026

- Translate all GitHub documentation and narrative fields in Linear snapshots into English.
- Establish an English documentation policy for future repository changes; keep the app, Linear, local German documentation, and user communication in German.
- Preserve source code, tests, build scripts, media, evidence identifiers, and existing artifact paths.

## 0.3.0 — October 23, 2026

- Use ordered camera targets instead of blending all active zooms; prevent returns to outdated targets.
- Smooth transitions over 600 ms while preserving continuous motion during retargeting; bridge gaps of up to 300 ms.
- Preserve manual zoom priority and deterministic evaluation for preview, scrubbing, and export.
- Add four camera tests, bringing the total to 17 passing tests; re-export the real click recording.

## 0.2.0 — October 23, 2026

- Add click capture, automatic zooms, a separate cursor track, and cursor smoothing.
- Add cursor size/visibility and click indicators, persistence, and compatibility with older projects.
- Add six tests, bringing the total to 13 passing tests. Complete a real user mouse test and export.
- Renew only FrameCraft's screen recording permission after the ad hoc rebuild.

## 0.1 — October 23, 2026

- Implement the native recording/editor app, import/demo, manual zooms, trimming, and appearance controls.
- Add the shared preview/MP4 pipeline, project persistence, and local app packaging.
- Pass seven tests and verify demo output and a real window recording without audio.
- Verify the REA installation/integrity and inspect the official reference package read-only.

## Project organization

- Create a Linear project with a development journal, completed work, and an ideas backlog.
- Publish source code, evidence, and original example data in mnnsbstn/framecraft.
