# Changelog

## Documentation — October 26, 2026

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
