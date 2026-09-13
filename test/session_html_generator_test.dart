import 'package:flutter_test/flutter_test.dart';
import 'package:ipsc_training/models/member.dart';
import 'package:ipsc_training/models/run.dart';
import 'package:ipsc_training/models/training_session.dart';
import 'package:ipsc_training/services/session_html_generator.dart';
import 'package:ipsc_training/models/gun_type.dart';

void main() {
  test('uses the requested export filename format', () {
    expect(
      SessionHtmlGenerator.fileName(DateTime(2026, 9, 13, 7, 5, 2)),
      'session_13092026_070502.html',
    );
  });

  test('generates escaped session HTML with run details', () {
    final session = TrainingSession(
      id: 1,
      date: DateTime(2026, 9, 13),
      participantIds: [1],
      runs: [
        Run(
          id: 1,
          memberId: 1,
          time: 10.5,
          points: 20,
          gun: GunType.pistol,
          stageName: '<Stage>',
        ),
        Run(id: 2, memberId: 1, time: 8, points: 20, gun: GunType.pistol),
      ],
    );

    final html = SessionHtmlGenerator.generate(
      session: session,
      members: [Member(id: 1, name: 'A & B')],
    );

    expect(html, contains('A &amp; B'));
    expect(html, contains('10.50'));
    expect(html, contains('Best Hit Factor'));
    expect(html, contains('<th>Points</th>'));
    expect(html, isNot(contains('Top Points')));
    expect(html, contains('Time (seconds)'));
    expect(html, contains('Complete Training Data'));
    expect(html, contains('type="checkbox"'));
    expect(html, contains('toggleSeries'));
    expect(html, isNot(contains('<polyline')));
    expect(html, isNot(contains('<h2>Participants</h2>')));
    expect(html, contains('stroke-dasharray="6 5"'));
    expect(html, contains('Guide lines:'));
    expect(html, contains('HF 2.0'));
    expect(html, contains('HF 2.5'));
    expect(html, contains('training-member-filter'));
    expect(html, contains('training-gun-filter'));
    expect(html, contains('training-sort'));
    expect(html, contains('<th>Run</th>'));
    expect(html, contains('data-run="1"'));
    expect(html, contains('<option value="run">Run number</option>'));
    expect(html, contains('filterAndSortTrainingData'));
    expect(html, contains('data-time="10.5"'));
    expect(html, isNot(contains('<th>Stage</th>')));
    expect(html, isNot(contains('<th>Penalties</th>')));
    expect(html, isNot(contains('<th>Final points</th>')));
    expect(html, isNot(contains('<th>Notes</th>')));
  });
}
