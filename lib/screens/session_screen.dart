import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/training_session.dart';
import '../models/run.dart';
import '../models/gun_type.dart';
import '../widgets/custom_card.dart';
import '../dialogs/add_run_dialog.dart';
import '../widgets/run_item.dart';
import '../utils/constants.dart';
import '../utils/gun_helpers.dart';

class SessionScreen extends StatefulWidget {
  final List<Member> members;
  final TrainingSession? activeSession;
  final Function(List<int>) onStartSession;
  final Function(Run) onAddRun;
  final Function(int) onDeleteRun;
  final Function(Run) onUpdateRun;
  final Function() onEndSession;
  final Function(List<int>) onUpdateShootingOrder;
  final Function(int)? onUpdateSessionSettings; // ← NEU!

  const SessionScreen({
    super.key,
    required this.members,
    this.activeSession,
    required this.onStartSession,
    required this.onAddRun,
    required this.onDeleteRun,
    required this.onUpdateRun,
    required this.onEndSession,
    required this.onUpdateShootingOrder,
    this.onUpdateSessionSettings, // ← NEU!
  });

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  final Set<int> _selectedIds = {};
  int _currentShooterIndex = 0;

  Member? _getMember(int id) {
    return widget.members.where((m) => m.id == id).firstOrNull;
  }

  Member? _getCurrentShooter() {
    if (widget.activeSession == null) return null;
    
    final order = widget.activeSession!.shootingOrder;
    if (_currentShooterIndex >= order.length) {
      _currentShooterIndex = 0; // Loop back to start
    }
    
    return _getMember(order[_currentShooterIndex]);
  }

  void _advanceToNextShooter() {
    if (widget.activeSession == null) return;
    
    setState(() {
      _currentShooterIndex++;
      if (_currentShooterIndex >= widget.activeSession!.shootingOrder.length) {
        _currentShooterIndex = 0;
      }
    });
  }

  void _skipCurrentShooter() {
    _advanceToNextShooter();
  }

  void _setCurrentShooterIndex(int index) {
    setState(() {
      _currentShooterIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeSession != null) {
      return _buildActiveSessionView();
    }

    return _buildStartSessionView();
  }

  Widget _buildStartSessionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.play_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text(
                  'Start New Training Session',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select participants for today\'s training',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (widget.members.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No members available',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add members first in the Members tab',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedIds.addAll(widget.members.map((m) => m.id));
                    }),
                    icon: const Icon(Icons.select_all, size: 16),
                    label: const Text('Select All'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    icon: const Icon(Icons.deselect, size: 16),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...widget.members.map((member) {
                final isSelected = _selectedIds.contains(member.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.withValues(alpha: 0.2)
                        : AppConstants.cardBg,
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(member.id);
                        } else {
                          _selectedIds.remove(member.id);
                        }
                      });
                    },
                    title: Text(
                      member.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: member.memberNumber != null
                        ? Text('# ${member.memberNumber}')
                        : null,
                    activeColor: Colors.blue,
                  ),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => widget.onStartSession(_selectedIds.toList()),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    'Start Session with ${_selectedIds.length} participant${_selectedIds.length != 1 ? 's' : ''}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSessionView() {
    final currentShooter = _getCurrentShooter();
    final totalShooters = widget.activeSession!.shootingOrder.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Session info and end button
          CustomCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle, color: Colors.green, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Session',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.activeSession!.participantIds.length} participants, ${widget.activeSession!.runs.length} runs',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showSessionSettings,
                        icon: const Icon(Icons.settings),
                        label: const Text('Settings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddParticipantDialog,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onEndSession,
                        icon: const Icon(Icons.stop),
                        label: const Text('End'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Current Shooter Card (same design as Active Session)
          if (currentShooter != null)
            CustomCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Next Shooter',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              currentShooter.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Position ${_currentShooterIndex + 1} of $totalShooters',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showChangeShooterDialog(),
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        tooltip: 'Change shooter',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddRunDialog(currentShooter, autoAdvance: true),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Run'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _skipCurrentShooter,
                          icon: const Icon(Icons.skip_next, size: 18),
                          label: const Text('Skip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          
          // Shooting order list
          _buildShootingOrderList(),
        ],
      ),
    );
  }

  Widget _buildShootingOrderList() {
    if (widget.activeSession == null) return const SizedBox.shrink();
    
    final order = widget.activeSession!.shootingOrder;
    final orderedMembers = order
        .map((id) => _getMember(id))
        .where((m) => m != null)
        .cast<Member>()
        .toList();
    
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_list_numbered, color: Colors.blue),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Shooting Order',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showReorderDialog(orderedMembers),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Reorder'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...orderedMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final isNext = index == _currentShooterIndex;
            
            return _buildParticipantCard(member, index + 1, isNext);
          }),
        ],
      ),
    );
  }

  void _showReorderDialog(List<Member> members) {
    showDialog(
      context: context,
      builder: (context) => _ReorderDialog(
        members: members,
        onReorder: (newOrder) {
          widget.onUpdateShootingOrder(newOrder.map((m) => m.id).toList());
        },
      ),
    );
  }

  Widget _buildParticipantCard(Member member, int position, bool isNext) {
    final memberRuns = widget.activeSession!.runs
        .where((r) => r.memberId == member.id)
        .toList();

    final pistolRuns = memberRuns.where((r) => r.gun == GunType.pistol).toList();
    final pccRuns = memberRuns.where((r) => r.gun == GunType.pcc).toList();
    final shotgunRuns = memberRuns.where((r) => r.gun == GunType.shotgun).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isNext 
            ? Colors.green.withValues(alpha: 0.2)
            : AppConstants.cardBg,
        border: isNext 
            ? Border.all(color: Colors.green, width: 2)
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isNext 
                        ? Colors.green 
                        : Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNext ? Colors.white : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isNext) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'NEXT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (memberRuns.isEmpty)
                        const Text(
                          'No runs yet',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        )
                      else ...[
                        if (pistolRuns.isNotEmpty)
                          _buildQuickStats(GunType.pistol, pistolRuns),
                        if (pccRuns.isNotEmpty)
                          _buildQuickStats(GunType.pcc, pccRuns),
                        if (shotgunRuns.isNotEmpty)
                          _buildQuickStats(GunType.shotgun, shotgunRuns),
                      ],
                    ],
                  ),
                ),
                if (!isNext)
                  ElevatedButton(
                    onPressed: () => _showAddRunDialog(member, autoAdvance: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text('Add Run'),
                  ),
              ],
            ),
          ),
          if (memberRuns.isNotEmpty)
            ...memberRuns.reversed.map(
              (run) => RunItem(
                run: run,
                onEdit: () => _showEditRunDialog(run),
                onDelete: () => _showDeleteDialog(run.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(GunType gun, List<Run> runs) {
    if (runs.isEmpty) return const SizedBox.shrink();
    
    // Find best run manually
    Run best = runs.first;
    for (final run in runs) {
      if (run.finalHitFactor > best.finalHitFactor) {
        best = run;
      }
    }

    return Text(
      '${GunHelpers.getIcon(gun)} ${GunHelpers.getLabel(gun)}: ${best.finalHitFactor.toStringAsFixed(2)} (${runs.length} runs)',
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  void _showAddRunDialog(Member member, {bool autoAdvance = false}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Verhindert Schließen durch Außenklick
      builder: (context) => AddRunDialog(
        member: member,
        onSave: (run) {
          widget.onAddRun(run);
          
          if (autoAdvance) {
            _advanceToNextShooter();
          }
        },
      ),
    );
  }

  void _showEditRunDialog(Run run) {
    final member = _getMember(run.memberId);
    if (member == null) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Verhindert Schließen durch Außenklick
      builder: (context) => AddRunDialog(
        member: member,
        existingRun: run,
        onSave: (updatedRun) {
          widget.onUpdateRun(updatedRun);
        },
        showSkip: false,
      ),
    );
  }

  void _showChangeShooterDialog() {
    if (widget.activeSession == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600), // maxHeight hinzugefügt!
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Next Shooter',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Scrollbare Liste
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.activeSession!.shootingOrder.length,
                  itemBuilder: (context, index) {
                    final memberId = widget.activeSession!.shootingOrder[index];
                    final member = _getMember(memberId);
                    if (member == null) return const SizedBox.shrink();

                    final isCurrentShooter = index == _currentShooterIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          _setCurrentShooterIndex(index);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentShooter
                              ? Colors.green
                              : AppConstants.cardBg,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isCurrentShooter
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentShooter ? Colors.white : Colors.blue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isCurrentShooter)
                              const Icon(Icons.check_circle, color: Colors.white),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.cardBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddParticipantDialog() {
    if (widget.activeSession == null) return;

    // Get members not yet in session
    final availableMembers = widget.members.where((member) {
      return !widget.activeSession!.participantIds.contains(member.id);
    }).toList();

    if (availableMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All members are already in this session'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Participant',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select members to add to this session',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: availableMembers.map((member) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          _addParticipantToSession(member.id);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.cardBg,
                          padding: const EdgeInsets.all(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.blue,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (member.memberNumber != null)
                                    Text(
                                      '# ${member.memberNumber}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.add_circle, color: Colors.green),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.cardBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addParticipantToSession(int memberId) {
    if (widget.activeSession == null) return;

    final member = _getMember(memberId);
    if (member == null) return;

    // Add to shooting order (participant IDs werden automatisch im home_screen aktualisiert)
    final updatedOrder = [...widget.activeSession!.shootingOrder, memberId];

    widget.onUpdateShootingOrder(updatedOrder);
    
    // Also need to update participant IDs
    setState(() {
      // This will be handled by the parent updating the session
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${member.name} added to session'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showDeleteDialog(int runId) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Run'),
        content: const Text('Are you sure you want to delete this run?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteRun(runId);
              Navigator.pop(c);
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

  void _showSessionSettings() {
    if (widget.activeSession == null) return;
    
    final maxPointsCtrl = TextEditingController(
      text: widget.activeSession!.maxPoints?.toString() ?? '200',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.cardBg,
        title: const Text('Session Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: maxPointsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Maximum Points',
                hintText: 'e.g., 200',
                helperText: 'Used for perfect score calculation (🎯)',
                helperStyle: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final maxPoints = int.tryParse(maxPointsCtrl.text);
              if (maxPoints != null && maxPoints > 0) {
                widget.onUpdateSessionSettings?.call(maxPoints);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Max points set to $maxPoints'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}

// Reorder Dialog with Drag & Drop
class _ReorderDialog extends StatefulWidget {
  final List<Member> members;
  final Function(List<Member>) onReorder;

  const _ReorderDialog({
    required this.members,
    required this.onReorder,
  });

  @override
  State<_ReorderDialog> createState() => _ReorderDialogState();
}

class _ReorderDialogState extends State<_ReorderDialog> {
  late List<Member> _orderedMembers;

  @override
  void initState() {
    super.initState();
    _orderedMembers = List.from(widget.members);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reorder Shooting Order',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drag to reorder',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _orderedMembers.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final member = _orderedMembers.removeAt(oldIndex);
                    _orderedMembers.insert(newIndex, member);
                  });
                },
                itemBuilder: (context, index) {
                  final member = _orderedMembers[index];
                  return Container(
                    key: ValueKey(member.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.drag_handle, color: Colors.grey),
                        const SizedBox(width: 12),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            member.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.cardBg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onReorder(_orderedMembers);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}