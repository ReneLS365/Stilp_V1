# Stilp v1 — Android APK build and installation

This guide describes how to build and install **Stilp v1** as an internal Android APK for field use.

Scope:
- Android only
- APK only
- Internal/feltbrug distribution
- No Play Store flow

## 1) Fastest path: download APK from GitHub Actions

After the `Build Android APK` workflow has run successfully on GitHub:

1. Open the repository on GitHub.
2. Go to **Actions**.
3. Open **Build Android APK**.
4. Open the latest successful run.
5. Scroll to **Artifacts**.
6. Download `stilp-v1-android-apk`.
7. Unzip the downloaded artifact.
8. Install `app-release.apk` on the Android phone.

The workflow artifact contains:

```text
app-release.apk
```

Artifact retention:
- GitHub keeps the APK artifact for 30 days.
- Run the workflow again when a fresh APK is needed.

## 2) Preconditions for local build

You need:
- Flutter SDK installed and on `PATH`
- Android SDK + platform tools installed
- A connected Android phone (USB) or file transfer method

This repository currently does **not** include an `android/` platform directory. Before the first local APK build, generate it once from repo root:

```bash
flutter create --platforms=android .
```

After this, keep and version-control the generated `android/` project files (except secrets/keystores).

## 3) GitHub Actions APK workflow

The repository includes a GitHub Actions workflow at:

```text
.github/workflows/android-apk.yml
```

It can be started manually:

```text
GitHub → Actions → Build Android APK → Run workflow
```

The workflow runs:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

If the repository has no `android/` directory, the workflow generates one during the run with:

```bash
flutter create --platforms=android .
```

That generated platform directory is used only inside the workflow run unless committed separately later.

## 4) Release identity (label/package)

Recommended defaults for Stilp v1:
- App label: `Stilp v1`
- Application ID/package: `com.stilp.v1`

If needed, set these in:
- `android/app/src/main/AndroidManifest.xml` (`android:label`)
- `android/app/build.gradle` or `android/app/build.gradle.kts` (`applicationId`)

Only change these if your generated Android project does not already match your chosen Stilp identity.

## 5) Signing and keystore handling

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

## 6) Local build commands

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

## 7) APK output location

Default Flutter output path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 8) Transfer APK to Android phone

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

## 9) Allow installation from unknown apps

On Android phone:
1. Open **Settings**.
2. Go to **Security** / **Apps** / **Special access** (varies by vendor).
3. Open **Install unknown apps**.
4. Enable the app you use to open APKs (e.g., Files, Chrome, Drive).

## 10) Install APK

On phone:
1. Open the downloaded `app-release.apk`.
2. Tap **Install**.
3. Wait for install completion.
4. Tap **Open**.

## 11) Post-install smoke checklist (physical device)

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
- [ ] PDF export path does not crash
- [ ] Image export path does not crash
- [ ] No backend/cloud login is required

## 12) Troubleshooting

### GitHub Actions run fails
- Open the failed workflow run.
- Check whether failure happened in `flutter analyze`, `flutter test`, or `flutter build apk --release`.
- Fix the reported issue and rerun the workflow.

### No artifact is visible
- Artifacts are only created after a successful workflow run.
- Open the latest successful run, not a failed run.
- The artifact expires after 30 days.

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
