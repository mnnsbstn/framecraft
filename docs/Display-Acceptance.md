# Two-display recording acceptance

On November 8, 2026, FrameCraft recorded each whole display on one Apple Silicon Mac with an extended desktop. The LG sat to the right of the internal display, with its top edge 108 logical points higher. System audio and the microphone were off.

| Selected source | Logical size | Capture size | A/B/C zooms | Largest HD click-marker error | Clicks checked on the other display |
| --- | --- | --- | --- | --- | --- |
| External LG HDR 4K | 2560 × 1440 at 2× | 3840 × 2160 | 3 of 3 | 0.73 px | 3 |
| Built-in display | 2048 × 1332 at 1× | 2048 × 1332 | 3 of 3 | 0.67 px | 4 |

The six zoom centers in the saved projects matched the independently logged mouse-down coordinates. At each sampled target the camera reached 1.8×. In three frames per monitor, the white cursor outline passed within 0.54 HD pixels of the projected click. For all seven off-display events, the saved cursor was hidden and there was no corresponding click. At those times an export with the cursor enabled matched the cursor-disabled control pixel for pixel.

## Method

1. Use a separate test app with a different colored board on each display. Its native mouse-down handler records the clicked location relative to its own window and flashes an orange disk at that point.
2. Select one display in FrameCraft, turn off audio, record A/B/C on the selected display and click the other display. Repeat in the other direction. Save each editable project.
3. Match the board log to the saved click times and positions. Export the section containing the clicks with FrameCraft’s HD MP4 exporter, then export a control with the cursor disabled.
4. Decode source and output frames near each click. Compare the center of the orange disk to the click projected into the exported crop. Compare the white arrow outline against the control and inspect the decoded frames during off-display events.
5. Sample source frames around each mouse-down. The first sampled lit frame appeared 21–111 ms after the event across the six targets. This includes the board redraw, screen capture, and sampling interval. It is a measurement of visible feedback, not isolated input latency.

The internal project contained nine additional clicks outside the six-target sequence. The table covers the independently observed board hits. Measurements are from LG build 12 and internal build 13. Build 13 adds the inspector fix below and uses the same capture and rendering implementation as build 12.

## Fixes found during testing

In 0.5.0, a delayed mouse-button counter update could duplicate a native mouse-down at a later pointer location. This sometimes moved the automatic zoom away from the clicked target. Version 0.5.1 uses the native event location and time, updates window geometry for that click, and uses counter samples only when no native down events arrived during the session.

Switching from a saved project with zooms to a new recording also exposed a crash in the zoom inspector. Build 13 resolves the edited zoom by ID on every control read and write. A stale binding returns its last displayed value and ignores writes after its zoom disappears. The change was exercised by opening the saved LG project, recording the internal display, then saving the new project. All 44 automated tests passed.

[Per-target measurements](verification/display-acceptance-0.5.1.json) · [Automated test results](verification/tests-0.5.1.txt)

## Window movement and overlap

These are separate from whole-display acquisition. The fixture logged physical clicks on a titled test window on both displays, followed by a click on an overlapping window. The first saved window clip ended at 27.09 seconds, before those logged clicks. A second clip lasted 300.55 seconds. Its two remotely driven fixture clicks produced no visible cursor samples in FrameCraft, so it cannot establish accuracy after a window move. The cause of the first early end was not established. SBSTN-84 remains open for a time-aligned physical window replay and an unambiguous visual comparison of FrameCraft's own foreground window against the captured background.

The full-display result applies to this extended arrangement and its two scale settings. Mirroring, hot-plugging a monitor mid-recording, and other physical layouts were outside the run. The full-screen test projects, frame extracts and clips are local. Only the measurements are included here.
