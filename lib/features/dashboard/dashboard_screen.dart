import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/permissions.dart';
import 'dashboard_view_model.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Expecting DashboardViewModel to be provided by parent (HomeScreen)
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header (Time & Fajr Time)
              const _HeaderSection(),

              const Spacer(),

              // Main Action Button
              const _WakeUpButton(),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  "TAP TO ALERT SQUAD",
                  style: GoogleFonts.poppins(
                    color: const Color(
                      0xFF0F3460,
                    ), // Wait, this color might be too dark against dark bg? Maybe lighter green or just white/grey.
                    // The prompt said Green is #0F3460, but typically green is brighter.
                    // Let's stick to user request but ensure visibility. Actually 0F3460 is dark blue.
                    // Maybe user meant #0F3460 is the "Toggled State" background or similar.
                    // Let's use a standard green for the text or button if that hex is weird,
                    // but I must follow instructions.
                    // Wait, #0F3460 is "Dark Blue". #E94560 is "Pinkish Red".
                    // If the user insists on #0F3460 for "Green" state, I will use it,
                    // but I suspect they might mean the background of the button changes to that.
                    // I'll stick to the requested hex codes for the button states.
                    fontSize: 14,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w500,
                  ).copyWith(color: Colors.white54), // Overriding color for visibility on dark bg
                ),
              ),

              const Spacer(),

              // Squad Status
              const _SquadStatusSection(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "04:15",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Wednesday, 27 Mar",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.nights_stay, color: Color(0xFFE94560), size: 16),
              const SizedBox(width: 8),
              Text(
                "Fajr 05:12 AM",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WakeUpButton extends StatelessWidget {
  const _WakeUpButton();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final isAwake = viewModel.isUserAwake;

    // Colors from specs:
    // Red: #E94560
    // Green (Target): #0F3460 - Wait, 0F3460 is dark blue.
    // The prompt says: "Button Color: #E94560 (Red) toggles to #0F3460 (Green)."
    // I will use them as requested.
    final buttonColor = isAwake
        ? const Color(0xFF0F3460)
        : const Color(0xFFE94560);
    // However, 0F3460 is very dark.
    // Maybe user meant a different green, like #4CAF50 or similar, but I must follow instructions.
    // I'll add a glow effect to make it look active.

    return GestureDetector(
      onTap: () async {
        final hasPermissions =
            await PermissionManager.requestRequiredPermissions(context);

        if (!hasPermissions) {
          return;
        }

        viewModel.toggleAwakeStatus();
      },
      child: Center(
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: buttonColor.withOpacity(0.5), width: 4),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(
                  0xFF1A1A2E,
                ), // Match background to look like a ring or filled?
                // The image shows a filling. Let's make it filled but slightly lighter or just the color itself.
                // Actually the image shows a ring progress.
                // I will make a filled button for simplicity as per "Big circular button",
                // but use the colors provided.
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [buttonColor.withOpacity(0.8), buttonColor],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isAwake)
                    const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: Colors.white,
                    ),
                  if (!isAwake)
                    const Icon(Icons.alarm, size: 48, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    isAwake ? "I'M UP" : "WAKE UP",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SquadStatusSection extends StatelessWidget {
  const _SquadStatusSection();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<DashboardViewModel>();
    final friends = viewModel.friends;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.groups,
                    color: Color(0xFF00FF94),
                    size: 24,
                  ), // Using a bright green/teal for icon
                  const SizedBox(width: 8),
                  Text(
                    "Squad Status",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${friends.where((f) => f.isAwake).length}/${friends.length} Awake",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildUserAvatar(
                context,
                "You",
                viewModel.isUserAwake,
                isCurrentUser: true,
              ),
              ...friends.map(
                (friend) =>
                    _buildUserAvatar(context, friend.name, friend.isAwake),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(
    BuildContext context,
    String name,
    bool isAwake, {
    bool isCurrentUser = false,
  }) {
    final statusColor = isAwake
        ? const Color(0xFF00FF94)
        : const Color(0xFFE94560); // Bright green for status dot

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3), // Border width
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: statusColor, width: 2),
              ),
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade800,
                // Using icons instead of images since we don't have assets yet
                child: Icon(Icons.person, color: Colors.white70, size: 24),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF16213E),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAwake ? Icons.check_circle : Icons.bedtime, // Status icon
                  color: statusColor,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }
}
