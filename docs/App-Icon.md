# FrameCraft app icon

Current asset: version 0.4.0 (build 10), November 6, 2026. White recolor: [SBSTN-107](https://linear.app/mnnsbstn/issue/SBSTN-107/app-logo-von-gelbgrun-auf-weiss-umstellen). Original icon introduced in 0.3.4. Tracked in [SBSTN-105](https://linear.app/mnnsbstn/issue/SBSTN-105/eigenes-framecraft-app-icon-entwerfen-und-integrieren).

<img src="../Assets/AppIcon.png" width="256" alt="FrameCraft black and white app icon">

## Design and assets

A rounded screen frame and recording dot represent screen capture and composition. The current icon palette is near-black (#08090b base) with **#FFFFFF** white symbols. The user requested replacing the earlier #e5ff42 icon accent; the interface accent remains lime. Generated lighting introduces subtle tonal variation; these are palette references, not a claim that every pixel has the exact hex value. No Screen Studio artwork is used.

- [Master PNG](../Assets/AppIcon.png): 1254 × 1254 pixels, transparent outside the tile.
- [macOS ICNS](../Assets/AppIcon.icns): 16, 32, 128, 256 and 512 point representations at 1× and 2×, ten images in total, up to 1024 physical pixels.
- [Packaged app](../artifacts/FrameCraft-0.4.0-macos-arm64.zip).

## Reuse and packaging

Edit or replace the square master PNG, keeping at least 1024 pixels per side and transparency. Regenerate the standalone resource with `./script/build_icon.sh`. The normal `./script/build_and_run.sh --build` also generates it directly into the staged app's `Contents/Resources/AppIcon.icns`, sets `CFBundleIconFile`, and signs the completed bundle. Quit FrameCraft normally before rebuilding; the existing running-app guard remains active.

The existing bundle identifier, installed app path and persistent local signing identity are retained. No screen permission reset or keychain identity replacement was performed for this update.

## Original 0.3.4 verification

Build and shell syntax checks passed. The ICNS roundtrip contains all ten correctly sized representations. Installed and source icon hashes match. Strict signature validation and mutual previous/current designated-requirement checks passed; the extracted download also passes signature validation and retains executable permissions. The app launches, and its native About panel visibly shows the new icon and version 0.3.4 (8). The 128-pixel representation was also visually inspected.

This update changes assets and packaging only. Runtime Swift sources and tests are unchanged. The prior 29 passing tests and 347.910-second save/reopen/export acceptance remain the functional baseline; neither was rerun for the icon. The build reports existing capture/composition API warnings. See [structured checks](verification/app-icon-0.3.4.json) and [build output](verification/build-0.3.4.txt).

## Generation provenance

Created with the built-in imagegen tool, then recolored with an imagegen edit in response to the user's black/#e5ff42 request. The original generated screen-frame/recording-dot composition was retained; the earlier purple palette was discarded. The final PNG is preserved without retouching. Apple `sips` and `iconutil` create the packaging sizes only. Image generation is nondeterministic; the committed master is the reproducible packaging source.

Final edit prompt (`transparent_background: true`):

```text
Edit this FrameCraft macOS app icon. Preserve the exact composition, rounded-square silhouette, open lower-right screen frame, round recording dot, generous outer transparent margin and overall geometry. Change the palette only, with slightly more restrained materials: tile is deep matte BLACK / near-black charcoal (#08090b base), with subtle neutral black shading and a restrained soft edge bevel. BOTH the screen-frame symbol and recording dot use the user's exact accent color #e5ff42 as their dominant base tone (electric yellow-lime), with only subtle lighting variation. No violet, purple, coral, red, ivory or white symbols remain. No colored glow around the tile. Clear high-contrast premium macOS icon, legible at small sizes. Keep background outside the tile genuinely transparent; preserve alpha, no backdrop or checkerboard. No text, no extra details, no changes to geometry.
```


## White recolor — 0.4.0

The built-in imagegen edit changed the frame and recording dot to white while preserving the black tile and transparent margin. All ten ICNS sizes were regenerated, embedded and signed. The native About panel visibly shows the white icon and Version 0.4.0 (10). See [release verification](verification/timeline-0.4.0.json). The committed master is the packaging source; slight neutral generated shading is retained.

Final edit prompt (`transparent_background: true`, referenced image: the preceding lime PNG):

```text
Edit the attached FrameCraft macOS app icon. Change only the lime/yellow-green screen-frame symbol and circular recording dot from #e5ff42 to neutral WHITE (#FFFFFF). Both symbols should appear clean bright white, with at most subtle neutral gray bevel shading. Remove every yellow or green tint. Preserve the exact original geometry, framing, proportions, black tile, black shading, rounded square silhouette, open lower-right gap, dot location and transparent outer margin. Do not add text or any detail. Keep the black background tile and transparent alpha outside it unchanged.
```
