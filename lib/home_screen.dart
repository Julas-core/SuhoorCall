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
    setState(() {
      _selectedIndex = 0;
    });
  }

  void _showAwakeChallenge(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return Consumer<DashboardViewModel>(
            builder: (context, viewModel, _) {
              return ChallengeScreen(
                onDismissed: () async {
                  viewModel.markAsAwake();
                  await JoinSquadViewModel.markCurrentDeviceAwakePersisted();
                  if (!context.mounted) {
                    return;
                  }
                  Navigator.of(context).maybePop();
                  _navigateToDashboardAndMarkAwake();
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(),
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardScreen(onAwakePressed: () => _showAwakeChallenge(context)),
            const LeaderboardScreen(),
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
            ],
          ),
        ),
      ),
    );
  }
}
