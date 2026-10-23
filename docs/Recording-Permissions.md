# Recording permission and local updates

## Status (October 24, 2026)

The 0.3.1 source adds permission recovery and safer local updates. This Mac currently has **zero valid code-signing identities**. The development build remains ad hoc signed; persistent screen recording permission across changed builds is **not yet guaranteed**. SBSTN-82 remains open until stable signing and practical update acceptance are complete.

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

Use the same identity consistently. No certificate is created or installed automatically. A failed selected identity does not silently fall back to ad hoc signing. If the existing app has an identity-based signature, an implicit downgrade to ad hoc signing is refused. This is local development support, not a notarized distribution workflow. Signatures do not automatically grant recording permission.

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
- Stable identity signing and permission retention across changed builds remain unverified because no valid identity is available.
- Version 0.3.1 was packaged, strictly signature-verified, installed at the existing path, and launched after the user closed the old app. The previous bundle was preserved in a local backup.
- Live UI verification confirmed the permission-denied notice, disabled source/start controls, and settings button opening the correct macOS pane. The toggle appeared enabled, but ScreenCaptureKit still denied access after a normal launch-only restart. User renewal is pending; no new recording is claimed.
- The 0.3.1 app archive is available under artifacts; the previous 0.3.0 archive is retained.
