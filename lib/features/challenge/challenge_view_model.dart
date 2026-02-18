import 'dart:math';
import 'package:flutter/material.dart';

class ChallengeViewModel extends ChangeNotifier {
  late int _number1;
  late int _number2;
  String _input = '';

  bool _isSolved = false;
  bool get isSolved => _isSolved;

  String get problemText => '$_number1 + $_number2 =';
  String get input => _input;

  ChallengeViewModel() {
    _generateProblem();
  }

  void _generateProblem() {
    final random = Random();
    _number1 = random.nextInt(50) + 1; // 1-50
    _number2 = random.nextInt(50) + 1; // 1-50
    _input = '';
    notifyListeners();
  }

  void addDigit(String digit) {
    if (_input.length < 3) {
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
    final expectedSum = _number1 + _number2;
    if (_input.isNotEmpty && int.tryParse(_input) == expectedSum) {
      _isSolved = true;
      notifyListeners();
    }
  }
}
