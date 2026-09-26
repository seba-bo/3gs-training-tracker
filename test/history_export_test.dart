import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ipsc_training/models/gun_type.dart';
import 'package:ipsc_training/models/member.dart';
import 'package:ipsc_training/models/run.dart';
import 'package:ipsc_training/models/training_session.dart';
import 'package:ipsc_training/screens/history_screen.dart';

void main() {
  testWidgets('export ranks equal point scores by hit factor', (tester) async {
    String? exportedText;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            exportedText = (call.arguments as Map)['text'] as String;
          }
          return null;
        });

    final members = [
      Member(id: 1, name: 'Alex'),
      Member(id: 2, name: 'Blair'),
      Member(id: 3, name: 'Casey'),
    ];
    final session = TrainingSession(
      id: 1,
      date: DateTime(2026, 9, 26),
      participantIds: [1, 2, 3],
      runs: [
        Run(id: 1, memberId: 1, time: 10, points: 100, gun: GunType.pistol),
        Run(id: 2, memberId: 1, time: 8, points: 100, gun: GunType.pistol),
        Run(id: 3, memberId: 2, time: 5, points: 100, gun: GunType.pistol),
        Run(id: 4, memberId: 3, time: 10, points: 90, gun: GunType.pistol),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryScreen(
            members: members,
            sessionHistory: [session],
            onDeleteSession: (_) {},
            onResumeSession: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(InkWell).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    final topScorers = exportedText!.split('Top Scorers').last;

    expect(
      topScorers.indexOf('Blair: 100 pts'),
      lessThan(topScorers.indexOf('Alex: 100 pts')),
    );
    expect(topScorers, contains('Alex: 100 pts (12.50 hit factor'));
  });
}
