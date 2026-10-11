# Warpforge Patcher changelog

The Android app that patches the game on the phone itself. Newest first. A heading ending in
"(test build)" is published as a pre-release.

## 0.2.1 - 2026-10-11

### Changes
- The "Export the game's downloaded files" button is gone. The revival server hands those files out now, so they no longer need backing up.
- Before it removes the installed game, the app asks a plain "Remove the game first?" (Continue or Stop) and no longer asks about a backup.

Tested on a phone.

## 0.2.0 - 2026-10-11

### New
- First release. Patches your own copy of the game (version 1.35.0) on the phone: from the
  installed game or from a `.apks` / `.xapk` backup. Then it installs the patched game and puts the
  current mod in place. Same patching as the PC's `1 - patch.bat`.
- Warns before it has to remove the installed game, because that erases the game's downloaded files
  for good, and goes on only once you confirm you have a backup.
- **Export the game's downloaded files**, on Android 12 and older (Android 13 and newer do not let any
  app read them; use a PC there).
- **Fix black menu after loading**, ticked by default on Pixel 6 and later and on Samsungs with an
  Exynos chip and Mali graphics: shows a still picture instead of the opening video.
- **Update the mod only**, **Share logs** (never includes your game login), and saving or loading the
  app's signing key.

Tested in MuMu Player and on a Pixel 6 Pro.
