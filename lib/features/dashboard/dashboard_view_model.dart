import 'package:flutter/material.dart';

class Friend {
  final String name;
  final bool isAwake;
  final String imageUrl; // Mock image URL or asset path

  Friend({required this.name, required this.isAwake, required this.imageUrl});
}

class DashboardViewModel extends ChangeNotifier {
  bool _isUserAwake = false;
  bool get isUserAwake => _isUserAwake;

  void toggleAwakeStatus() {
    _isUserAwake = !_isUserAwake;
    notifyListeners();
  }

  void markAsAwake() {
    _isUserAwake = true;
    notifyListeners();
  }

  // Mock list of Friends
  final List<Friend> _friends = [
    Friend(name: 'Ahmed', isAwake: false, imageUrl: 'assets/avatar_1.png'),
    Friend(name: 'Layla', isAwake: true, imageUrl: 'assets/avatar_2.png'),
    Friend(name: 'Omar', isAwake: false, imageUrl: 'assets/avatar_3.png'),
    Friend(name: 'Sarah', isAwake: true, imageUrl: 'assets/avatar_4.png'),
  ];

  List<Friend> get friends => _friends;
}
