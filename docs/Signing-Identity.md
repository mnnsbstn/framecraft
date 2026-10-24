# Stable local signing

The local identity binds updates to the same private key and bundle identifier. It addresses permission loss caused by changing ad hoc identities; it does not promise that macOS will never request consent again.

## One-time setup

Run `python3 script/setup-local-signing.py`. The script creates or reuses **FrameCraft Local Development** in the user default keychain, permits the system codesign tool, and verifies a real signature before writing its public SHA-1 certificate selector to `~/Library/Application Support/FrameCraft/Signing/identity.sha1`. It creates no system trust override. SHA-1 here is a certificate selector used by codesign; the certificate itself is signed with SHA-256 and has a 3072-bit RSA key. Temporary encrypted key/export files are removed when setup exits.

If macOS asks codesign to access this key, complete that authentication yourself. Choose Always Allow only for the expected codesign / FrameCraft Local Development prompt to permit future builds. Do not share your login password with an agent. A cancelled prompt fails setup without replacing the app. Running setup again reuses the certificate; it does not rotate it.

This certificate is for local development. It is not a Developer ID identity and is not a notarized public distribution signature. No trusted-root or Gatekeeper override is required by this workflow.

## Migration and updates

Save your project, stop capture/export, and quit FrameCraft. For the one-time transition from the old ad hoc build, use `FRAMECRAFT_MIGRATE_ADHOC=1 ./script/build_and_run.sh --build`. Approve screen recording for the new identity yourself if macOS requires it. The old ad hoc authorization is not expected to transfer to a different identity.

Later, use the normal build script. It automatically selects the stored identity, verifies the new bundle, checks that old and new designated requirements accept each other, and only then replaces the stopped app with a recoverable backup. Signing failure, unavailable keys, identity changes, or an attempted downgrade fail before replacement. Existing-launch mode does not rebuild or re-sign. An explicit FRAMECRAFT_SIGNING_IDENTITY remains available for a properly configured identity; it does not bypass compatibility checks.

Keep this key and certificate. Do not regenerate them for each build. Deleting the key prevents signing future matching updates. Use Keychain Access to make an encrypted private backup yourself if desired; never commit or upload a private key, PKCS#12 export, or its password. Moving to another Mac, rotating the certificate, expiry, changing bundle identity, and macOS policy changes require separate validation. The local certificate is valid for ten years; plan renewal before expiry.

## Verification

`python3 script/verify-signing-continuity.py` compiles two different small executables, signs them with the saved identity, and verifies mutual requirements. It also checks rejection of an ad hoc impostor with the same identifier and a tampered executable. These native signing checks do not replace the real two-build ScreenCaptureKit acceptance test.

Version 0.3.2 builds 5 and 6 passed the real changed-code update test on this Mac. See [recorded evidence](verification/stable-signing-0.3.2.json). Never infer permanent permission solely from a matching certificate or a successful ordinary restart.

## Sources

- [Apple TN3127: Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
- [Apple TN2206: macOS Code Signing In Depth](https://developer.apple.com/library/archive/technotes/tn2206/)
- [Apple Code Signing Tasks](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html)

A self-signed identity may be listed as untrusted by `security find-identity -v`; that list tests certificate authority trust, not whether this key can produce a valid identity-bound local signature. Do not add broad trust overrides to change that display. The setup probe, strict signature verification, mutual requirements and actual capture test are the relevant checks here.
