# Flutter Firebase Playground

A sample Flutter project integrating Firebase Core, Firebase Analytics, and Firebase Cloud Messaging (FCM) with `flutter_local_notifications`.

- Freshers: step-by-step learning guide
- Experienced devs: ready-to-adapt integration template

## Project Goals

- Initialize Firebase (Core) on app start
- Analytics: track screen views and custom events with safe error handling
- Messaging: receive FCM in foreground, background, and terminated states
- Show notifications using `flutter_local_notifications`
- Retrieve and display FCM token
- Handle notification taps to navigate to different screens

## Prerequisites

- Flutter SDK 3.8.x (Dart 3.8.x)
- macOS with Xcode (for iOS), CocoaPods installed
- Android SDK / Android Studio
- A Firebase project (access to console)

## Quickstart

1. Clone and install dependencies

```bash
git clone <your-fork-or-repo-url> flutter-firebase-playground
cd flutter-firebase-playground
flutter pub get
```

2. Configure Firebase via FlutterFire (recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

- Select your Firebase project
- Enable platforms: Android and iOS
- This generates `lib/firebase_options.dart` and applies platform files

3. Alternatively, manual Firebase files

- Android: add `google-services.json` to `android/app/`
- iOS: add `GoogleService-Info.plist` to `ios/Runner/`
- Make sure to add Google Services Gradle plugins as per Firebase docs

4. Run the app

```bash
flutter run -d ios         # or
flutter run -d android
```

## Step-by-step Firebase setup

### Using FlutterFire (recommended)

- Install CLI: `dart pub global activate flutterfire_cli`
- From project root: `flutterfire configure`
- After completion you should see `lib/firebase_options.dart` with real options

### Manual setup (not recommended for beginners)

- Create a Firebase project in the console
- Add Android app: package ID matches `applicationId` in `android/app/build.gradle`
- Download `google-services.json` into `android/app/`
- Add to `android/build.gradle` and `android/app/build.gradle` the Google services plugin
- Add iOS app: bundle ID matches `PRODUCT_BUNDLE_IDENTIFIER` in Xcode
- Download `GoogleService-Info.plist` into `ios/Runner/`
- In Xcode, enable Push Notifications and Background Modes (Remote notifications)

## Code Organization

- `lib/services/`
  - `analytics_service.dart` — wraps Firebase Analytics with helpers
  - `messaging_service.dart` — handles FCM permissions, tokens, listeners
  - `local_notifications_service.dart` — initializes and shows local notifications
- `lib/screens/`
  - `home_screen.dart` — entry with links to demos
  - `analytics_screen.dart` — logs events and explains error handling
  - `messaging_screen.dart` — shows FCM token and last payload
  - `details_screen.dart` — destination for notification tap routing
- `lib/widgets/` — reusable UI such as `rounded_button.dart`

## How Analytics demo works

- `AnalyticsService` exposes `logEvent` and `logScreenView`
- `HomeScreen` and `AnalyticsScreen` log screen views
- Press buttons on Analytics screen to log events
- Error handling: malformed events are caught and logged to console so you can see what would happen in a real app

### Verify in Analytics DebugView

- Android: run `adb shell setprop debug.firebase.analytics.app <your.package>` then relaunch the app
- iOS: launch with Xcode or simulator and check DebugView
- Open Firebase Console → Analytics → DebugView to see real-time events

## How Messaging demo works

- On first open, the app requests notification permission
- The FCM token is displayed in Messaging screen
- App listens for messages in all states:
  - Foreground: shows a local notification and logs payload
  - Background: tap on notification triggers `onMessageOpenedApp`
  - Terminated: if app launched by tapping a notification, payload is read via `getInitialMessage`

### Send test notifications from Firebase Console

- Firebase Console → Cloud Messaging → Send test message
- Enter your FCM token from the Messaging screen
- Use a data payload to control navigation:

```json
{
  "route": "/details",
  "id": "42",
  "title": "New Item",
  "body": "Tap to view details"
}
```

- Title/body can be either Notification fields or included in data

## Notification tap routing

- The app checks the `route` field in message data; if it equals `"/details"`, it navigates to Details and passes `id`
- Otherwise, it opens the Messaging screen by default
- Example data payload (see above)

## Platform-specific notes

### Android

- `POST_NOTIFICATIONS` permission is declared for Android 13+
- Ensure the default notification channel meta-data is present
- After FlutterFire, the Google Services plugin lines will be added

### iOS

- Enable Push Notifications capability and Background Modes → Remote notifications in Xcode
- Set up APNs key/cert in Firebase project settings
- On first run, iOS will prompt for notification permission

## Troubleshooting & common pitfalls

- Forgot to run `flutterfire configure`: you'll see an `UnimplementedError` for `DefaultFirebaseOptions.currentPlatform`
- Token is null: permissions not granted or simulator without APNs. Use a real iOS device for push
- Notifications not shown on Android 13+: ensure runtime permission was granted
- Not receiving messages in terminated state: use data-only or include correct APNs configuration
- Analytics DebugView empty: verify you've enabled DebugView as described

## Acceptance criteria & verification

- App builds and runs on Android and iOS after FlutterFire configuration
- Analytics screen logs events; visible in DebugView when debug mode is enabled
- Messaging screen shows FCM token
- Foreground messages display local notification
- Background/terminated tap opens the app and navigates according to payload

## How to test quickly

### Analytics

- Launch the app → open Analytics screen → press the buttons
- Observe console logs and Firebase DebugView

### FCM

- Open Messaging screen → copy token
- Send test message from Firebase Console to that token
- Verify notification appears; tap it to navigate to Details (if `route: /details`) or open Messaging screen
