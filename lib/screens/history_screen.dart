import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/member.dart';
import '../models/training_session.dart';
import '../models/gun_type.dart';
import '../models/run.dart';
import '../widgets/custom_card.dart';
import '../utils/constants.dart';
import '../utils/gun_helpers.dart';
import '../utils/formatters.dart';

class HistoryScreen extends StatefulWidget {
  final List<Member> members;
  final List<TrainingSession> sessionHistory;
  final Function(int) onDeleteSession;
  final Function(TrainingSession) onResumeSession;

  const HistoryScreen({
    super.key,
    required this.members,
    required this.sessionHistory,
    required this.onDeleteSession,
    required this.onResumeSession,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final Set<int> _expandedSessions = {};

  Member? _getMember(int id) {
    return widget.members.where((m) => m.id == id).firstOrNull;
  }

  void _toggleExpanded(int sessionId) {
    setState(() {
      if (_expandedSessions.contains(sessionId)) {
        _expandedSessions.remove(sessionId);
      } else {
        _expandedSessions.add(sessionId);
      }
    });
  }

  String _generateExportText(TrainingSession session) {
    final buffer = StringBuffer();
    buffer.writeln('3GS Training Session - ${Formatters.formatDate(session.date)}');
    buffer.writeln();
    
        
    // Group runs by gun type and find best run per member per gun
    final gunTypes = [GunType.pistol, GunType.pcc, GunType.shotgun];
    
    for (final gunType in gunTypes) {
      final runsForGun = session.runs.where((r) => r.gun == gunType).toList();
      
      if (runsForGun.isEmpty) continue;
      
      // Find maximum points achieved in this gun category (this session's "perfect score")
      final maxPointsInCategory = runsForGun.map((r) => r.points).reduce((a, b) => a > b ? a : b);
      
      // Find best run per member for this gun type
      final memberBestRuns = <int, Run>{};
      for (final run in runsForGun) {
        if (!memberBestRuns.containsKey(run.memberId) ||
            run.finalHitFactor > memberBestRuns[run.memberId]!.finalHitFactor) {
          memberBestRuns[run.memberId] = run;
        }
      }
      
      // Sort by hit factor
      final sortedEntries = memberBestRuns.entries.toList()
        ..sort((a, b) => b.value.finalHitFactor.compareTo(a.value.finalHitFactor));
      
      // Write results for this gun type
      buffer.writeln('Rankings by Best Hit Factor');
      buffer.writeln('(${GunHelpers.getLabel(gunType)})');
      
      int position = 1;
      for (final entry in sortedEntries) {
        final member = _getMember(entry.key);
        if (member == null) continue;
        
        final run = entry.value;
        final medal = position == 1 ? '🥇' : position == 2 ? '🥈' : position == 3 ? '🥉' : position.toString();
        
        // Perfect score: max points in this category AND no penalties
        final isPerfect = run.penalties == 0 && run.points >= maxPointsInCategory;
        final perfectScore = isPerfect ? ' 🎯' : '';
        
        buffer.writeln('$medal ${member.name}: ${run.finalHitFactor.toStringAsFixed(2)}$perfectScore (${run.finalPoints} pts in ${run.time}s)');
        
        position++;
      }
      
      buffer.writeln();
    }

    // Top 3 Scorers by Gun Type
    if (session.runs.isNotEmpty) {
      buffer.writeln('Top Scorers');
      
      for (final gunType in gunTypes) {
        final runsForGun = session.runs.where((r) => r.gun == gunType).toList();
        
        if (runsForGun.isEmpty) continue;
        
        // Find best run per member for this gun type
        final memberBestRuns = <int, Run>{};
        for (final run in runsForGun) {
          if (!memberBestRuns.containsKey(run.memberId) ||
              run.finalHitFactor > memberBestRuns[run.memberId]!.finalHitFactor) {
            memberBestRuns[run.memberId] = run;
          }
        }
        
        // Sort by hit factor
        final sortedEntries = memberBestRuns.entries.toList()
          ..sort((a, b) => b.value.finalHitFactor.compareTo(a.value.finalHitFactor));
        
        // Get top 3, but include all members tied at position 3
        final topThree = <MapEntry<int, Run>>[];
        if (sortedEntries.isNotEmpty) {
          topThree.add(sortedEntries[0]);
          if (sortedEntries.length > 1) {
            topThree.add(sortedEntries[1]);
            if (sortedEntries.length > 2) {
              final thirdFactor = sortedEntries[2].value.finalHitFactor;
              for (final entry in sortedEntries.skip(2)) {
                if (entry.value.finalHitFactor == thirdFactor) {
                  topThree.add(entry);
                } else {
                  break;
                }
              }
            }
          }
        }
        
        // Write top scorers for this gun type
        buffer.writeln('${GunHelpers.getLabel(gunType)}');
        int position = 1;
        for (final entry in topThree) {
          final member = _getMember(entry.key);
          if (member == null) continue;
          
          final run = entry.value;
          final medal = position == 1 ? '🥇' : position == 2 ? '🥈' : position == 3 ? '🥉' : '⭐';
          buffer.writeln('$medal ${member.name}: ${run.finalPoints} pts (${run.finalHitFactor.toStringAsFixed(2)} hit factor in ${run.time}s)');
          if (position < 3) position++;
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  void _exportSession(TrainingSession session) {
    final exportText = _generateExportText(session);
    
    Clipboard.setData(ClipboardData(text: exportText));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session exported to clipboard!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDeleteSessionDialog(TrainingSession session) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Delete session from ${Formatters.formatDate(session.date)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteSession(session.id);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showResumeSessionDialog(TrainingSession session) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Resume Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume session from ${Formatters.formatDate(session.date)}?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('• ${session.participantIds.length} participants'),
            Text('• ${session.runs.length} runs recorded'),
            const SizedBox(height: 12),
            const Text(
              'The session will be removed from history and become active again. You can continue adding runs.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onResumeSession(session);
              Navigator.pop(c);
            },
            child: const Text(
              'Resume Session',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort sessions by date (newest first)
    final sortedSessions = List<TrainingSession>.from(widget.sessionHistory)
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CustomCard(
            child: Row(
              children: [
                const Icon(Icons.history, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.sessionHistory.length} completed sessions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (sortedSessions.isEmpty)
            CustomCard(
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No completed sessions yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start a session to see it here',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...sortedSessions.map((session) => _buildSessionCard(session)),
        ],
      ),
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    final participants = widget.members
        .where((m) => session.participantIds.contains(m.id))
        .toList();

    final isExpanded = _expandedSessions.contains(session.id);

    // Group runs by gun type
    final pistolRuns = session.runs.where((r) => r.gun == GunType.pistol).length;
    final pccRuns = session.runs.where((r) => r.gun == GunType.pcc).length;
    final shotgunRuns = session.runs.where((r) => r.gun == GunType.shotgun).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with expand button
            InkWell(
              onTap: () => _toggleExpanded(session.id),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.formatDate(session.date),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                Formatters.formatTime(session.date),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${session.runs.length} runs',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    
                    // Participants
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: participants.map((member) {
                        final memberRuns = session.runs
                            .where((r) => r.memberId == member.id)
                            .length;
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.cardBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                member.name,
                                style: const TextStyle(fontSize: 12),
                              ),
                              if (memberRuns > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '$memberRuns',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    
                    if (session.runs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      
                      // Gun type breakdown
                      Row(
                        children: [
                          if (pistolRuns > 0)
                            _buildGunTypeBadge(GunType.pistol, pistolRuns),
                          if (pccRuns > 0) ...[
                            if (pistolRuns > 0) const SizedBox(width: 8),
                            _buildGunTypeBadge(GunType.pcc, pccRuns),
                          ],
                          if (shotgunRuns > 0) ...[
                            if (pistolRuns > 0 || pccRuns > 0) const SizedBox(width: 8),
                            _buildGunTypeBadge(GunType.shotgun, shotgunRuns),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Expanded details
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Action Buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showResumeSessionDialog(session),
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Resume'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _exportSession(session),
                        icon: const Icon(Icons.file_download, size: 16),
                        label: const Text('Export'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showDeleteSessionDialog(session),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Participants
                  const Text(
                    'Participants',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: participants.map((member) {
                      final memberRuns = session.runs
                          .where((r) => r.memberId == member.id)
                          .length;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppConstants.cardBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              member.name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (memberRuns > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$memberRuns',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  
                  // Detailed Results (if runs exist)
                  if (session.runs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Detailed Results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._buildDetailedResults(session),
                  ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDetailedResults(TrainingSession session) {
    // Create list of all runs with member info and sort by hit factor
    final runsWithMembers = <Map<String, dynamic>>[];
    for (final run in session.runs) {
      final member = _getMember(run.memberId);
      if (member != null) {
        runsWithMembers.add({
          'member': member,
          'run': run,
        });
      }
    }

    runsWithMembers.sort((a, b) {
      final runA = a['run'] as Run;
      final runB = b['run'] as Run;
      return runB.finalHitFactor.compareTo(runA.finalHitFactor);
    });

    return runsWithMembers.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final member = item['member'] as Member;
      final run = item['run'] as Run;
      
      final medal = index == 0
          ? '🥇'
          : index == 1
              ? '🥈'
              : index == 2
                  ? '🥉'
                  : '${index + 1}.';

      final borderColor = index == 0
          ? Colors.yellow
          : index == 1
              ? Colors.grey
              : index == 2
                  ? Colors.orange
                  : null;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppConstants.cardBg,
          border: borderColor != null
              ? Border.all(color: borderColor, width: 2)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                medal,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${GunHelpers.getIcon(run.gun)} ${member.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${run.finalPoints} pts in ${run.time}s',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Text(
              run.finalHitFactor.toStringAsFixed(2),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildGunTypeBadge(GunType gun, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            GunHelpers.getIcon(gun),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}