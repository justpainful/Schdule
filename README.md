# Schdule

A monthly schedule tracker for iOS 26, built to replace the hand-drawn paper grid:
one board per habit, one cell per day, and — unlike paper — a cell that can say
*"three times today"*.

Native SwiftUI, native Liquid Glass, **fully local**: no accounts, no sync, no
network. Your data never leaves the device.

## Status

| Milestone | Scope | State |
|---|---|---|
| M0 | Repo scaffold, XcodeGen project, CI screenshot loop | in progress |
| M1 | SwiftData model, store, streak/stats engine | pending |
| M2 | Design system, `DayCell`, month grid, Today dashboard | pending |
| M3 | Notes-style folders & navigation, Liquid Glass polish | pending |
| M4 | Export posters, PDF/CSV/JSON, share sheet | pending |
| M5 | Home Screen / Lock Screen / StandBy widgets, Control Center | pending |
| M6 | App Intents, Shortcuts, Spotlight, Live Activity | pending |
| M7 | Local notifications, EventKit, Face ID board lock | pending |
| M8 | Arabic + English, RTL, accessibility | pending |
| M9 | App icon, TipKit, onboarding, performance | pending |

## Building

The Xcode project is **generated, not committed**. You need
[XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen && xcodegen generate && open Schdule.xcodeproj
```

Requires Xcode 26 and an iOS 26 simulator or device.

## The CI screenshot loop

Development happens on Windows, where Xcode does not exist, so every build,
test, and screenshot runs on a GitHub Actions `macos-26` runner. Each push:

1. builds the project and runs the Swift Testing unit suite,
2. drives `SchduleUITests` through a scripted tour on an iPhone 17 Pro simulator,
3. extracts the screenshots from the `.xcresult` with `xcparse`,
4. uploads them as artifacts for visual review.

Pull the latest set locally with:

```bash
gh run download --name screenshots-en-light --dir ./review
```

Screens are photographed on a real simulator rather than rendered offscreen
because `ImageRenderer` cannot reproduce `.glassEffect` — Liquid Glass works by
sampling the backdrop it composites over, and an offscreen renderer has none.

Under `-UITestMode` the app freezes "today" to 8 August 2026 and runs on a
UTC calendar, so screenshots are comparable between rounds instead of drifting
with the wall clock.

## Layout

```
App/Schdule/            app target
Packages/SchduleKit/    local SPM package shared by app, widgets, and intents
  SchduleModel/           value types, enums, calendar math
  SchduleDesign/          tokens, DayCell, MonthGrid, glass chrome
Tests/SchduleKitTests/  Swift Testing unit suite
UITests/SchduleUITests/ scripted screenshot tour
project.yml             XcodeGen manifest — the source of truth for the project
```
