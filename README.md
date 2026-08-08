# Schdule

A monthly schedule tracker for iOS 26, built to replace the hand-drawn paper
grid: one board per habit, one cell per day, and — unlike paper — a cell that
can say *"three times today"*.

Native SwiftUI, native Liquid Glass, **fully local**: no account, no sync, no
network calls, no analytics. There is nowhere for the data to go.

## What it does

**Six kinds of board.** Did-it, how-many-times, an amount with a unit, a timed
session, a one-to-five rating, and — the one that changes the shape of the app —
**avoiding**. On an anti-habit the polarity flips: a day you log nothing is the
day that went well, the streak counts days clean, and a rising trend is coloured
red rather than green. Habits and anti-habits are kept in separate sections
throughout, because a full row of marks means opposite things on each.

**The month grid.** Each cell shows a tick for one, a numeral for two or more,
with the tint deepening behind it. The numeral carries the information and the
tint is decoration, so the grid stays readable with colour-blindness, with
Increase Contrast, and at widget scale. A missed day and a day that has not
arrived yet are drawn differently — otherwise a month in progress looks like a
month of failures.

**Everywhere else.** Home Screen widgets (small, medium, large), Lock Screen
widgets, StandBy, a Control Centre / Action button control, Siri and Shortcuts
in Arabic and English, Spotlight, local reminders with a Log button on the
banner, and a Calendar mirror that writes to its own calendar so deleting one
calendar undoes all of it.

**Sharing.** Three poster styles — a card for a chat, a 9:16 story, and a
monospaced receipt — plus PDF, CSV, and a full JSON backup. Nothing syncs, so an
export is the only copy that outlives the phone.

**Private boards.** Any board can require Face ID. A locked board is withheld
from widgets, Spotlight, Siri, Insights, and reminders — the name alone is
usually the sensitive part — and re-locks whenever the app leaves the
foreground.

Arabic and English throughout, with real RTL layout.

## Getting the app

Every push builds an unsigned `.ipa`, downloadable from the run's artifacts:

```bash
gh run download --name Schdule-unsigned-ipa
```

It is unsigned on purpose — this repository holds no certificate and no
provisioning profile, and should not. Install it with a sideloader (AltStore,
Sideloadly, TrollStore), which re-signs it with your own Apple ID.

## Building

The Xcode project is **generated, not committed**:

```bash
brew install xcodegen && xcodegen generate && open Schdule.xcodeproj
```

Requires Xcode 26 and an iOS 26 simulator or device.

## The CI screenshot loop

Development happens on Windows, where Xcode does not exist, so every build,
test, and screenshot runs on a GitHub Actions `macos-26` runner. Each push:

1. builds every target and runs the Swift Testing suite,
2. drives `SchduleUITests` through a scripted tour on an iPhone 17 Pro
   simulator, in Arabic and English, light and dark,
3. extracts the frames from the `.xcresult` with `xcresulttool`,
4. uploads them for visual review, and packages the unsigned IPA.

```bash
gh run download --name screenshots --dir ./review
```

Screens are photographed on a real simulator rather than rendered offscreen
because `ImageRenderer` cannot reproduce `.glassEffect` — Liquid Glass works by
sampling the backdrop it composites over, and an offscreen renderer has none.

Under `-UITestMode` the app runs on an in-memory store seeded with a fixed
August 2026 and a frozen "today", so frames are comparable between rounds
instead of drifting with the wall clock. Locale and first-day-of-week stay live,
since those are exactly what the Arabic frames exist to exercise.

## Layout

```
App/Schdule/            app target
  Root/                   Today, Boards, board detail, Insights
  Editor/                 board editor, day editor, templates
  Export/                 share sheet
  Settings/               appearance, reminders, calendar, data export
  Support/                store wiring, seeding, biometrics, shortcuts
Widgets/SchduleWidgets/ widget extension, Lock Screen widgets, control
Packages/SchduleKit/    one dynamic framework, six modules
  SchduleModel/           value types, calendar arithmetic
  SchduleStats/           streaks, completion, weekday and overlap analysis
  SchduleStore/           SwiftData, reminders, calendar mirror
  SchduleDesign/          tokens, DayCell, MonthGrid, glass chrome
  SchduleExport/          posters, PDF, CSV, JSON
  SchduleIntents/         App Intents, entities, widget reads
Tests/SchduleKitTests/  Swift Testing unit suite
UITests/SchduleUITests/ scripted screenshot tour
project.yml             XcodeGen manifest — the source of truth
```

The package ships as **one dynamic framework** rather than six static libraries.
The AppIntents metadata processor refuses a build where an app and an embedded
extension both statically link a library declaring the same App Entity, and
static linking would have put two copies of the same `@Model` classes in one
process.
