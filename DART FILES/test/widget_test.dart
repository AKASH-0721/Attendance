import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:attendance_interface/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Check if both buttons are found
    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Teacher Login'), findsOneWidget);
  });
}
