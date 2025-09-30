# NYC Public Space Flutter App

The repo contains the source code for the NYC Public Space App, a consolidated map of public spaces in New York City. 

## Development

**Install dependencies**
```bash
flutter pub get
```

**Set up environment variables**
Create a `.env` file in the project root:
```
ACCESS_TOKEN=pk.your_mapbox_access_token_here
```

**Configure Firebase** (optional - for authentication features)
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

### Running the App

- Choose a device in the bottom right of VS Code (make sure the emulator/simulator are running)
- Use the `Run and Debug` panel in VS Code
- Press the green play button ("Start Debugging")

### VS Code Setup

The project includes launch configuration. Set your `ACCESS_TOKEN` environment variable:
```bash
export ACCESS_TOKEN=pk.your_token_here
```

### Production build to a real iOS device

This step is helpful for testing the build before releasing.

- connect device via USB
- choose device in VS Code (bottom-right blue bar)
- flutter run --release --dart-define ACCESS_TOKEN=pk.12345

## Releasing

### Android Release

- increment version in `pubspec.yaml`
- `sh scripts/build_android.sh`

Login to Google Play Console
- Closed Testing > Create new release
- Drag and drop app bundle (build/app/outputs/bundle/release/app-release.aab)

### iOS Release

**Important**: before releasing, do a local release to a real device to test (see above) 

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
