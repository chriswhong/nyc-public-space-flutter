# NYC Public Space Flutter App

The repo contains the source code for the NYC Public Space App, a consolidated map of public spaces in New York City. 

NYC Public Space App Links:
- [iOS App Store](https://apps.apple.com/us/app/nyc-public-space/id6737332320)
- [Android Play Store](https://play.google.com/store/apps/details?id=com.nycpublicspace&hl=en_US)
- [Web Version (https://nycpublicspace.org/)](https://nycpublicspace.org/)

  
<img width="236" height="512" alt="public-space" src="https://github.com/user-attachments/assets/da129045-cf8b-4c6f-9433-2267416d1779" />

## Related Repos

**[`chriswhong/nyc-public-space-data`](https://github.com/chriswhong/nyc-public-space-data)** - Data exports from the app database and data processing scripts.

## Development

**Install dependencies**
```bash
flutter pub get
```

**Configure Firebase**
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

**Mapbox access token**

The app reads its Mapbox access token from Firebase Remote Config (parameter `mapbox_access_token`) on startup, in both development and production builds. Make sure that parameter is set and published in the Firebase console. No local setup is needed.

*Optional local override:* if Remote Config is unavailable (e.g. offline development), you can pass a token at build time. It is only used when the Remote Config value is empty or the fetch fails:
```bash
flutter run --dart-define=ACCESS_TOKEN=pk.your_mapbox_access_token_here
```

## Run on simulator/emulator

`flutter run`

## Production build to my device

`flutter run --release`

You may need to add `-d <device_id>` if you have multiple devices connected. You can find the device id by running `flutter devices`.

`flutter run --release -d 00008140-00061DE80106801C`

## Releasing

### Android Release

- Add entry to CHANGELOG.md
- increment version in `pubspec.yaml`
- `sh scripts/build_android.sh`

Login to Google Play Console
- Closed Testing > Create new release
- Drag and drop app bundle (build/app/outputs/bundle/release/app-release.aab)

### iOS Release

**Important**: before releasing, do a local release to a real device to test (see above) 

- Add entry to CHANGELOG.md
- increment version in `pubspec.yaml`
- `sh scripts/build_ios.sh`

Open Xcode:
- Navigate to ios/ and open the Runner.xcworkspace file.
- Archive the Build: Product > Archive
- Validate and Upload: Select the new archive, click Distribute App, and follow the steps:
  - Method: App Store Connect.
  - Team: Ensure the correct team is selected.
  - Validation: Resolve any errors or warnings.
  - Upload: Complete the upload process.

Log in to App Store Connect
- Use the + icon to make a new version
- Add the build
- Add info and submit for release
