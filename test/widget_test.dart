import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edstream_mobile/core/theme/app_theme.dart';
import 'package:edstream_mobile/presentation/screens/auth/login_screen.dart';

void main() {
  testWidgets('Edstream dual-role login screen smoke test', (WidgetTester tester) async {
    // Build LoginScreen inside MaterialApp and trigger a frame.
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const LoginScreen(),
      ),
    );

    // Verify Brand title is visible
    expect(find.text('EDSTREAM'), findsOneWidget);

    // Verify Teacher and Student tabs are visible
    expect(find.text('Teacher'), findsOneWidget);
    expect(find.text('Student'), findsOneWidget);

    // Verify Teacher login prompt is initially active
    expect(find.text('Teacher Login'), findsOneWidget);
    expect(find.text('Staff Email'), findsOneWidget);

    // Tap on Student tab
    await tester.tap(find.text('Student'));
    await tester.pumpAndSettle();

    // Verify Student login state is active
    expect(find.text('Student Login'), findsOneWidget);
    expect(find.text('Email or Reg Number'), findsOneWidget);
  });
}
