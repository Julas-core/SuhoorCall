# Suhoor Wake-Up Circle

Suhoor Wake-Up Circle is a Flutter app for waking up with your squad before Fajr.
It combines a personal wake challenge with a shared squad status flow, so each member can confirm they are awake.

## Project Goal

Build a simple, focused social wake-up experience where:

- One person can start/host a circle.
- Friends can join through QR.
- Everyone can confirm they are awake.
- The group can see wake status in one place.

## Current State (as of Feb 2026)

This is an active MVP/prototype with core flows implemented:

- App shell with 3 tabs: Dashboard, Squads (Join), Challenge.
- Wake challenge (math keypad) used to dismiss/confirm wake-up.
- Squad joining flow with QR scanner UI and payload handling.
- Circle state and wake status persistence via SharedPreferences.
- P2P architecture contracts + hybrid repository (primary + fallback transport).

Important implementation note:

- The current P2P transport classes are scaffolded/simulated (event-driven mock behavior), designed so real Nearby/Wi-Fi Direct integrations can be plugged in behind the same contracts.

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
- **QR scanning:** mobile_scanner
- **Permissions:** permission_handler
- **Typography/UI:** Google Fonts + Material 3
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux (Flutter targets)

Main dependencies are defined in `pubspec.yaml`:

- `provider`
- `shared_preferences`
- `mobile_scanner`
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
		circle/
			wake_circle_service.dart
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

- Replace simulated transport behavior with production Nearby/Wi-Fi Direct implementation.
- Add real alarm scheduling + background wake trigger.
- Persist leaderboard history and streak calculations.
- Add end-to-end squad host/join testing on physical devices.
