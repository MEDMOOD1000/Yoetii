# Mornye application shell

A reusable Flutter application shell extracted from Mornye. It retains the Mornye and Material appearance systems, the animated Mornye navigation bar, responsive tabs, language selection, and persistent appearance settings. Home, Workspace, and Search are empty content slots for a future app idea.

The media player, library, downloader, Rust backend, music screens, and their Flutter packages and Android build tasks have been removed. The Android host is a standard Flutter project. The app uses the original Mornye visual code; see LICENSE, COPYING and NOTICE for attribution and license terms.

## Build

Use Flutter 3.50.0. Run `flutter pub get` and `flutter run` with an Android device, or push to main and download the APK from the Build Android APK workflow. The CI APK uses a development signing key for testing. An existing APK signed by a different key must be uninstalled before installing it.

The web target can be used to preview the interface on a desktop browser with `flutter run -d chrome` or `flutter build web`.
