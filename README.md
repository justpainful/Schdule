<div align="center">

# Schdule

A native iOS tracker for habits, routines and monthly progress.

</div>

## Overview

Schdule turns the familiar monthly paper grid into a native iPhone app. Each board tracks one routine and each day records the value that belongs to that routine.

Boards can track completion, counts, amounts, timed sessions, ratings and habits the user wants to avoid.

Everything is stored locally. There are no accounts, analytics or network services.

## Features

- Six board types
- Monthly grid with clear daily state
- Habit and anti-habit tracking
- Home Screen and Lock Screen widgets
- StandBy and Control Center support
- Siri, Shortcuts and Spotlight integration
- Local reminders
- Calendar mirroring
- Face ID protected boards
- Arabic and English UI
- RTL support
- PDF, CSV and JSON export

## Platform

| Area | Implementation |
|---|---|
| App | SwiftUI |
| Minimum platform | iOS 26 |
| UI | Native Liquid Glass |
| Storage | SwiftData |
| Widgets | WidgetKit |
| Automation | App Intents |
| Privacy | Local only |

## Building

The Xcode project is generated with XcodeGen.

```bash
brew install xcodegen
xcodegen generate
open Schdule.xcodeproj
```

Requires Xcode 26 and an iOS 26 simulator or device.

## CI

Development is also verified on GitHub Actions using a macOS runner. The workflow builds the project, runs tests, drives the UI test tour and uploads screenshots for review.

Download the latest screenshot artifact with:

```bash
gh run download --name screenshots --dir ./review
```

Unsigned IPA builds are also produced by CI:

```bash
gh run download --name Schdule-unsigned-ipa
```

## Project layout

```text
App/Schdule/              App target
Widgets/SchduleWidgets/   Widgets and controls
Packages/SchduleKit/      Shared framework
Tests/SchduleKitTests/    Unit tests
UITests/SchduleUITests/   UI and screenshot tests
project.yml               XcodeGen manifest
```

`SchduleKit` contains the model, statistics, storage, design, export and App Intents modules used across the app and extensions.

## Privacy

Private boards can require Face ID and are excluded from widgets, Spotlight, Siri, Insights and reminders while locked. App data remains on the device unless the user explicitly exports it.