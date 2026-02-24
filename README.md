# Suhoor Wake-Up Circle

Suhoor Wake-Up Circle is a Flutter app for waking up with your squad.
It combines a personal wake challenge with a shared squad status flow, so each member can confirm they are awake.

## Project Goal

Build a simple, focused social wake-up experience where:

- One person can start/host a circle.
- Friends can join through QR.
- Everyone can confirm they are awake.
- The group can see wake status in one place.

## Project Status (Updated: Feb 23, 2026)

This project is in **active MVP** state.

### Working now

- App shell with 3 tabs: Dashboard, Squads, Challenge.
- Alarm scheduling and persistence with the `alarm` package.
- Wake challenge flow (math keypad) to confirm awake status.
- Squad join flow using QR scan + payload parsing.
- Circle/member state persistence via `SharedPreferences`.
- Leaderboard history, rankings, and streak calculations.
- Hybrid P2P repository with transport abstraction.

### In progress / not production-ready yet

- Nearby transport is implemented and Android-focused.
- Wi-Fi P2P transport is still a simulated fallback implementation.
- End-to-end multi-device reliability testing is still ongoing.
- UX polish, hardening, and production rollout tasks remain.

## Screenshots

Add your screenshots under a `screenshots/` folder at the project root, then update/replace these image files:

![Dashboard](screenshots/dashboard.png)
![Challenge](screenshots/challenge.png)
![Join Squad](screenshots/join-squad.png)

Suggested captures:

- Dashboard tab with wake button and squad status.
- Challenge tab showing the math challenge keypad.
- Join Squad tab (and QR scan screen).

## Features

- **Wake Dashboard**
	- Large wake action button.
	- Live squad status summary.
	- Current user + members awake indicators.

- **Wake Challenge**
	- Random math challenge generation.
	- Numeric keypad input and answer validation.
	- Success callback into dashboard wake confirmation flow.

- **Squad Join**
	- QR scanning flow using mobile camera.
	- Invitation payload parsing and circle join.
	- Manual member naming support.

- **Circle / Session Management**
	- Circle creation and invitation payload generation.
	- Wake event broadcast model.
	- Awake confirmations and member status updates.
	- Local persistence for peer identity, circle, settings, and active wake event.

- **Alarm Scheduling**
	- Local alarm setup and cancellation.
	- Persisted alarm time/state across app restarts.
	- Alarm-triggered wake-up experience into challenge flow.

- **Leaderboard**
	- Wake history tracking per member.
	- Rank calculations across time windows.
	- Streak computation and top-member display.

- **Permissions Handling**
	- Android permission flow for location / nearby devices / bluetooth scan.
	- Camera permission flow for QR scanning.

## Why I Built It

Suhoor can be difficult to wake up for consistently, especially when doing it alone.
This project was built to make waking up more accountable and social:

- Turn wake-up into a shared squad routine.
- Add a small cognitive challenge to avoid instantly snoozing.
- Keep the UX lightweight and focused on one daily problem.

## Tech Stack

- **Framework:** Flutter (Dart)
- **State management:** Provider + ChangeNotifier
- **Storage:** SharedPreferences
- **Alarm scheduling:** alarm
- **QR scanning:** mobile_scanner
- **QR generation:** qr_flutter
- **P2P connectivity:** nearby_connections (Android path)
- **Permissions:** permission_handler
- **Typography/UI:** Google Fonts + Material 3
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux (Flutter targets)

Main dependencies are defined in `pubspec.yaml`:

- `provider`
- `shared_preferences`
- `mobile_scanner`
- `qr_flutter`
- `alarm`
- `nearby_connections`
- `permission_handler`
- `google_fonts`

## Architecture Explanation

The app follows a lightweight feature-first structure with separated domain contracts and services:

```
lib/
	main.dart
	home_screen.dart
	core/
		circle_models.dart
		p2p_contracts.dart
		permissions.dart
	features/
		dashboard/
		challenge/
		leaderboard/
	services/
		alarm/
			alarm_service.dart
		circle/
			wake_circle_service.dart
		leaderboard/
			history_service.dart
		p2p/
			p2p_repository_factory.dart
			hybrid_p2p_repository.dart
			nearby_connections_transport.dart
			wifi_p2p_connection_transport.dart
```

### Layers

- **UI Layer (`features/*`)**
	- Screens and ViewModels.
	- Uses Provider to bind UI to state.

- **Core Layer (`core/*`)**
	- Shared models (`WakeCircle`, `CircleMember`, `WakeEvent`, etc).
	- P2P contracts and message envelope definitions.
	- Permission helper abstraction.

- **Service Layer (`services/*`)**
	- `WakeCircleService`: orchestrates circle lifecycle, wake events, persistence, and transport events.
	- P2P repository + transports: communication abstraction with primary/fallback strategy.

### State Flow (High Level)

1. UI action occurs (wake, scan QR, mark awake).
2. ViewModel calls `WakeCircleService`.
3. Service updates in-memory models and persisted data.
4. Service emits `notifyListeners`.
5. UI rebuilds via Provider consumers/watchers.

## How to Run

### Prerequisites

- Flutter SDK installed (compatible with Dart `^3.10.0` from `pubspec.yaml`).
- Android Studio / Xcode / VS Code Flutter tooling depending on target platform.
- A connected device or running emulator/simulator.

### Steps

1. Install dependencies:

	 ```bash
	 flutter pub get
	 ```

2. Verify environment:

	 ```bash
	 flutter doctor
	 ```

3. Run the app:

	 ```bash
	 flutter run
	 ```

4. (Optional) Run tests:

	 ```bash
	 flutter test
	 ```

### Android permission notes

For QR + nearby discovery flows on Android, grant requested permissions when prompted:

- Location (while in use)
- Nearby Wi-Fi Devices
- Bluetooth Scan
- Camera

## Roadmap (Next)

### v0.2 — Reliability Foundation

- Add recurring alarm support with day-based scheduling.
- Improve alarm behavior across app restart, device reboot, and background state.
- Finalize circle reconnect flows (rejoin, stale-session cleanup).
- Add unit tests for alarm and circle services.

### v0.3 — Feature Completeness

- Complete production-grade Wi-Fi transport path to complement Nearby.
- Improve host/join sync stability on real Android devices.
- Expand leaderboard with weekly reset, streak badges, and missed-day insights.
- Add widget/integration tests for challenge, join, and wake-confirm flows.

### Beta — Release Readiness

- Add crash/error reporting and basic product analytics.
- Complete QA matrix across supported Android versions/devices.
- Polish onboarding and permission UX for first-time users.
- Prepare store assets, release notes, and internal beta rollout checklist.
