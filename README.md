# Warpforge Revival for Android

Everything needed to run *Warhammer 40,000: Warpforge* on an Android phone against a
[Warpforge Revival server](https://github.com/silentanarchist/warpforge-revival-server), now that
the game's own servers are closed:

- **the Android build of the Warpforge Revival mod** (`WarpforgeRevival.Android.dll`),
- **the patcher** that puts a mod loader into your own copy of the Android game, and
- **the changes made to that mod loader** so it runs this game on current phones.

The Windows mod is in [warpforge-revival-mod](https://github.com/silentanarchist/warpforge-revival-mod).
Both are built from the same source and numbered together: `x.y.z-a` for Android, `x.y.z-w` for
Windows.

This is an unofficial fan project. It is not affiliated with or endorsed by Everguild or Games
Workshop. It contains no game files: you need your own copy of the game.

> **Status: works, but one piece cannot be downloaded from here yet.**
> The whole chain below has been run on one phone (a Pixel 8 Pro on Android 17): the game starts,
> signs in, plays matches and updates its mod from the server. What this repository does not hold
> is the *loader package* the patcher needs (step 3). It contains files generated from the game's
> own code, which are not ours to publish. See [What is not here, and why](#what-is-not-here-and-why).
> Until a step that generates those files from your own copy of the game exists, the patcher
> cannot be completed from this repository alone.

---

## Before you start

Read this part first. Two of these points cost people their data if skipped.

**What you need**

- A Windows PC and a USB cable.
- An Android phone with a 64-bit ARM processor (every current phone). Tested on Android 17 only.
- Your own copy of the Android game, version **1.35.0**, as its three files:
  `com.Everguild.WarhammerWarpforge.apk`, `config.arm64_v8a.apk` and `UnityDataAssetPack.apk`.
  They usually come packed together as one `.xapk` file (about 780 MB).
- About 3 GB of free disk space on the PC, and about 2 GB free on the phone.
- Google's "SDK Platform-Tools for Windows" (the `adb` program), from
  <https://developer.android.com/tools/releases/platform-tools>.

**Installing erases the game's downloaded files on the phone.**
Android will not install a patched game over the original one, so the original has to be removed
first, and removing it deletes everything the game downloaded. If your phone still holds the
game's card files from before the shutdown, copy this folder to a PC *before you do anything else*:

```
Android/data/com.Everguild.WarhammerWarpforge/files
```

Those files are no longer downloadable from anywhere. Do not patch a phone that may hold a newer
set of them than you have saved.

**Keep your signing key.**
The first time you patch, the patcher makes a signing key and saves it as
`patcher\tool\signing-key.pem`. Every later patch you install has to be signed with that same
key, or Android refuses it and you are back to removing the game. Keep the file, keep it private,
and never share a patcher folder that has it inside.

---

## Step by step

### 1. Get the patcher

Download this repository (green **Code** button, then **Download ZIP**) and unzip it somewhere
with a short path, for example `C:\warpforge-android`. Everything you run is in the `patcher`
folder.

### 2. Put your game files in

Do one of these:

- put the game's `.xapk` file straight into the `patcher` folder, **or**
- put its three `.apk` files into `patcher\game-files`.

If your copy is split into `.z01` / `.z02` / `.zip` parts, open the `.zip` part with 7-Zip and
take the `.xapk` out first.

### 3. Add the loader package

The patcher expects the loader package in `patcher\tool` as `melon_data.zip` (or in pieces named
`melon_data.zip.part0`, `.part1`, `.part2`, which it joins itself).

This is the piece that is not in this repository; see
[What is not here, and why](#what-is-not-here-and-why) for what it contains and how it is built.

### 4. Patch

Double-click **`1 - patch.bat`**. It:

1. joins the patching program from its two halves,
2. unpacks your `.xapk` if you gave it one,
3. puts the mod loader into the game and signs the result.

The big data file takes a few minutes. When it finishes, the `patched` folder holds three files:

```
base.apk   config.arm64_v8a.apk   UnityDataAssetPack.apk
```

All three belong together. If it stops with an error, the details are in `patcher\patch-log.txt`.

### 5. Switch on USB debugging on the phone

1. Settings > About phone > tap **Build number** seven times. This unlocks "Developer options".
2. Settings > System > Developer options > switch on **USB debugging**.
3. Connect the phone to the PC by cable. The phone asks "Allow USB debugging?" - accept it.

Unzip Google's platform-tools so that this file exists:

```
patcher\tool\platform-tools\adb.exe
```

### 6. Install on the phone

Double-click **`2 - install on phone.bat`**.

- If the game on the phone was patched before with the same signing key, the new copy installs
  over it and nothing is lost.
- Otherwise the install is refused, and the script asks whether to remove the copy on the phone
  first. **That is the step that erases the game's downloaded files** (see above). It only goes
  ahead if you type `YES`.

No cable? Copy the three files from `patched` to the phone and install them *together* with a
split-APK installer app such as SAI. Tapping `base.apk` on its own does not work.

### 7. First start

Start the game once.

- If it asks for **"All files access"**, allow it. The loader keeps its files, its logs and the
  `Mods` folder in `MelonLoader/com.Everguild.WarhammerWarpforge/` on the phone's storage.
- The very first start after an install copies the loader's files and sits on a black screen for
  up to a minute. Later starts skip that.
- Without the mod the game stops at the title screen with a connection error. That is expected.

Close the game (swipe it away from the recent apps).

### 8. Put the mod on the phone

Download the latest mod from [Releases](../../releases) (or from `releases/` here) and unzip it.

- Copy `WarpforgeRevival.Android.dll` into `patcher\mods` and double-click
  **`4 - put mod on phone.bat`**, **or**
- copy the file on the phone itself into `MelonLoader/com.Everguild.WarhammerWarpforge/Mods/`.

### 9. Play

Start the game. It signs in with the phone's device id (no account needed) and reaches the menu
in about half a minute.

The mod's version is shown next to the game's in **Settings > General**.

To use a different server, edit `ServerUrl` in
`MelonLoader/com.Everguild.WarhammerWarpforge/UserData/WarpforgeRevival.cfg` on the phone.

---

## Updates

**The mod updates itself.** When the server has a newer build the game asks, downloads it, checks
it and installs it, then shows a **Close game** button. Tap it and open the game again. (The
game's own "Exit" only puts the app in the background, which is why the mod has its own button.)

**The loader does not.** A new loader means running `1 - patch.bat` and `2 - install on phone.bat`
again. With the same signing key that installs over the old copy and keeps everything.

---

## If something goes wrong

**Collect the logs.** Connect the phone and double-click **`3 - get phone logs.bat`**. It asks:

- `1` - the game is closed and you are about to start it. It clears the phone's system log, then
  waits while you start the game and reproduce the problem.
- `2` - the game is open and something just went wrong. It saves the logs as they are now. Use
  this one *before* force-stopping the app, or the evidence is gone.

It makes a new folder under `patcher\phone-logs`. That folder is what to send. The logs can
contain your player id and server address, so do not post them publicly.

**Things seen so far**

| What happens | What to do |
|---|---|
| The install is refused | The copy on the phone was signed with a different key. See step 6. |
| Black screen for up to a minute on the first start after installing | Wait. It is copying the loader's files; later starts skip it. |
| The game stops at the title screen with a connection error | The mod is not on the phone (step 8), or the server is not reachable from the phone. |
| The game closes a few seconds after you open it, right after an update | An older mod build's "Close game" left the app half-closed. Swipe it away from the recent apps and open it again. Fixed from 0.11.9-a. |
| A start gets stuck before signing in, or closes within seconds, for no clear reason | Swipe the app away and start again. If it keeps happening, collect logs with option `2` before closing it. |

---

## For server owners

A server needs two things for phones, both described in the
[server's README](https://github.com/silentanarchist/warpforge-revival-server):

- the Android build of the game's content files in `content/bundles-android/` (the content files
  differ per platform; the Windows ones do not load on a phone), and
- the Android mod as `mod/WarpforgeRevival.Android.dll`, so phones are offered updates.

---

## What is in this repository

| Path | What it is |
|---|---|
| `WarpforgeRevival/` | The mod's source. The same files build the Windows mod; the parts marked `ANDROID_PORT` are the Android differences. Kept in step with [warpforge-revival-mod](https://github.com/silentanarchist/warpforge-revival-mod). |
| `WarpforgeRevival.Android/` | The project that builds `WarpforgeRevival.Android.dll` from that source. |
| `releases/` | Built mods. Each zip committed here is also published under Releases. |
| `patcher/1 - patch.bat` | Patches your copy of the game. |
| `patcher/2 - install on phone.bat` | Installs the patched game over USB. |
| `patcher/3 - get phone logs.bat` | Collects the phone's logs. |
| `patcher/4 - put mod on phone.bat` | Copies the mod from `patcher\mods` to the phone. |
| `patcher/tool/LemonPatch.exe.part0`, `.part1` | The patching program, in two halves (joined on every run). |
| `patcher/LemonPatch-source.cs`, `LemonPatch.csproj`, `LemonPatch-core-change.diff` | Its source: a small command-line front end, and two changes to LemonLoader's installer code. |
| `loader-changes/` | The changes made to the mod loader itself, as diffs against the public sources. |

### The patching program

`LemonPatch.exe` is LemonLoader's official patching code
([LemonLoader/MelonLoaderInstaller](https://github.com/LemonLoader/MelonLoaderInstaller), commit
`ac443fc`, GPL-3.0) with a command-line front end and two changes:

- **One signing key for every run**, saved next to the tool, so a re-patched game installs over
  the previous one.
- **Heap pointer tagging switched off** in the game's manifest. Newer phones tag heap pointers,
  the loader's runtime drops the tag in places, and the system then closes the app.

It also keeps the game's own engine library instead of swapping in a generic one: the generic
build is for Unity 6000.2.6f1, the game's data is 6000.2.6f2, and the engine then refuses to load.

### The loader changes

The loader is [LemonLoader](https://github.com/LemonLoader/MelonLoader) 0.7 (the Android port of
MelonLoader) with [Il2CppInteropARM64](https://github.com/LemonLoader/Il2CppInteropARM64). Out of
the box it did not get this game to its menu on a current phone. The diffs in `loader-changes/`
are what it took:

`melonloader-lemonloader-0.7.diff` (against LemonLoader/MelonLoader `7b14dac3`)

- A native crash is handed on to the system instead of hanging the app.
- The loader's files are copied out of the app once per patch, not on every start (this was 30
  to 40 seconds of black screen each time).
- The game's name and versions are read from a small text file instead of the 700 MB data file.
- The short (4-byte) kind of hook is used only for functions too short for a normal one. Using
  it everywhere made the game fail at random on start.
- The interface files generated from the game are taken ready-made from the package, because the
  tools that generate them do not run on a phone.

`il2cppinterop-arm64.diff` (against LemonLoader/Il2CppInteropARM64 `f194da0`)

- Text returned by the game's runtime is no longer freed by the loader (that crashed the app).
- The positions of six runtime functions are listed for this exact game build, because the
  searches that find them were written for Windows and found the wrong ones.
- Unused arguments, which arrive as garbage on ARM64, are checked before they are touched.
- Two functions the game calls tens of millions of times while loading get a shortcut in machine
  code. This took one loading step from 75 seconds to 6.

The function positions make this loader specific to **game version 1.35.0, 64-bit ARM**.

---

## What is not here, and why

**The game.** Not ours to publish. You supply your own copy.

**The loader package (`melon_data.zip`).** It is a zip of three things:

1. the mod loader built from the public sources with the changes above,
2. the .NET runtime the loader runs on, and
3. "interface files": about 170 small libraries that describe the game's own classes and
   functions, so that a mod can call them. They hold no game code, only names and shapes, but
   they are generated from the game's code, which makes them game content.

Parts 1 and 2 could be published. Part 3 is why the package is not here: it has to be generated
from your own copy of the game. The tools for that (Cpp2IL and the Il2CppInterop generator) do not
run on a phone, so it has to happen on the PC, as part of patching. That step is not written yet.

**Your signing key, your logs, and anything in `game-files`, `patched` or `phone-logs`.** They are
listed in `.gitignore` so they cannot be committed by accident.

---

## Building

### The mod

You need the .NET SDK (6 or newer) and reference libraries from your own installation. They are
not in this repository because they are not ours to publish.

| Folder | Where it comes from |
|---|---|
| `refs/net6` | the .NET 6 runtime libraries (`Microsoft.NETCore.App` 6.x) |
| `refs-android/ml` | `MelonLoader/net6` from the loader package |
| `refs-android/il2cpp` | `MelonLoader/Il2CppAssemblies` from the loader package (the interface files) |

```
dotnet build WarpforgeRevival.Android/WarpforgeRevival.Android.csproj -c Release
```

The result is `WarpforgeRevival.Android/bin/Release/net6.0/WarpforgeRevival.Android.dll`.

### The loader

1. Check out `LemonLoader/Il2CppInteropARM64` at `f194da0`, apply `il2cppinterop-arm64.diff`, and
   build it: `dotnet build Il2CppInterop.HarmonySupport -c Release -p:VersionSuffix=arm64c`.
2. Check out `LemonLoader/MelonLoader` at `7b14dac3` and apply `melonloader-lemonloader-0.7.diff`.
   Make the Il2CppInterop build from step 1 available to it as a local NuGet source.
3. Build the native part with the .NET 9 SDK and the Android NDK (r27c):
   ```
   cd MelonLoader.Bootstrap
   dotnet publish -c Release -r linux-bionic-arm64 -p:DisableUnsupportedError=true -p:PublishAotUsingRuntimePack=true
   ```
   The result is `bin/Release/native/libmain.so`.

### The patching program

Check out `LemonLoader/MelonLoaderInstaller` at `ac443fc` next to the `patcher` folder as `inst`,
apply `LemonPatch-core-change.diff`, use `LemonPatch-source.cs` as the program, and publish
`LemonPatch.csproj` for `win-x64` as a single self-contained file.

---

## Licences

- The mod (`WarpforgeRevival/`, `WarpforgeRevival.Android/`) and the scripts: MIT, see
  [LICENSE](LICENSE). The licence covers this project's code only, not the game.
- `LemonPatch.exe` and the files describing it: GPL-3.0, as LemonLoader's installer is. See
  `patcher/LICENSE-LemonLoader-installer.txt`.
- `loader-changes/melonloader-lemonloader-0.7.diff` changes MelonLoader (Apache-2.0).
- `loader-changes/il2cppinterop-arm64.diff` changes Il2CppInterop (LGPL-3.0).

Only use LemonLoader from <https://github.com/LemonLoader>. There are look-alike download sites
with the same name.
