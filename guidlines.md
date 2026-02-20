# Suhoor Wake-Up Circle — Implementation Checklist (Feb 2026)

This file tracks what is still unimplemented and where to build it.

## Current Reality (Quick Summary)

- Core MVP screens exist (Dashboard, Squads/Join, Challenge).
- QR creation/scanning flow exists.
- Member wake status persistence exists via SharedPreferences.
- P2P repository contracts exist.
- P2P transports are currently simulated (mock event behavior), not production Nearby/Wi-Fi Direct.
- Circle domain/service architecture described in README is not implemented yet.

---

## Priority Order

1. **P0** Build real Circle domain + service layer and move business logic out of UI ViewModels.
2. **P0** Replace simulated transports with production transport implementations.
3. **P1** Add alarm scheduling + background wake trigger.
4. **P1** Add persistent wake history + streak/leaderboard calculations.
5. **P2** Add testing coverage and README assets cleanup (screenshots).

---

## P0 — Circle Domain + Service Layer

### Target files

- `lib/core/circle_models.dart` (currently empty)
- `lib/services/circle/wake_circle_service.dart` (currently empty)
- `lib/features/leaderboard/join_squad_view_model.dart`
- `lib/features/dashboard/dashboard_view_model.dart`

### TODO

- Define core models in `circle_models.dart`:
	- `WakeCircle`
	- `CircleMember`
	- `WakeEvent`
	- `MemberWakeStatus` (single shared enum)
- Implement `WakeCircleService` in `wake_circle_service.dart`:
	- create/join circle
	- start wake event
	- mark member awake
	- broadcast/consume transport events
	- persistence for circle, members, active event
- Refactor `JoinSquadViewModel` to delegate business logic to `WakeCircleService`.
- Refactor `DashboardViewModel` to read circle state from `WakeCircleService` instead of static helper methods.

### Definition of done

- `JoinSquadViewModel` and `DashboardViewModel` become UI-focused only.
- No duplicate wake/member logic spread across multiple view models.
- Circle state and wake lifecycle are managed by one service source of truth.

---

## P0 — Real P2P Transport Implementations

### Target files

- `lib/services/p2p/nearby_connections_transport.dart`
- `lib/services/p2p/wifi_p2p_connection_transport.dart`
- `lib/services/p2p/hybrid_p2p_repository.dart`
- `lib/core/permissions.dart`
- Platform files under `android/` (and optionally `ios/` if supported)

### TODO

- Replace timer-based mock discovery with real discovery APIs.
- Implement real connect/disconnect lifecycle and error handling.
- Implement actual message send/receive, mapping native callbacks to `P2pTransportEvent`.
- Keep handshake verification path (`SessionNonceHandshakeVerifier`) intact and enforced.
- Harden transport failover behavior in `HybridP2pRepository`:
	- primary unavailable -> fallback
	- connection-loss retry/fallback strategy
- Re-check runtime permissions and Android manifest requirements for chosen transport libraries.

### Definition of done

- Two physical devices can host/join and exchange wake events without simulated events.
- No local echo pretending to be remote traffic.

---

## P1 — Alarm Scheduling + Background Wake Trigger

### Target files

- `pubspec.yaml`
- new service file: `lib/services/alarm/alarm_service.dart`
- `lib/features/dashboard/dashboard_screen.dart` (or settings entry point)
- platform setup files in `android/` (+ `ios/` if needed)

### TODO

- Add alarm/background package(s) suitable for Flutter + Android focus.
- Implement `AlarmService` with:
	- schedule alarm
	- cancel/update alarm
	- trigger Challenge flow on alarm fire
- Persist next alarm configuration in SharedPreferences.
- Add minimal UI to set/manage wake time (MVP scope only).

### Definition of done

- Alarm triggers reliably when app is backgrounded (as platform permits).
- Challenge flow can be entered from an alarm trigger path.

---

## P1 — History + Streak + Leaderboard Logic

### Target files

- `lib/features/leaderboard/leaderboard_view_model.dart` (currently mock-only)
- new files under `lib/services/leaderboard/`
- optionally `lib/core/circle_models.dart` for history models

### TODO

- Replace mock leaderboard entries with persisted/generated data.
- Persist wake history records (date, member id, status, completion time).
- Add streak calculation service:
	- current streak
	- longest streak
	- today completed / missed rules
- Render leaderboard from computed data.

### Definition of done

- Leaderboard survives app restart and reflects real session history.
- Streak values are calculated, not hardcoded.

---

## P2 — Tests + README Completeness

### Target files

- `test/widget_test.dart`
- new tests under `test/services/` and `test/features/`
- `README.md`
- `screenshots/` (new folder)

### TODO

- Add unit tests for:
	- handshake validation
	- wake event transitions
	- member status updates
	- streak calculations
- Add widget tests for:
	- challenge solve -> mark awake path
	- create circle -> QR visible
	- scan join flow (with mocked scanner result)
- Add required screenshots referenced by README.

### Definition of done

- Core domain/service logic is test-covered.
- README screenshots render and match current UI.

---

## Guardrails

1. No internet backend required for MVP; flows must continue to work locally.
2. Keep provider-based architecture unless there is a clear migration reason.
3. Put domain logic in services/models, not in widget files.
4. Keep permission handling explicit and user-friendly.
5. Preserve handshake validation for any peer trust decision.

---

## Suggested Execution Plan (Sprint-Friendly)

- **Sprint 1:** Circle models + `WakeCircleService` + ViewModel refactor.
- **Sprint 2:** Real Nearby/Wi-Fi Direct transport integration on Android.
- **Sprint 3:** Alarm scheduling/background trigger + minimal alarm settings UI.
- **Sprint 4:** History/streak leaderboard + tests + README screenshots.