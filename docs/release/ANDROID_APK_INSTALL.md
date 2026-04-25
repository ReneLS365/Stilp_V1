# Stilp v1 — Android APK build and installation

This guide describes how to build and install **Stilp v1** as an internal Android APK for field use.

Scope:
- Android only
- APK only
- Internal/feltbrug distribution
- No Play Store flow

## 1) Preconditions

You need:
- Flutter SDK installed and on `PATH`
- Android SDK + platform tools installed
- A connected Android phone (USB) or file transfer method

This repository currently does **not** include an `android/` platform directory. Before the first APK build, generate it once from repo root:

```bash
flutter create --platforms=android .
```

After this, keep and version-control the generated `android/` project files (except secrets/keystores).

## 2) Release identity (label/package)

Recommended defaults for Stilp v1:
- App label: `Stilp v1`
- Application ID/package: `com.stilp.v1`

If needed, set these in:
- `android/app/src/main/AndroidManifest.xml` (`android:label`)
- `android/app/build.gradle` or `android/app/build.gradle.kts` (`applicationId`)

Only change these if your generated Android project does not already match your chosen Stilp identity.

## 3) Signing and keystore handling

### Important
- Do **not** commit private keystores (`*.jks`, `*.keystore`) or passwords.
- Do **not** commit secret values in plaintext.

### If release signing is not configured yet
You can still build with:

```bash
flutter build apk --release
```

In this state, the APK is built with Flutter/Gradle default signing behavior for the project setup.

For stable internal distribution, configure your own release keystore outside git and wire it via local files such as:
- `android/key.properties` (gitignored)
- keystore file in a private local path (gitignored)

Example `android/key.properties` template (placeholder values only):

```properties
storePassword=__SET_LOCALLY__
keyPassword=__SET_LOCALLY__
keyAlias=__SET_LOCALLY__
storeFile=__ABSOLUTE_OR_RELATIVE_PATH_TO_PRIVATE_KEYSTORE__
```

Add to `.gitignore` (if not already present):

```gitignore
android/key.properties
*.jks
*.keystore
```

## 4) Build commands

From repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Primary release command (required):

```bash
flutter build apk --release
```

## 5) APK output location

Default Flutter output path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 6) Transfer APK to Android phone

Choose one method:

### A) USB file transfer
1. Connect Android phone via USB.
2. Copy `app-release.apk` to `Download/` (or another known folder).

### B) ADB install directly from computer

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### C) Send file (email/chat/cloud drive)
1. Upload APK from your computer.
2. Download APK on phone to local storage.

## 7) Allow installation from unknown apps

On Android phone:
1. Open **Settings**.
2. Go to **Security** / **Apps** / **Special access** (varies by vendor).
3. Open **Install unknown apps**.
4. Enable the app you use to open APKs (e.g., Files, Chrome, Drive).

## 8) Install APK

On phone:
1. Open the downloaded `app-release.apk`.
2. Tap **Install**.
3. Wait for install completion.
4. Tap **Open**.

## 9) Post-install smoke checklist (physical device)

Verify all of the following:
- [ ] APK installs on a physical Android phone
- [ ] Stilp app opens
- [ ] User can create a project
- [ ] Project can be saved locally
- [ ] Project can be reopened
- [ ] Plan view opens
- [ ] Facade editor opens
- [ ] Manual packing list opens
- [ ] Export preview opens
- [ ] No backend/cloud login is required

## 10) Troubleshooting

### Install blocked by Android
- Ensure **Install unknown apps** is enabled for the installer app.
- Re-download APK if file is corrupted.

### `INSTALL_FAILED_UPDATE_INCOMPATIBLE`
Cause: Existing app was signed with a different key.

Fix:
1. Uninstall existing Stilp app from phone.
2. Reinstall APK built from the current signing setup.

### `INSTALL_PARSE_FAILED_NO_CERTIFICATES` / unsigned issue
- Rebuild using `flutter build apk --release`.
- Verify signing config is valid if custom release keystore is used.

### Old APK keeps reinstalling
- Confirm exact file path and modified time.
- Delete previous APK copies from Downloads and transfer the new file again.

### Build fails due missing Android project
Run once in repo root:

```bash
flutter create --platforms=android .
```

Then retry build commands.
