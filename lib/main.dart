import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_screen.dart';

void main() {
  runApp(const SuhoorApp());
}

class SuhoorApp extends StatelessWidget {
  const SuhoorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suhoor Wake-Up Circle',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(context),
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final baseTextTheme = GoogleFonts.poppinsTextTheme(
      Theme.of(context).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E), // Dark Navy
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE94560), // Red
        secondary: Color(0xFF0F3460),
        surface: Color(0xFF16213E),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
