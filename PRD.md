# PRD: Sound Pad 3000

App iOS/iPadOS: soundboard de 8 pads. SwiftUI. Um layout. UI em inglês.

## Problem Statement

Quero um board no telefone com oito botões. Cada um toca um som que eu escolhi ou gravei. Quero ver o som sair no pad (barras). Quero nomear cada pad. Não quero mixer, nuvem, nem várias telas.

## Solution

Uma tela. Header laranja (título, subtítulo, speaker). Abaixo, grade 2×4 de pads. Tap toca. Long press edita. Speaker do header para tudo. Os pads e os arquivos ficam no aparelho.

O primeiro launch vem vazio. Sem sample de fábrica.

## User Stories

1. As a user, I want eight pads on one screen, so that I can trigger sounds without navigating.
2. As a user, I want a tap on a pad with audio to play that sound from the start, so that I get a one-shot stinger.
3. As a user, I want a second tap on the same pad to restart the sound, so that I can retrigger without waiting.
4. As a user, I want several pads to play at once, so that I can layer sounds.
5. As a user, I want a tap on an empty pad to do nothing (no sound, no haptic), so that I am not lied to.
6. As a first-time user, I want all eight pads empty, so that the board is mine from the start.
7. As a user, I want each pad to show its number, so that I can tell them apart before they have names.
8. As a user, I want a named pad to show that name, so that I know what I will trigger.
9. As a user, I want a blank name to show only the number, so that I am not stuck with a fake label.
10. As a user, I want lit meter bars on a playing pad to follow real level (peak/RMS), so that I can see the envelope.
11. As a user, I want idle pads to keep their bars dim, so that only the sounding pad reads as live.
12. As a user, I want a short press scale on touch down, so that I feel the hit separate from the meter.
13. As a user, I want a light haptic only when a pad with audio is tapped, so that play is confirmed.
14. As a user, I want a long press on a pad to open a native sheet, so that I can edit that pad.
15. As a user, I want the sheet to stop all playback when it opens, so that edit mode is quiet and recordings stay clean.
16. As a user, I want a text field for the pad name in the sheet, so that I can label the sound.
17. As a user, I want to pick an audio file from Files, so that I can load a sound I already have.
18. As a user, I want the app to copy that file into its sandbox, so that the pad still works if I delete the original.
19. As a user, I want unsupported or unplayable files to show a native alert and leave the pad unchanged, so that I do not brick a slot.
20. As a user, I want imports larger than 25 MB rejected with a native alert, so that the app does not eat disk.
21. As a user, I want imported files of any duration (under the size cap), so that I am not limited to 15 s on files I already own.
22. As a user, I want to record up to 15 seconds from the sheet, so that I can make a custom take.
23. As a user, I want the mic permission prompt only when I tap Record, so that first launch is not a permission wall.
24. As a user, I want recording to keep working as “pick a file” if I deny the mic, with an alert and a path to Settings, so that the rest of the app still works.
25. As a user, I want a timer while recording, so that I know how much of the 15 s I have used.
26. As a user, I want recording to stop at 15 s automatically, so that I cannot overrun.
27. As a user, I want the new recording applied only when I confirm the sheet, so that Cancel leaves the pad as it was.
28. As a user, I want to replace an existing sound (file or new recording), so that I can update a pad.
29. As a user, I want to remove audio from a pad that already has one, so that it goes back to empty.
30. As a user, I want Cancel on the sheet to discard name and audio changes, so that I can abort.
31. As a user, I want Confirm to persist name and audio, so that the pad updates on the board.
32. As a user, I want pads to survive killing the app, so that I do not rebuild the board every time.
33. As a user, I want a tap on the header speaker to stop all sounds, so that a long import does not run until it ends.
34. As a user, I want leaving the app or locking the phone to stop all sounds, so that the board is not a background player.
35. As a user, I want a phone call or other audio interruption to stop all sounds and not resume, so that one-shots do not continue under a call.
36. As a user, I want system volume to control loudness, so that I do not manage eight faders.
37. As a user, I want the same 2×4 layout on iPhone and iPad, portrait locked, so that there is one board to learn.
38. As a user, I want the header to show “Sound Pad 3000” and “Your custom sound board”, so that the product matches the mock.
39. As a user, I want Geist in the header and a mono font on the pads, so that the board matches the mock.
40. As a VoiceOver user, I want each pad announced with number, name, and whether it has audio, so that I can play without seeing the grid.
41. As a developer, I want a unit test target that I run with Product → Test, so that pad storage and the audio engine stay honest without UI tests.

## Implementation Decisions

- SwiftUI only. One root screen: header + 2×4 grid. No other tabs, no other windows.
- Native SwiftUI sheet for pad edit. Fields: name, Record, Choose File, Remove (if the pad has audio), Cancel, Confirm.
- Long press opens the sheet. Tap never opens it.
- Playback is one-shot. Same pad tap restarts. Different pads overlap. Empty pad: no play, no haptic.
- Opening the edit sheet calls the same stop-all as the header speaker.
- Header speaker is a control: tap stops all playback. It is not a standing mute.
- Portrait locked. iPhone and iPad. Same grid, larger pads on iPad.
- UI copy in English. No String Catalog / localization in this version.
- System volume only. No per-pad gain.
- No background audio mode. Resign active / background: stop all.
- Audio interruption: stop all, do not resume.
- Recordings cap at 15 seconds. Imports cap at 25 MB, any duration. Formats: m4a, mp3, wav, aac, caf. Document picker (Files) only. No Photos picker.
- Chosen or recorded audio is copied into the app sandbox. The pad stores a stable local reference, not the original Files URL.
- Persistence on device only. Eight pad records: index, name, optional local file. No iCloud.
- Metering is real level from the playing signal, mapped to the pad bars (bottom-up, orange when lit). Idle bars stay dim.
- Pad press: brief scale (~0.97) on touch down. Playing state is the meter, not a full-pad color fill.
- Light haptic on successful play only.
- Mic permission on first Record tap. Denied: native alert pointing at Settings. File import still works.
- Fonts: Geist for the header. Monospace on pad number and name. Font files come from the requester when implementation starts.
- Playback and recording go through AVFoundation, never called from the view directly.
- Two modules:

  1. **Pad store.** Owns the eight pads, copy-in of files, 25 MB check, 15 s recording limit as a rule on the recorded file, persist/load, clear pad (delete sandbox file + name). Disk in tests is a temp directory injected at init.

  2. **Audio engine** (protocol). `play(pad:)`, `restart(pad:)`, `stopAll()`, metering levels per playing pad, interruption hook that `stopAll()`. Production type wraps AVFoundation. Tests inject a fake that records calls and returns canned levels.

- The view binds to the store + engine. It does not own FileManager or AVAudioPlayer.

## Testing Decisions

A good test checks what a user (or the view) can observe: pad became empty, file was copied, play was requested, all sound stopped. It does not check that SwiftUI presented a sheet.

**Target:** one Unit Test Bundle on the `Sound Pad 3000` scheme. Swift Testing (`@Test`, `#expect`). Run with Product → Test (`Cmd+U`) or `xcodebuild test -scheme "Sound Pad 3000"`. `@testable import` the app. No UI Test target in this PRD. No CI unless added later.

**Pad store tests** (temp directory, no audio hardware):

- Eight pads empty after a fresh store.
- Import copies the file and attaches it to that pad index.
- Import over 25 MB fails, pad unchanged.
- Unplayable/rejected type does not attach (if the store is the one that validates size/copy; playability may be the engine’s job on confirm).
- Clear removes the sandbox file and the name.
- Reload store from the same directory restores names and file presence.
- Confirm vs cancel is a store/view contract: only committed edits persist. Tests cover store mutations, not the sheet.

**Audio engine tests** (fake player):

- Play on a pad that has a file calls `play`.
- Second play on the same pad calls restart for that id.
- Header stop calls `stopAll`.
- Sheet-open stop calls `stopAll`.
- Interruption calls `stopAll` and does not schedule resume.
- Fake can publish levels so a mapper to bar counts can be tested without a speaker.

Do not test Geist, DocumentPicker UI, the mic system alert, or layout pixels.

There is no prior test in the repo. This target is new.

## Out of Scope

- Factory / demo samples
- Loop, hold-to-play, toggle
- Per-pad or master fader
- iCloud / sync
- Background playback, mix with Spotify
- Photos/video import
- Landscape layout, second screen, pad pages beyond 8
- Localization
- Mute that stays on (header is stop, not mute)
- In-app store, accounts, analytics
- UI tests, snapshot tests
- Sharing pads, export of the board

## Further Notes

- Visual reference: the attached mock (orange header, dark pads, right-side bar meters, pad 1 showing a live envelope).
- Bundle already in the Xcode project: `aestech.Sound-Pad-3000`. Keep it.
- Implementation should not start until Geist (and the pad mono, if not a system mono) are in the repo or handed over.
- No GitHub/Linear remote on this repo; this file is the PRD source of truth.
