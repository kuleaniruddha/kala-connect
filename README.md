# कला-Connect

A voice-first Flutter app that helps artisans photograph a product, create a
catalogue draft, and get a suggested price range.

## Run it locally

### 1. Install Flutter

Install the Flutter SDK, then confirm it is ready:

```powershell
flutter doctor
```

### 2. Clone the project

```powershell
git clone https://github.com/harshpjain77-design/kala-connect.git
cd kala-connect
```

### 3. Install packages and run

Connect an Android phone with USB debugging enabled, or start an Android
emulator. Then run:

```powershell
flutter pub get
flutter run
```

Allow camera, microphone, and photo-library permissions when Android asks.

## Demo login

The app starts in demo mode, so Firebase setup is not needed to test it.

- Phone number: enter any valid-looking number, for example `+919876543210`
- OTP: `123456`

## Build an APK

```powershell
flutter build apk --debug
```

The APK will be at:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Optional: real Firebase OTP

Firebase is already connected in the project files, but real OTP requires the
project owner to enable Phone Authentication, add Android SHA fingerprints, and
initialize Storage in Firebase Console. Once that is complete, run:

```powershell
flutter run --dart-define=USE_FIREBASE=true
```
