# Stilp v1 — Google Play internal test

This guide describes how to distribute Stilp v1 through Google Play internal testing.

Scope:
- Android only
- Google Play internal test only
- Internal/feltbrug distribution
- No public Play Store production release
- No backend
- No cloud sync
- No BOM/component logic

## Why this route

Some Android phones block direct APK sideloading through Google Play Protect Advanced Protection.

Google Play internal testing avoids that sideloading block because the app is installed through Google Play.

## What must be built

Google Play internal testing should use an Android App Bundle:

```text
app-release.aab
```

Default Flutter output path:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Local build commands

From repository root:

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

If the repository has no Android platform directory yet, generate it once before building:

```bash
flutter create --platforms=android .
```

## Google Play Console setup

1. Open Google Play Console.
2. Create or select the Stilp app.
3. Enroll the app in Play App Signing when prompted.
4. Go to Testing > Internal testing.
5. Create an email list for testers.
6. Add tester Google accounts.
7. Create a new internal test release.
8. Upload `app-release.aab`.
9. Complete required release notes.
10. Save and roll out the internal test release.
11. Copy the tester opt-in link.
12. Open the opt-in link on the Android phone.
13. Join the test.
14. Install Stilp through Google Play.

## Required identifiers

Before first upload, confirm the Android application id is stable.

Recommended value:

```text
com.stilp.v1
```

Do not change the application id after publishing the first bundle unless you intentionally create a new Play app.

## Signing and secrets

Do not commit:
- keystores
- passwords
- service account JSON
- Play Console credentials
- private signing files

Keep all signing assets outside git.

## Tester smoke checklist

Verify on a physical Android phone:

- [ ] tester can open the opt-in link
- [ ] tester can join the internal test
- [ ] app installs through Google Play
- [ ] app opens
- [ ] user can create a project
- [ ] project can be saved locally
- [ ] project can be reopened
- [ ] plan view opens
- [ ] facade editor opens
- [ ] manual packing list opens
- [ ] export preview opens
- [ ] PDF export path does not crash
- [ ] image export path does not crash
- [ ] no backend/cloud login is required

## Troubleshooting

### The phone still blocks APK install
Do not install the APK directly. Use the Google Play internal test opt-in link and install through Google Play.

### Tester cannot access the app
- Confirm the tester email is on the internal test email list.
- Confirm the tester is logged into Google Play with the same account.
- Confirm the internal test release is rolled out.

### App bundle rejected
- Check application id.
- Check version code is higher than previous upload.
- Check Play App Signing setup.
- Check required Play Console policy/store listing fields.

### No AAB artifact exists
Run the Android App Bundle workflow or build locally with:

```bash
flutter build appbundle --release
```

## Public release boundary

This workflow is not a production Play Store release.

It is only for internal testing so Stilp can be installed on Android devices that block sideloaded APKs.
