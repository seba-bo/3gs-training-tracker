import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ipsc_training/main.dart';

void main() {
  setUp(() async {
    // Mock SharedPreferences für Tests
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App loads and shows 3GS Training title', (WidgetTester tester) async {
    await tester.pumpWidget(const IPSCTrackerApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('3GS Training'), findsOneWidget);
    expect(find.text('🎯'), findsOneWidget);
  });

  testWidgets('Can add a shooter', (WidgetTester tester) async {
    await tester.pumpWidget(const IPSCTrackerApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('No shooters added yet'), findsOneWidget);

    final nameField = find.ancestor(
      of: find.text('Shooter name'),
      matching: find.byType(TextField),
    );
    
    await tester.enterText(nameField, 'Test Shooter');
    await tester.pump();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Test Shooter'), findsOneWidget);
    expect(find.text('No shooters added yet'), findsNothing);
  });

  testWidgets('Can navigate to Rankings', (WidgetTester tester) async {
    await tester.pumpWidget(const IPSCTrackerApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Rankings'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rankings by'), findsOneWidget);
  });

  testWidgets('Leaderboard shows correct views', (WidgetTester tester) async {
    await tester.pumpWidget(const IPSCTrackerApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.text('Rankings'));
    await tester.pumpAndSettle();

    expect(find.text('Rankings by Best Hit Factor'), findsOneWidget);

    await tester.tap(find.text('By Points'));
    await tester.pumpAndSettle();

    expect(find.text('Rankings by Best Points'), findsOneWidget);
  });

  testWidgets('Menu shows export and clear options', (WidgetTester tester) async {
    await tester.pumpWidget(const IPSCTrackerApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    await tester.tap(find.byType(PopupMenuButton<dynamic>));
    await tester.pumpAndSettle();

    expect(find.text('Export CSV'), findsOneWidget);
    expect(find.text('Clear Board'), findsOneWidget);
  });

  testWidgets('Can record a score', (WidgetTester tester) async {
    await tester.pumpWidget(const IPSCTrackerApp());
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Add shooter
    final nameField = find.ancestor(
      of: find.text('Shooter name'),
      matching: find.byType(TextField),
    );
    await tester.enterText(nameField, 'Test Shooter');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Click Add Run
    await tester.tap(find.text('Add Run'));
    await tester.pumpAndSettle();

    // Enter time
    final timeField = find.byWidgetPredicate(
      (widget) => widget is TextField && 
                  widget.decoration?.hintText == 'e.g., 12.45',
    );
    await tester.enterText(timeField, '10.5');
    await tester.pump();

    // Enter points
    final pointsField = find.byWidgetPredicate(
      (widget) => widget is TextField && 
                  widget.decoration?.hintText == 'e.g., 85',
    );
    await tester.enterText(pointsField, '85');
    await tester.pumpAndSettle();

    // Verify Hit Factor is shown
    expect(find.text('Hit Factor'), findsOneWidget);

    // Save the run
    await tester.tap(find.text('Save Run'));
    await tester.pumpAndSettle();

    // Should be back on roster screen with the run recorded
    expect(find.textContaining('HF'), findsOneWidget);
  });
}