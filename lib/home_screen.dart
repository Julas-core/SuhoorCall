import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/challenge/challenge_screen.dart';
import 'features/leaderboard/leaderboard_screen.dart'; // Import LeaderboardScreen
import 'features/leaderboard/join_squad_view_model.dart';
import 'features/dashboard/dashboard_view_model.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToDashboardAndMarkAwake() {
    // Mark as awake
    // We need to access the DashboardViewModel.
    // Since DashboardScreen has its own ChangeNotifierProvider, we might need to lift the state up
    // or access it if it was provided above.
    //
    // Looking at DashboardScreen, it creates the provider:
    // ChangeNotifierProvider(create: (_) => DashboardViewModel(), ...)
    //
    // This means the state is local to DashboardScreen and lost when we switch tabs if purely switching widgets.
    // However, usually for a tab app, we want the state to persist.
    // I should probably lift the ChangeNotifierProvider to main.dart or HomeScreen.
    //
    // For now, I will keep the structure simple but be aware that switching tabs might reset Dashboard state
    // if I just simply toggle bodies. usage of IndexedStack helps preserve state.

    setState(() {
      _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // We need to hoist the DashboardViewModel so it can be accessed by the ChallengeScreen's onDismissed
    // (if we want to update the dashboard state) and to persist across tab switches.
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            const DashboardScreen(), // We need to update DashboardScreen to consume the provider instead of creating it
            const LeaderboardScreen(), // Leaderboard Screen
            Consumer<DashboardViewModel>(
              builder: (context, viewModel, _) {
                return ChallengeScreen(
                  onDismissed: () async {
                    viewModel.markAsAwake();
                    await JoinSquadViewModel.markCurrentDeviceAwakePersisted();
                    _navigateToDashboardAndMarkAwake();
                  },
                );
              },
            ),
          ],
        ),
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF16213E),
            selectedItemColor: const Color(0xFFE94560),
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(),
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.leaderboard_outlined),
                activeIcon: Icon(Icons.leaderboard),
                label: 'Squads',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alarm),
                activeIcon: Icon(
                  Icons.alarm_on,
                ), // Or create a custom challenge icon
                label: 'Challenge',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
