// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:suhoor_wake_up_circle/main.dart';

void main() {
  testWidgets('Suhoor app loads dashboard and navigation', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const SuhoorApp());
    await tester.pumpAndSettle();

    expect(find.text("TAP TO ALERT SQUAD"), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Squads'), findsOneWidget);
    expect(find.text('Challenge'), findsOneWidget);
  });
}
