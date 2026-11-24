# Evidence for my Streak pull requests

These files only back up the screenshots and recordings in the PR descriptions. None of them are part of a PR.

## pr-581: one new habit form at a time (InlitX/streak#581, #573)

The same demo runs on two targets.

- **macOS** (`before.*`, `after.*`):
  the real macOS app (debug build, Flutter 3.41.9, macOS 27.3) on a 1728×1052 window. Frames are the app's own rendered output, captured from inside the test about 8 times a second. The tap marker is Flutter's test pointer overlay. Pauses where capture stalled are cut to 0.6 s.
- **iPadOS** (`ipad-*`): the iPad Pro 13-inch (M5) Simulator, iOS 27.3, portrait (1032 pt wide, so the split layout is on). Recorded with `xcrun simctl io recordVideo`.

`demo_test.dart` is a Flutter integration test that drives the app. It:

1. seeds two habits;
2. clicks "+";
3. types "Drink water" into the form;
4. clicks "+" twice more;
5. goes back once.

| Files | Built from |
|---|---|
| `before.*`, `ipad-before.*` | `main` @ dbd6365 |
| `after.*`, `ipad-after.*` | the same tree with `lib/features/habits/pages/home_page.dart` from the PR (02641b5) |

The only other local changes were the Xcode 27 build fixes from #582 (needed to build at all) and, on macOS, a separate bundle ID so the demo data stays apart from real data.

Form count after each step, from the test log (the same on macOS and iPad):

| Step | before | after |
|---|---|---|
| click 1 | 1 | 1 |
| click 2 | 2 | 1 |
| click 3 | 3 | 1 |
| back once | 2 | 0 |

## pr-582: build with Xcode 27 (InlitX/streak#582, #516)

Flutter 3.41.9, Xcode 27.3, macOS 27.3. Paths in the logs are shortened to `streak/`.

| File | What it shows |
|---|---|
| `before-main.png` | `main` fails to build for iOS and macOS on the deployment targets |
| `before-rename.png` | `main` with only the deployment-target commit still fails on the Swift rename |
| `after-branch.png` | the PR branch: analyze clean, iOS release and macOS debug build |
| `after-macos.png` | the PR branch running on macOS (first-run screen) |
| `after-ios-sim-*` | the PR branch running in the iPhone 18 Pro Simulator, iOS 27.3 (debug build) |
