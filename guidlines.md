# Project: Suhoor Wake-Up Circle (Offline P2P)
# Tech Stack: 
- Framework: Flutter (Dart)
- Architecture: MVVM (Model-View-ViewModel) with Provider or Riverpod
- Platform: Android (Min SDK 21) & iOS
- Key Libraries: `flutter_p2p_connection`, `flutter_nearby_connections`, `audioplayers`

# Core Constraints (The "Do Not" Section):
1. NO Internet usage. All features must work via Bluetooth/Wi-Fi Direct.
2. NO Google Play Services (Firebase, etc.). 
3. DO NOT use complex state management for simple UI; keep it readable.
4. ALWAYS handle permissions (Location, Nearby Devices) gracefully.

# Coding Style:
- Use specific variable names (e.g., `isUserAwake` instead of `flag`).
- Create separate files for Widgets.
- Verify all P2P connections with a "Handshake" string before trusting them.