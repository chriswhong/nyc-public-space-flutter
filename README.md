# NYC Public Space Map

A consolidated map of public spaces in New York City.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Production build to my device

flutter run --release --dart-define ACCESS_TOKEN=pk.12345


## Android Release

- increment version in pubspec.yaml
- sh scripts/build_android.sh

Login to Google Play Console
Closed Testing > Create new release
Drag and drop app bundle (build/app/outputs/bundle/release/app-release.aab)



## iOS Release

**Important**: before releasing, do a local release to a real device to test (see above) 

- increment version in pubspec.yaml
- sh scripts/build_ios.sh

Open Xcode:

Navigate to ios/ and open the Runner.xcworkspace file.

Archive the Build:
    In Xcode, go to Product > Archive.
    After the archiving process, the Organizer window opens.

Validate and Upload:
    Select the new archive, click Distribute App, and follow the steps:
    Method: App Store Connect.
    Team: Ensure the correct team is selected.
    Validation: Resolve any errors or warnings.
    Upload: Complete the upload process.

Log in to App Store Connect
Use the + icon to make a new version
Add the build
Add info and submit for release
