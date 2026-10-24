# Recording permission and local updates

## Status (October 24, 2026)

Version 0.3.2 uses a persistent local self-signed identity and has passed a real changed-code update test: recording works before and after the update without another permission change. SBSTN-82 is complete for this local workflow. See [stable identity setup](Signing-Identity.md) and the acceptance record below. Earlier 0.3.1 notes describe the historical ad hoc state.

## Starting an existing build

Open `dist/FrameCraft.app`, or run:

```sh
./script/build_and_run.sh --launch
```

This verifies the existing signature and opens that bundle without compiling, replacing files, or signing again. It also works while FrameCraft is already running. To inspect signing without changing permissions:

```sh
./script/build_and_run.sh --diagnose
```

The default script action still builds and launches for development. `--build` only builds, and `--test` runs tests. Close FrameCraft after stopping recordings/exports and saving edits before rebuilding. All bundle-replacement modes now refuse to proceed while any FrameCraft process is running; a failed process query also aborts safely.

## Updating safely

A build is packaged and signed in a temporary directory first. Only after strict signature verification and another running-process check is the existing app moved into a recoverable `dist/.framecraft-backup.*/FrameCraft.app` folder and the new bundle installed at the same path. Signing failure leaves the previous app untouched; installation failure attempts to restore it. Backups remain local and are excluded from Git.

When a suitable existing identity is configured, explicitly select it:

```sh
FRAMECRAFT_SIGNING_IDENTITY="<your existing code-signing identity>" ./script/build_and_run.sh --build
```

Use the same identity consistently. The build script itself does not create certificates. The explicitly invoked setup helper creates/reuses a local identity as described in the stable identity guide. A failed selected identity does not silently fall back to ad hoc signing. If the existing app has an identity-based signature, an implicit downgrade to ad hoc signing is refused. This is local development support, not a notarized distribution workflow. Signatures do not automatically grant recording permission.

Apple explains that ad hoc designated requirements are specific to a code version, which prevents reliable identity tracking across changes: [TN3127: Inside Code Signing: Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements).

## Recovering screen recording access

The German recording sheet now distinguishes a denied ScreenCaptureKit request from other failures. For denial it shows **Bildschirmzugriff erforderlich**, **Systemeinstellungen öffnen**, and **Erneut prüfen**. The settings button opens the relevant macOS pane; it does not toggle permission or reset privacy data.

1. Open the recording sheet and follow the permission notice if shown.
2. In macOS, allow FrameCraft under Privacy & Security → Screen & System Audio Recording yourself.
3. Return to FrameCraft: sources refresh automatically, or choose **Erneut prüfen**.
4. If macOS requires a restart, save the project, quit normally, and reopen the existing app with `--launch` or Finder.

Failed source refreshes clear stale sources, selection, and cached capture content. Duplicate refreshes and recording starts during refresh are rejected. A denied permission cannot leave an old source enabled. Generic enumeration errors keep their actual error details instead of always being described as a permission problem.

Source enumeration uses Apple's [SCShareableContent API](https://developer.apple.com/documentation/screencapturekit/scshareablecontent/getexcludingdesktopwindows(_:onscreenwindowsonly:completionhandler:)). The screen settings URL has a manual-navigation fallback if macOS cannot open it.

## Verification

- 20 automated tests passed, including three new regressions for denied access clearing stale selection, other errors with the same numeric code, and concurrent refresh/start rejection.
- Existing video-export tests passed.
- Launch-only mode preserved every existing app bundle file byte for byte.
- `--build` refused a running app and preserved every existing bundle file.
- In 0.3.1, stable signing and changed-build retention were unverified. The 0.3.2 acceptance below supersedes that limitation for this Mac.
- Version 0.3.1 was packaged, strictly signature-verified, installed at the existing path, and launched after the user closed the old app. The previous bundle was preserved in a local backup.
- Live UI verification confirmed the permission-denied notice, disabled source/start controls, and settings button opening the correct macOS pane. The toggle appeared enabled, but ScreenCaptureKit still denied access after a normal launch-only restart. This was the initial denied state; recovery and a new recording are confirmed in the later verification below.
- The 0.3.1 app archive is available under artifacts; the previous 0.3.0 archive is retained.

## Follow-up diagnosis after user renewal — October 24, 2026

Source enumeration remained denied after normal launch-only restarts. The macOS privacy log explicitly reported a screen-capture code requirement mismatch: stored hash `641a69363d57c5da509cd6d6f6b68b8ccacf6c60`, installed hash `8f556a977cb9bc1f21f737963e0f756f9d368357`. The running process uses the expected app path.

The previously authorized renewal was limited to `tccutil reset ScreenCapture local.sebastian.FrameCraft`; it reported success. No other privacy service or app was reset. The unchanged app was reopened. At that stage, access was unconfirmed and UI work stopped because the Mac became locked. The subsequent successful check after manual unlock is recorded below; no additional reset was needed.

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
