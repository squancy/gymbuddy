# Gym Buddy (Kagur) setup guide

How to get the app building and running against local Firebase emulators. This
was checked on Windows 11 with an Android emulator on 2026-10-31. The iOS build
has not been set up yet.

## 1. Tools

| Tool | Version used | Notes |
| --- | --- | --- |
| Flutter | 3.47 (stable), Dart 3.13 | `pubspec.yaml` needs Dart `^3.5.4` |
| Android SDK | platform 35, NDK 28.2.13676358 | Install from Android Studio's SDK Manager |
| JDK 17 | Microsoft OpenJDK 17 | For the Gradle build |
| JDK 21 | Microsoft OpenJDK 21 | The Firebase emulators need Java 21+ |
| Node.js | LTS | For the Firebase CLI |
| Firebase CLI | `npm i -g firebase-tools` | Runs the Firestore and Storage emulators |
| Android emulator | A recent Pixel image with Google APIs | |

Check the install with `flutter doctor`. Android toolchain and a connected
device must both be green.

The Android build uses Gradle 8.14.3, Android Gradle Plugin 8.11.1 and Kotlin
2.2.20. Flutter 3.47 won't build with older versions.

## 2. Files that are not in git

`.gitignore` excludes these files, so a fresh clone **cannot build**. Get them
from a teammate:

| Path | What it is | How to get it |
| --- | --- | --- |
| `android/` (whole folder) | Android project, Gradle config, `google-services.json` | Copy from a teammate. Don't regenerate it with `flutter create`: that gives the wrong application ID (`com.android.gymbuddy`) |
| `lib/firebase_options.dart` | Firebase app config | `flutterfire configure --project=gym-buddy-9ab39`, or copy it |
| `lib/auth/secrets.dart` | Algolia keys for search | Copy from a teammate (shape below) |
| `firebase.json`, `firestore.rules`, `storage.rules`, `firestore.indexes.json`, `.firebaserc` | Firebase CLI and emulator config | Copy from a teammate |

`lib/auth/secrets.dart` looks like this:

```dart
class Algolia {
  static const String applicationID = '...';
  static const String searchAPIKey = '...';      // search-only key, never the admin key
  static const String indexNamePosts = '...';
  static const String indexNameUsers = '...';
  static const String indexNameUserSettings = '...';
}
```

`firebase.json` must have the emulator ports that the app hard-codes:
Firestore on `8080` and Storage on `9199`.

> Phase 0 of the plan moves `android/`, `ios/`, `pubspec.lock` and the Firebase
> config files into git. `secrets.dart` and `google-services.json` stay out.
> Update this section when that lands.

## 3. Emulators or production

The app picks its backend at **compile time**:

| Build | Backend |
| --- | --- |
| `flutter run` (no flag) | **Production** Firebase project `gym-buddy-9ab39` |
| `flutter run --dart-define=USE_EMULATORS=true` | Local emulators (Firestore `8080`, Storage `9199`) |

The flag sets `GlobalConsts.test` in `lib/consts/common_consts.dart`. Don't edit
that constant by hand: a committed `true` points release builds at localhost,
and a committed `false` sends every debug session to production.

Also in emulator mode:

- No email is sent. `EmailRepository.sendEmail` prints the recipient and
  subject to the log instead, because the emulators have no SMTP credentials.
- Posting and photo upload use the emulator paths in `post_page_view_model.dart`
  and `profile_photo_view_model.dart`.

Production Firestore rules expired on 2025-11-21, so a build without the flag
fails on its first read ("An unknown error occurred" on signup). Use the
emulators for all development until Phase 3 of the plan ships real rules.

## 4. Run the app

All commands run from the repo root.

**1. Start the Firebase emulators with the seed data.** The emulators need JDK 21
on `PATH` / `JAVA_HOME`:

```bash
firebase emulators:start --only firestore,storage --project gym-buddy-9ab39 --import=firebase_emulator_data
```

The emulator UI is at http://127.0.0.1:4000. Changes are **not** saved on exit,
so every start goes back to the seed data. To save your changes into the seed,
add `--export-on-exit=firebase_emulator_data`, and commit them on purpose.

The seed holds about 150 Budapest gyms (`gyms/budapest/gyms`), test users,
activities and 34 posts.

**2. Start an Android emulator** from Android Studio's Device Manager, or with
`emulator -avd <name>`.

**3. Put the emulator's GPS in Budapest.** The feed only looks for gyms within
1 km of the device:

```bash
adb emu geo fix 19.0402 47.4979      # longitude first, then latitude
```

**4. Run the app.** The Gradle build needs JDK 17:

```bash
flutter pub get
flutter run --dart-define=USE_EMULATORS=true
```

The app maps `127.0.0.1` to `10.0.2.2` inside the Android emulator by itself.
Look for `Mapping Firestore Emulator host "127.0.0.1" to "10.0.2.2"` in the log.

To try it, tap **Sign up**, fill in all fields including **Sex**, and allow
location. You land on Home. Check the new user in the emulator UI under
`users` and `user_settings`.

## 5. Tests

```bash
flutter analyze lib
flutter test                                          # widget tests in test/
flutter test integration_test/page_tests/<file>.dart \
  --dart-define=USE_EMULATORS=true -d <emulator-id>   # needs the emulators running
```

The integration tests and the database population scripts in
`integration_test/database_population/` call `firebaseInit(test: true)`. They
also need `--dart-define=USE_EMULATORS=true`. Without it they talk to
production.

**Known failures (2026-10-31):**

- All 3 widget tests in `test/` fail. The repositories construct
  `FirebaseFirestore.instance`, and Firebase isn't set up in a widget test.
  Phase 0 fixes this by injecting mock repositories.
- `integration_test/page_tests/signup_test.dart` doesn't fill in the new **Sex**
  field yet, so signup validation will reject it.

## 6. Windows notes

- **Non-ASCII paths break `flutter analyze`.** If the repo path has a character
  like `á` (for example `C:\Users\Erik Halász\...`), the analysis server crashes
  with `FormatException: Unexpected end of input`. Map the repo to a drive
  letter and run it from there:

  ```powershell
  subst Q: "C:\Users\<you>\...\gymbuddy"
  cd Q:\
  flutter analyze lib
  cd C:\
  subst Q: /D
  ```

  Building and running work without this. Putting the repo and the pub cache
  (`PUB_CACHE`, for example `C:\src\pub-cache`) under an ASCII path avoids the
  problem entirely.
- **Long paths:** `git worktree add` into a deep folder fails on
  `firebase_emulator_data/...` with "Filename too long". Use a short path, or
  run `git config core.longpaths true`.
- **Two JDKs:** set `JAVA_HOME` to JDK 17 for `flutter build` / `flutter run`,
  and to JDK 21 for `firebase emulators:start`. Setting it per shell is easiest.

## 7. Project layout

```
lib/
  main.dart               app entry, calls firebaseInit()
  routes.dart             named routes
  consts/                 UI strings, GlobalConsts (backend switch), test data
  data/
    repository/<feature>/ Firestore / Storage access, one per screen
    service/              geolocation, platform, Algolia search
  ui/<feature>/
    view_models/          ChangeNotifier / ValueNotifier state (MVVM)
    widgets/              screens
assets/budapest_gyms.csv  gym list, made by gym_scraping/scrape_gyms.py
firebase_emulator_data/   emulator seed (Firestore + Storage export)
integration_test/         page tests and database population scripts
test/                     widget tests
```

Each new screen follows the MVVM split already used in `ui/profile` and
`ui/search`: the repository talks to Firebase, the view model holds state, and
the widget only renders.

## 8. Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| "An unknown error occurred" on signup or login | The build is using production. Rebuild with `--dart-define=USE_EMULATORS=true` |
| Home feed is empty | There are no posts at gyms within 1 km. Check the GPS fix (step 3) and the `posts` in the emulator UI. Widening the radius is a Phase 1 item |
| Search returns nothing | `lib/auth/secrets.dart` is missing or wrong. Search uses Algolia, not the emulators |
| `Could not resolve` / AGP errors in Gradle | Your `android/` is older than the Gradle 8.14.3 / AGP 8.11.1 / Kotlin 2.2.20 upgrade. Get a current copy |
| Firebase emulators won't start | Wrong Java version (needs 21+), or something else is using port 8080/9199 |
| `flutter analyze` crashes with `FormatException` | Non-ASCII path. See section 6 |

The roadmap is in `Gym Buddy Plan to Finish the App.pdf`.
