# Changelog

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
