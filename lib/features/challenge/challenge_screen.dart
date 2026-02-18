import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'challenge_view_model.dart';
import 'dart:async';

class ChallengeScreen extends StatelessWidget {
  final VoidCallback onDismissed;

  const ChallengeScreen({super.key, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChallengeViewModel(),
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E), // Dark Navy
        body: SafeArea(child: _ChallengeContent(onDismissed: onDismissed)),
      ),
    );
  }
}

class _ChallengeContent extends StatefulWidget {
  final VoidCallback onDismissed;

  const _ChallengeContent({required this.onDismissed});

  @override
  State<_ChallengeContent> createState() => _ChallengeContentState();
}

class _ChallengeContentState extends State<_ChallengeContent> {
  Timer? _timer;
  String _timeString = "00:00";
  String _dateString = "";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  void _updateTime() {
    final now = DateTime.now();
    // Simulate the time in the screenshot "04:30" or use real time?
    // Usually best to use real time.
    // Format: HH:mm
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    // Format: Weekday, DD Month
    // Basic implementation since intl package not added yet?
    // I added google_fonts previously. I might not have intl.
    // I'll do a simple custom formatter or just hardcode the "Wednesday, 12 March" style if I can't easily do it without deps.
    // Actually, I can do basic formatting.
    const monthNames = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    const weekDays = [
      "",
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
      "Saturday",
      "Sunday",
    ];

    if (mounted) {
      setState(() {
        _timeString = "$hour:$minute";
        _dateString =
            "${weekDays[now.weekday]}, ${now.day} ${monthNames[now.month]}";
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChallengeViewModel>();

    if (viewModel.isSolved) {
      // Small delay to show result before dismissing
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only call once
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          Future.delayed(const Duration(milliseconds: 300), widget.onDismissed);
        }
      });
    }

    return Column(
      children: [
        const SizedBox(height: 20),
        // Top Header: SUHOOR ALARM
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm_on, color: Color(0xFF00FF94), size: 20),
            const SizedBox(width: 8),
            Text(
              "SUHOOR ALARM",
              style: GoogleFonts.poppins(
                color: const Color(0xFF00FF94),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Clock
        Text(
          _timeString,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 64,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        Text(
          _dateString,
          style: GoogleFonts.poppins(color: Colors.white60, fontSize: 16),
        ),

        const SizedBox(height: 30),

        // Challenge Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF16213E), // Slightly lighter navy
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              children: [
                // Card Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Wake Up Challenge",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Solve to dismiss the alarm",
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      backgroundColor: Color(0xFF1A3A40), // Dark green bg
                      radius: 20,
                      child: Icon(
                        Icons.calculate,
                        color: Color(0xFF00FF94),
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Math Problem
                // "14 + 27 =" ... "?"
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      viewModel.problemText,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // If we want the "?" distinct or below, we can adjust.
                    // The screenshot shows: 14 + 27 =
                    //                     ?
                    // But simplified: "14 + 27 = ?"
                  ],
                ),
                const Text(
                  "?",
                  style: TextStyle(
                    color: Color(0xFF00FF94),
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Input Field
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1525), // Very dark box
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: viewModel.isSolved
                          ? const Color(0xFF00FF94)
                          : Colors.white10,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      viewModel.input.isEmpty ? "|" : "${viewModel.input}|",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Keypad
                _buildKeypad(context, viewModel),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildKeypad(BuildContext context, ChallengeViewModel viewModel) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey(context, "1", () => viewModel.addDigit("1")),
            _buildKey(context, "2", () => viewModel.addDigit("2")),
            _buildKey(context, "3", () => viewModel.addDigit("3")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey(context, "4", () => viewModel.addDigit("4")),
            _buildKey(context, "5", () => viewModel.addDigit("5")),
            _buildKey(context, "6", () => viewModel.addDigit("6")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKey(context, "7", () => viewModel.addDigit("7")),
            _buildKey(context, "8", () => viewModel.addDigit("8")),
            _buildKey(context, "9", () => viewModel.addDigit("9")),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Opacity(
              opacity: 0.0,
              child: _buildKey(context, "", () {}),
            ), // Placeholder
            _buildKey(context, "0", () => viewModel.addDigit("0")),
            _buildKey(
              context,
              "⌫",
              () => viewModel.removeDigit(),
              isDestructive: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    bool isDestructive = false,
  }) {
    // If text is backspace symbol "⌫" or use icon?
    // Screenshot shows an icon (backspace-outlined).

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80,
        height: 60,
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFF2C1E25) // Reddish dark for backspace
              : const Color(0xFF1F293A), // Dark blue/grey for numbers
          borderRadius: BorderRadius.circular(16),
          border: isDestructive
              ? Border.all(color: const Color(0xFFE94560).withOpacity(0.3))
              : null,
        ),
        child: Center(
          child: isDestructive && text == "⌫"
              ? const Icon(Icons.backspace_outlined, color: Color(0xFFE94560))
              : Text(
                  text,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
