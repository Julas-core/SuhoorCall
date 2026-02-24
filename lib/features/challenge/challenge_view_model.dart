import 'dart:math';
import 'package:flutter/material.dart';

class ChallengeViewModel extends ChangeNotifier {
  late _MathChallenge _challenge;
  String _input = '';

  bool _isSolved = false;
  bool get isSolved => _isSolved;

  String get problemText => '${_challenge.expression} =';
  String get input => _input;

  static final List<_MathChallenge> _challengeBank = _buildChallengeBank();
  final Random _random = Random();

  ChallengeViewModel() {
    _generateProblem();
  }

  void _generateProblem() {
    _challenge = _challengeBank[_random.nextInt(_challengeBank.length)];
    _input = '';
    _isSolved = false;
    notifyListeners();
  }

  void addDigit(String digit) {
    if (_input.length < 5) {
      _input += digit;
      notifyListeners();
      _checkAnswer();
    }
  }

  void removeDigit() {
    if (_input.isNotEmpty) {
      _input = _input.substring(0, _input.length - 1);
      notifyListeners();
    }
  }

  void _checkAnswer() {
    if (_input.isNotEmpty && int.tryParse(_input) == _challenge.answer) {
      _isSolved = true;
      notifyListeners();
    }
  }

  static List<_MathChallenge> _buildChallengeBank() {
    final challenges = <_MathChallenge>[];

    for (var i = 1; i <= 30; i++) {
      final a = 37 + (i * 2);
      final b = 18 + i;
      challenges.add(_MathChallenge('$a + $b', a + b));
    }

    for (var i = 1; i <= 30; i++) {
      final a = 120 + (i * 3);
      final b = 35 + i;
      challenges.add(_MathChallenge('$a - $b', a - b));
    }

    for (var i = 1; i <= 30; i++) {
      final a = 11 + i;
      final b = (i % 7) + 4;
      challenges.add(_MathChallenge('$a × $b', a * b));
    }

    for (var i = 1; i <= 30; i++) {
      final divisor = (i % 8) + 3;
      final quotient = 12 + i;
      final dividend = divisor * quotient;
      challenges.add(_MathChallenge('$dividend ÷ $divisor', quotient));
    }

    for (var i = 1; i <= 15; i++) {
      final a = 8 + i;
      final b = 4 + (i % 6);
      final c = 12 + (i * 2);
      challenges.add(_MathChallenge('$a × $b + $c', (a * b) + c));
    }

    for (var i = 1; i <= 15; i++) {
      final a = 6 + i;
      final b = 7 + (i % 5);
      final c = 3 + (i % 4);
      challenges.add(_MathChallenge('($a + $b) × $c', (a + b) * c));
    }

    return challenges;
  }
}

class _MathChallenge {
  final String expression;
  final int answer;

  _MathChallenge(this.expression, this.answer);
}
