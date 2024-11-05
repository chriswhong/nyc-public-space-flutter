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

flutter clean
flutter build appbundle --release --dart-define ACCESS_TOKEN=pk.12345

## iOS Release

- increment version
- flutter clean
- flutter build ios --release --dart-define ACCESS_TOKEN=pk.12345

