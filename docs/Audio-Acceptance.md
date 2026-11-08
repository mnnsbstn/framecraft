# System and microphone audio in FrameCraft 0.5.0

On November 8, 2026, FrameCraft build 11 recorded system audio, microphone audio, and both together on this Mac running macOS 27.2. The user listened to the exported mixed recording through speakers and confirmed clear speech, audible test tones and no distracting echo.

| Capture mode | Recorded duration | Peak in the recording | Peak in the MP4 | Audio lead over the picture in the MP4 |
| --- | ---: | ---: | ---: | ---: |
| System audio only | 37.09 s | −18.18 dBFS | −18.17 dBFS | 13–47 ms |
| Microphone only | 62.10 s | −17.07 dBFS | −17.09 dBFS | Speech with a paused picture |
| System audio and microphone | 43.34 s | −14.88 dBFS | −14.89 dBFS | 13–47 ms |

Each recording and audible export contained one 48 kHz stereo track. Decoding found zero near-clipped audio frames and continuous audio timestamps. All three muted MP4s contained zero audio tracks. The [machine-readable measurements](verification/audio-acceptance-2026-11-08.json) include per-marker offsets and decoded frame counts.

## Repeating the check

1. Open the test video in QuickTime Player. It shows a central white rectangle for 400 ms at 2, 6, 10, 14 and 18 seconds, accompanied by an 880 Hz tone. The reference file had 600 video frames and no measured offset between the five markers and tones.
2. In FrameCraft, select the QuickTime window. Record the playing video with only system audio enabled. Record a spoken phrase with only the microphone enabled and QuickTime paused. Then record the playing video and the spoken phrase together.
3. Save each project. Reopen it and export an MP4 with and without audio. For this check, the export used HD at 30 fps and trimmed half a second from each end. The SHA-256 digests of the original media, saved copy and reopened project copy matched in all three modes. The combined project also reopened in the installed editor.
4. Listen to the mixed export on the intended output device. Check the level of the narration against the playback and listen for a delayed second copy of the sound.

The marker analysis used 10 ms audio windows and the decoded video timestamps. In the original recordings the five tones led the picture by 13–23 ms for system audio and 5–20 ms for combined audio. The 30 fps export quantizes the visual onset to a frame. Speech clarity and echo were judged by ear on this setup. These short captures measure sync over the 20-second stimulus, without establishing long-session drift or results for other devices.

## Permission denial

A separate test application ran the same production capture service with an isolated bundle identifier and a placeholder source. The first attempt received microphone authorization. Disabling microphone access for that helper in System Settings produced an actual denied status. The service displayed recovery instructions, returned to idle, created no file, and accepted another start attempt after the microphone option was disabled. The retry reached source validation. The installed FrameCraft retained its microphone permission.

The local test projects and recordings contain the user's voice. The published evidence consists of measurements. The checks exercised the existing release binary and production project and export services.
