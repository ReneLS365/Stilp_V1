# Stilp v1 — iOS installable distribution (iPhone)

This guide describes the Apple-supported workflow for building and installing **Stilp v1** on physical iPhones for internal use.

Scope:
- iOS only
- installable iPhone build only
- internal/feltbrug distribution
- no App Store release requirement

Selected distribution route:
- **Primary:** TestFlight (recommended for internal team installs)
- **Alternative:** Ad Hoc distribution (only if your Apple Developer setup requires it)

## 1) Prerequisites

You need:
- A Mac with a recent Xcode version
- Flutter SDK installed and on `PATH`
- Apple Developer Program access (for TestFlight or Ad Hoc signing/distribution)
- At least one physical iPhone for smoke testing
- USB cable or trusted wireless device pairing for first local device run

## 2) Current repository iOS platform state

This repository currently does **not** include an `ios/` directory.

Generate iOS platform files locally once from repo root:

```bash
flutter create --platforms=ios .
```

Notes:
- Do this only in your local/macOS build environment with Xcode installed.
- Never commit Apple signing secrets from your local machine.

## 3) Prepare dependencies and baseline checks

From repository root:

```bash
flutter pub get
flutter analyze
flutter test
```

## 4) Open and configure iOS project

After `ios/` exists:
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Select the `Runner` target.
3. Go to **Signing & Capabilities**.
4. Set your **Team**.
5. Use a unique **Bundle Identifier** for your org/device group.
6. Keep **Automatically manage signing** enabled unless your org requires manual profiles.

Security rules:
- Do **not** commit certificates (`.p12`), provisioning profiles (`.mobileprovision`), private keys, passwords, or account details.
- Keep all signing assets in macOS keychain / Apple Developer portal only.

## 5) Version and build number handling

Set app version/build before release build:

```bash
flutter build ios --release --build-name 1.0.0 --build-number 22
```

Or set/update in `pubspec.yaml` and build normally.

Recommended rule:
- Increase `build-number` for each uploaded/archive build.
- Increase `build-name` for user-visible release versions.

## 6) Build iOS release artifact

From repository root:

```bash
flutter build ios --release
```

This produces a signed-release-ready iOS build structure for Xcode archive/distribution workflows.

## 7) Distribute/install via Apple-supported route

### A) TestFlight (recommended)

1. In Xcode, choose **Any iOS Device (arm64)**.
2. Run **Product > Archive**.
3. In Organizer, select archive and click **Distribute App**.
4. Choose **App Store Connect** > **Upload**.
5. In App Store Connect, assign build to internal testers.
6. Tester installs through TestFlight on iPhone.

Why this is preferred:
- Official Apple internal-distribution path
- Easier tester rollout/updates than per-device Ad Hoc files

### B) Ad Hoc (fallback)

Use only if TestFlight is unavailable for your account/process.

1. Register iPhone UDIDs in Apple Developer portal.
2. Create/manage Ad Hoc provisioning profile.
3. Archive in Xcode.
4. **Distribute App** > **Ad Hoc** and export signed package.
5. Install via Apple Configurator / MDM / approved internal method.

## 8) Physical iPhone smoke checklist

Run this on an installed iPhone release build:

- [ ] app installs on physical iPhone
- [ ] app opens
- [ ] user can create a project
- [ ] project can be saved locally
- [ ] project can be reopened
- [ ] plan view opens
- [ ] facade editor opens
- [ ] manual packing list opens
- [ ] export preview opens
- [ ] PDF export screen does not crash
- [ ] image export screen does not crash
- [ ] no backend/cloud login is required

## 9) Troubleshooting

### `flutter build ios --release` fails because iOS platform is missing
Run once:

```bash
flutter create --platforms=ios .
```

### Xcode signing error (`No signing certificate` / `No profiles`)
- Confirm correct Apple Team is selected in `Runner` target.
- Verify Apple Developer membership/role allows signing.
- Re-fetch profiles in Xcode Settings > Accounts.

### Device install blocked by trust/profile issue
- Install through TestFlight where possible.
- For local debug run, confirm iPhone trusts developer certificate/profile.

### Build upload rejected due duplicate build number
- Increase `--build-number` and archive/upload again.

### CI/Linux environment limitation
- iOS archive/distribution requires macOS + Xcode + Apple signing assets.
- On non-macOS environments, run command validation only and complete signing/archive/upload locally on a Mac.

## 10) Local command checklist (copy/paste)

```bash
flutter create --platforms=ios .   # only if ios/ is missing
flutter pub get
flutter analyze
flutter test
flutter build ios --release
```

Then finish in Xcode:
- Signing & Capabilities configuration
- Archive
- Distribute via TestFlight (preferred) or Ad Hoc
