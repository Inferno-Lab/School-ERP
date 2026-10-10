# Developer environment and build notes

These are the paths on the lead's Windows machine; adjust for yours.

- Flutter 3.47.x / Dart 3.13 at `D:\dev\flutter`, JDK 21 at `D:\dev\jdk21`, Android SDK at `D:\dev\android-sdk`, emulator AVD `edunest` (x86_64).
- Git Bash: `export PATH=/d/dev/flutter/bin:/d/dev/jdk21/bin:$PATH`. adb: `/d/dev/android-sdk/platform-tools/adb.exe`.

## Emulator

- Start with the host GPU: `emulator -avd edunest -gpu host -no-snapshot-save`. Software GPU modes crash when Impeller runs the glass shader.
- Launch it as a **detached process** (PowerShell `Start-Process`); an emulator started inside a tool shell dies when that shell call ends.
- The emulator, Gradle and an IDE together exhaust memory on 16 GB machines. Symptoms: PowerShell `OutOfMemoryException`, "Unable to determine engine version", `adb shell` hanging. Close the emulator before release builds.

## Builds

```bash
flutter build apk --debug --target-platform android-x64                  # emulator
flutter build apk --release --target-platform android-arm64,android-arm  # phones (debug-signed unless a keystore is configured)
```

- `android/gradle.properties` sets `kotlin.incremental=false`: the repo and the pub cache sit on different drives and incremental Kotlin fails across them.
- Release builds take 5–10 minutes. Run them in the background and poll for an explicit `EXIT=` marker in the log; never wait on a file a failed build will not create.
- Per-school release signing and store accounts belong to the platform plan; the current APK is debug-signed for demos.

## Windows scripting pitfalls

- Python wants `D:/…` paths, not `/d/…`.
- Write multi-line scripts to a file rather than a long heredoc full of backslashes.
- Screenshot tool output goes outside the repo: `--dart-define=SHOOT_DIR=D:/…`.
