import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/training_session.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_input.dart';
import '../widgets/member_card.dart';
import '../dialogs/add_member_dialog.dart';
import '../dialogs/edit_member_dialog.dart';
import '../services/session_html_importer.dart';

class MembersScreen extends StatefulWidget {
  final List<Member> members;
  final List<TrainingSession> sessionHistory;
  final Function(Member) onAddMember;
  final Function(int) onDeleteMember;
  final Function(Member) onUpdateMember;

  const MembersScreen({
    super.key,
    required this.members,
    required this.sessionHistory,
    required this.onAddMember,
    required this.onDeleteMember,
    required this.onUpdateMember,
  });

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  int _getTotalSessions(int memberId) {
    return widget.sessionHistory
        .where((s) => s.participantIds.contains(memberId))
        .length;
  }

  int _getTotalRuns(int memberId) {
    return widget.sessionHistory
        .expand((s) => s.runs)
        .where((r) => r.memberId == memberId)
        .length;
  }

  List<Member> _getFilteredMembers() {
    var members = List<Member>.from(widget.members);

    // Sort alphabetically
    members.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      members = members.where((m) {
        return m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (m.memberNumber?.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ??
                false);
      }).toList();
    }

    return members;
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = _getFilteredMembers();

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search bar
            CustomCard(
              child: CustomInput(
                hint: 'Search members...',
                controller: _searchCtrl,
                prefixIcon: const Icon(Icons.search, size: 20),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
            const SizedBox(height: 16),

            // Members list
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _searchQuery.isEmpty
                        ? 'All Members (${widget.members.length})'
                        : 'Found ${filteredMembers.length} of ${widget.members.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (filteredMembers.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No members yet\nTap + to add a member'
                              : 'No members found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    ...filteredMembers.map(
                      (member) => MemberCard(
                        member: member,
                        totalSessions: _getTotalSessions(member.id),
                        totalRuns: _getTotalRuns(member.id),
                        onEdit: () => _showEditMemberDialog(member),
                        onDelete: () => _showDeleteDialog(member),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMemberDialog(),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, size: 32),
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Dialog kann nur mit Cancel Button geschlossen werden
      builder: (context) => AddMemberDialog(
        onAdd: widget.onAddMember,
        onBulkFromHtml: _bulkImportFromHtml,
      ),
    );
  }

  void _showEditMemberDialog(Member member) {
    showDialog(
      context: context,
      builder: (context) =>
          EditMemberDialog(member: member, onSave: widget.onUpdateMember),
    );
  }

  void _showDeleteDialog(Member member) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Delete "${member.name}"? Historical data will be kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDeleteMember(member.id);
              Navigator.pop(c);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkImportFromHtml() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['html', 'htm'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.single.bytes;
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected HTML file')),
      );
      return;
    }

    final names = SessionHtmlImporter.extractMemberNames(utf8.decode(bytes));
    if (names.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No Complete Training Data members found'),
        ),
      );
      return;
    }

    final existingNames = widget.members
        .map((member) => member.name.trim().toLowerCase())
        .toSet();
    var nextId = widget.members.isEmpty
        ? 1
        : widget.members
                  .map((member) => member.id)
                  .reduce((a, b) => a > b ? a : b) +
              1;

    var added = 0;
    var skipped = 0;
    for (final name in names) {
      final key = name.trim().toLowerCase();
      if (existingNames.contains(key)) {
        skipped++;
        continue;
      }

      widget.onAddMember(Member(id: nextId++, name: name.trim()));
      existingNames.add(key);
      added++;
    }

    if (!mounted) return;
    final message = added == 0
        ? 'All $skipped members already exist'
        : 'Added $added member${added == 1 ? '' : 's'}'
              '${skipped > 0 ? '; $skipped already existed' : ''}';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
