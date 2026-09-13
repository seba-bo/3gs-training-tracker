import '../models/gun_type.dart';
import '../models/member.dart';
import '../models/run.dart';
import '../models/training_session.dart';
import '../utils/formatters.dart';
import '../utils/gun_helpers.dart';

class SessionHtmlGenerator {
  static String generate({
    required TrainingSession session,
    required List<Member> members,
  }) {
    final membersById = {for (final member in members) member.id: member};
    final rows = session.runs.map((run) {
      final memberName = membersById[run.memberId]?.name ?? 'Unknown member';
      return '''
        <tr>
          <td>${_escape(memberName)}</td>
          <td>${_escape(GunHelpers.getLabel(run.gun))}</td>
          <td>${_escape(run.stageName ?? '')}</td>
          <td>${run.time.toStringAsFixed(2)}</td>
          <td>${run.points}</td>
          <td>${run.penalties}</td>
          <td>${run.finalPoints}</td>
          <td>${run.finalHitFactor.toStringAsFixed(2)}</td>
          <td>${_escape(run.notes ?? '')}</td>
        </tr>''';
    }).join();

    final gunSections = GunType.values.map((gun) {
      final runs = session.runs.where((run) => run.gun == gun).toList();
      if (runs.isEmpty) return '';
      return _gunSection(gun, runs, membersById);
    }).join();

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>3GS Training Session - ${_escape(Formatters.formatDate(session.date))}</title>
  <style>
    :root { color-scheme: light; font-family: Arial, sans-serif; }
    body { color: #202124; margin: 0; padding: 32px; }
    main { margin: 0 auto; max-width: 1200px; }
    h1 { margin-bottom: 4px; }
    h2 { border-bottom: 1px solid #ddd; margin-top: 32px; padding-bottom: 8px; }
    h3 { margin-bottom: 8px; }
    .meta { color: #666; }
    .leaderboards { display: grid; gap: 16px; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); }
    .leaderboard { border: 1px solid #ddd; border-radius: 6px; padding: 12px; }
    .leaderboard table { margin-top: 0; }
    .chart { border: 1px solid #ddd; margin-top: 16px; overflow-x: auto; padding: 8px; }
    .chart svg { display: block; min-width: 680px; width: 100%; }
    .legend { display: flex; flex-wrap: wrap; gap: 8px 16px; margin: 8px 0 0 52px; }
    .legend-item { align-items: center; display: inline-flex; gap: 6px; }
    .legend-swatch { display: inline-block; height: 3px; width: 20px; }
    table { border-collapse: collapse; margin-top: 16px; width: 100%; }
    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
    th { background: #f1f3f4; }
    tr:nth-child(even) { background: #fafafa; }
    @media print { body { padding: 0; } }
  </style>
</head>
<body>
  <main>
    <h1>3GS Training Session</h1>
    <p class="meta">${_escape(Formatters.formatDate(session.date))} at ${_escape(Formatters.formatTime(session.date))}</p>
    ${session.notes == null || session.notes!.isEmpty ? '' : '<p><strong>Notes:</strong> ${_escape(session.notes!)}</p>'}
    <h2>Leaderboards and Charts</h2>
    $gunSections
    <h2>Complete Training Data</h2>
    ${session.runs.isEmpty ? '<p>No runs recorded.</p>' : '''
    <table>
      <thead><tr><th>Member</th><th>Gun</th><th>Stage</th><th>Time (s)</th><th>Points</th><th>Penalties</th><th>Final points</th><th>Hit factor</th><th>Notes</th></tr></thead>
      <tbody>$rows</tbody>
    </table>'''}
  </main>
</body>
<script>
  function toggleSeries(chartId, seriesId, visible) {
    document.querySelectorAll('#' + chartId + ' .' + seriesId).forEach(function (point) {
      point.style.display = visible ? '' : 'none';
    });
  }
</script>
</html>''';
  }

  static String _gunSection(
    GunType gun,
    List<Run> runs,
    Map<int, Member> membersById,
  ) {
    final bestHitFactor = <int, Run>{};
    for (final run in runs) {
      final currentHitFactor = bestHitFactor[run.memberId];
      if (currentHitFactor == null ||
          run.finalHitFactor > currentHitFactor.finalHitFactor) {
        bestHitFactor[run.memberId] = run;
      }
    }

    final hitFactorRows = bestHitFactor.entries.toList()
      ..sort(
        (a, b) => b.value.finalHitFactor.compareTo(a.value.finalHitFactor),
      );
    String leaderboardRows(MapEntry<int, Run> entry) {
      final memberName = membersById[entry.key]?.name ?? 'Unknown member';
      final run = entry.value;
      return '<tr><td>${_escape(memberName)}</td><td>${run.finalHitFactor.toStringAsFixed(2)}</td><td>${run.time.toStringAsFixed(2)} s</td></tr>';
    }

    final chart = _buildChart(gun, runs, membersById);
    return '''
    <section>
      <h3>${_escape(GunHelpers.getLabel(gun))}</h3>
      <div class="leaderboards">
        <div class="leaderboard">
          <strong>Best Hit Factor</strong>
          <table><thead><tr><th>Member</th><th>HF</th><th>Time</th></tr></thead><tbody>
            ${hitFactorRows.map(leaderboardRows).join()}
          </tbody></table>
        </div>
      </div>
      $chart
    </section>''';
  }

  static String _buildChart(
    GunType gun,
    List<Run> runs,
    Map<int, Member> membersById,
  ) {
    const chartWidth = 760.0;
    const chartHeight = 360.0;
    const left = 60.0;
    const right = 30.0;
    const top = 20.0;
    const bottom = 48.0;
    final plotWidth = chartWidth - left - right;
    final plotHeight = chartHeight - top - bottom;
    final minTime = runs.map((run) => run.time).reduce(_minDouble);
    final maxTime = runs.map((run) => run.time).reduce(_maxDouble);
    final minPoints = runs
        .map((run) => run.finalPoints)
        .reduce(_minInt)
        .toDouble();
    final maxPoints = runs
        .map((run) => run.finalPoints)
        .reduce(_maxInt)
        .toDouble();
    final timeRange = maxTime - minTime == 0 ? 1.0 : maxTime - minTime;
    final pointRange = maxPoints - minPoints == 0 ? 1.0 : maxPoints - minPoints;
    final xMin = minTime;
    final xMax = maxTime == minTime ? minTime + timeRange : maxTime;
    final yMin = minPoints;
    final yMax = maxPoints == minPoints ? minPoints + pointRange : maxPoints;
    final groups = <int, List<Run>>{};
    for (final run in runs) {
      groups.putIfAbsent(run.memberId, () => []).add(run);
    }

    final colors = [
      '#2563eb',
      '#dc2626',
      '#059669',
      '#d97706',
      '#7c3aed',
      '#0891b2',
    ];
    final hitFactorGuides = <String>[];
    final hitFactorLegend = <String>[];
    final guideColors = [
      '#dc2626',
      '#2563eb',
      '#059669',
      '#d97706',
      '#7c3aed',
      '#0891b2',
      '#be123c',
      '#4f46e5',
    ];
    final minHitFactor = runs
        .map((run) => run.finalHitFactor)
        .reduce(_minDouble);
    final maxHitFactor = runs
        .map((run) => run.finalHitFactor)
        .reduce(_maxDouble);
    final firstHalfStepHitFactor = (minHitFactor * 2).ceil();
    final nextHalfStepHitFactor = (maxHitFactor * 2).floor() + 1;
    for (
      var halfStepHitFactor = firstHalfStepHitFactor;
      halfStepHitFactor <= nextHalfStepHitFactor;
      halfStepHitFactor++
    ) {
      final hitFactor = halfStepHitFactor / 2;
      if (hitFactor <= 0) continue;
      final guideStart = xMin > yMin / hitFactor ? xMin : yMin / hitFactor;
      final guideEnd = xMax < yMax / hitFactor ? xMax : yMax / hitFactor;
      if (guideStart > guideEnd) continue;
      final startX = left + ((guideStart - xMin) / (xMax - xMin)) * plotWidth;
      final endX = left + ((guideEnd - xMin) / (xMax - xMin)) * plotWidth;
      final startY =
          top +
          (1 - ((hitFactor * guideStart - yMin) / (yMax - yMin))) * plotHeight;
      final endY =
          top +
          (1 - ((hitFactor * guideEnd - yMin) / (yMax - yMin))) * plotHeight;
      final guideColor =
          guideColors[hitFactorLegend.length % guideColors.length];
      hitFactorGuides.add(
        '<line x1="${startX.toStringAsFixed(1)}" y1="${startY.toStringAsFixed(1)}" x2="${endX.toStringAsFixed(1)}" y2="${endY.toStringAsFixed(1)}" stroke="$guideColor" stroke-dasharray="6 5" stroke-width="1"><title>HF ${hitFactor.toStringAsFixed(1)}</title></line>',
      );
      hitFactorLegend.add(
        '<span class="legend-item"><span class="legend-swatch" style="background:$guideColor"></span>HF ${hitFactor.toStringAsFixed(1)}</span>',
      );
    }
    final series = <String>[];
    final legend = <String>[];
    final chartId = 'chart-${gun.name}';
    var colorIndex = 0;
    for (final entry in groups.entries) {
      final color = colors[colorIndex++ % colors.length];
      final seriesId = 'series-${gun.name}-${entry.key}';
      final sortedRuns = [...entry.value]
        ..sort((a, b) => a.time.compareTo(b.time));
      final points = sortedRuns.map((run) {
        final x = left + ((run.time - xMin) / (xMax - xMin)) * plotWidth;
        final y =
            top + (1 - ((run.finalPoints - yMin) / (yMax - yMin))) * plotHeight;
        return (x: x, y: y, run: run);
      }).toList();
      series.addAll(
        points.map(
          (point) =>
              '<circle class="$seriesId" cx="${point.x.toStringAsFixed(1)}" cy="${point.y.toStringAsFixed(1)}" fill="$color" r="4"><title>${_escape(membersById[entry.key]?.name ?? 'Unknown member')}: ${point.run.time.toStringAsFixed(2)} s, ${point.run.finalPoints} points, HF ${point.run.finalHitFactor.toStringAsFixed(2)}</title></circle>',
        ),
      );
      final name = membersById[entry.key]?.name ?? 'Unknown member';
      final hitFactors = sortedRuns
          .map((run) => run.finalHitFactor.toStringAsFixed(2))
          .join(', ');
      legend.add(
        '<label class="legend-item"><input type="checkbox" checked onchange="toggleSeries(\'$chartId\', \'$seriesId\', this.checked)"><span class="legend-swatch" style="background:$color"></span>${_escape(name)} (HF $hitFactors)</label>',
      );
    }

    return '''<div id="$chartId" class="chart">
      <svg viewBox="0 0 $chartWidth $chartHeight" role="img" aria-label="Time versus points chart">
        <line x1="$left" y1="$top" x2="$left" y2="${chartHeight - bottom}" stroke="#555"/>
        <line x1="$left" y1="${chartHeight - bottom}" x2="${chartWidth - right}" y2="${chartHeight - bottom}" stroke="#555"/>
        <text x="${chartWidth / 2}" y="${chartHeight - 8}" text-anchor="middle">Time (seconds)</text>
        <text transform="translate(14 ${chartHeight / 2}) rotate(-90)" text-anchor="middle">Points</text>
        <text x="$left" y="${chartHeight - bottom + 20}" text-anchor="middle">${minTime.toStringAsFixed(2)}</text>
        <text x="${chartWidth - right}" y="${chartHeight - bottom + 20}" text-anchor="middle">${maxTime.toStringAsFixed(2)}</text>
        <text x="${left - 8}" y="${chartHeight - bottom + 4}" text-anchor="end">${minPoints.toStringAsFixed(0)}</text>
        <text x="${left - 8}" y="${top + 4}" text-anchor="end">${maxPoints.toStringAsFixed(0)}</text>
        ${hitFactorGuides.join()}
        ${series.join()}
      </svg>
      <div class="legend hf-legend"><strong>Guide lines:</strong> ${hitFactorLegend.join()}</div>
      <div class="legend">${legend.join()}</div>
    </div>''';
  }

  static double _minDouble(double a, double b) => a < b ? a : b;
  static double _maxDouble(double a, double b) => a > b ? a : b;
  static int _minInt(int a, int b) => a < b ? a : b;
  static int _maxInt(int a, int b) => a > b ? a : b;

  static String fileName(DateTime timestamp) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return 'session_${twoDigits(timestamp.day)}${twoDigits(timestamp.month)}${timestamp.year.toString().padLeft(4, '0')}_${twoDigits(timestamp.hour)}${twoDigits(timestamp.minute)}${twoDigits(timestamp.second)}.html';
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
