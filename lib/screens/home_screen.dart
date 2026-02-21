import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/training_session.dart';
import '../models/run.dart';
import '../models/gun_type.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import 'members_screen.dart';
import 'session_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppScreen _currentScreen = AppScreen.members;
  List<Member> _members = [];
  List<TrainingSession> _sessionHistory = [];
  TrainingSession? _activeSession;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final members = await StorageService.loadMembers();
    final history = await StorageService.loadSessionHistory();
    final activeSession = await StorageService.loadActiveSession();

    setState(() {
      _members = members;
      _sessionHistory = history;
      _activeSession = activeSession;
      _isLoading = false;
    });

    // Show recovery message if active session was found
    if (activeSession != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Active session recovered: ${activeSession.runs.length} runs',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _saveMembersData() async {
    await StorageService.saveMembers(_members);
  }

  Future<void> _saveHistoryData() async {
    await StorageService.saveSessionHistory(_sessionHistory);
  }

  void _addMember(Member member) {
    setState(() => _members.add(member));
    _saveMembersData();
  }

  void _deleteMember(int id) {
    setState(() => _members.removeWhere((m) => m.id == id));
    _saveMembersData();
  }

  void _updateMember(Member updatedMember) {
    setState(() {
      final index = _members.indexWhere((m) => m.id == updatedMember.id);
      if (index != -1) {
        _members[index] = updatedMember;
      }
    });
    _saveMembersData();
  }

  void _startSession(List<int> participantIds) {
    if (participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    setState(() {
      _activeSession = TrainingSession(
        id: DateTime.now().millisecondsSinceEpoch,
        date: DateTime.now(),
        participantIds: participantIds,
        runs: [],
      );
      // Stay on session screen - don't switch to roster
    });
    
    // Save active session immediately for crash recovery
    _saveActiveSession();
  }

  void _endSession() {
    if (_activeSession == null) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('End Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to end this session?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('• ${_activeSession!.participantIds.length} participants'),
            Text('• ${_activeSession!.runs.length} runs recorded'),
            const SizedBox(height: 12),
            const Text(
              'The session will be saved to history. You can resume it later if needed.',
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
              Navigator.pop(c);
              _performEndSession();
            },
            child: const Text(
              'End Session',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _performEndSession() {
    if (_activeSession == null) return;

    // Save to history
    setState(() {
      _sessionHistory.add(_activeSession!);
      _activeSession = null;
    });
    _saveHistoryData();
    
    // Clear temporary active session storage
    StorageService.clearActiveSession();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session saved to history'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addRun(Run run) {
    if (_activeSession == null) return;

    setState(() {
      _activeSession!.runs.add(run);
    });
    
    // Save active session for crash recovery
    _saveActiveSession();
  }

  void _deleteRun(int runId) {
    if (_activeSession == null) return;

    setState(() {
      _activeSession!.runs.removeWhere((r) => r.id == runId);
    });
    
    // Save active session for crash recovery
    _saveActiveSession();
  }

  void _updateRun(Run updatedRun) {
    if (_activeSession == null) return;

    setState(() {
      final index = _activeSession!.runs.indexWhere((r) => r.id == updatedRun.id);
      if (index != -1) {
        _activeSession!.runs[index] = updatedRun;
      }
    });
    
    // Save active session for crash recovery
    _saveActiveSession();
  }

  void _updateShootingOrder(List<int> newOrder) {
    if (_activeSession == null) return;

    setState(() {
      // Update both shooting order and participant IDs
      // This allows adding new participants to the session
      final currentParticipants = Set<int>.from(_activeSession!.participantIds);
      final newParticipants = Set<int>.from(newOrder);
      
      // Merge: keep existing and add new ones
      final allParticipants = {...currentParticipants, ...newParticipants}.toList();
      
      _activeSession = _activeSession!.copyWith(
        participantIds: allParticipants,
        shootingOrder: newOrder,
      );
    });
    
    // Save active session for crash recovery
    _saveActiveSession();
  }

  void _updateSessionMaxPoints(int maxPoints) {
    if (_activeSession == null) return;
    
    setState(() {
      _activeSession = _activeSession!.copyWith(maxPoints: maxPoints);
    });
    _saveActiveSession();
  }

  void _deleteHistorySession(int sessionId) {
    setState(() {
      _sessionHistory.removeWhere((s) => s.id == sessionId);
    });
    _saveHistoryData();
  }

  void _resumeSession(TrainingSession session) {
    if (_activeSession != null) {
      // Show warning if there's already an active session
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please end the current session first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Remove from history
      _sessionHistory.removeWhere((s) => s.id == session.id);
      // Make it active
      _activeSession = session;
      // Switch to session screen
      _currentScreen = AppScreen.session;
    });
    
    _saveHistoryData();
    _saveActiveSession();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session resumed!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveActiveSession() async {
    if (_activeSession != null) {
      await StorageService.saveActiveSession(_activeSession!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppConstants.primaryBg,
              AppConstants.secondaryBg,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              if (_activeSession != null) _buildActiveSessionBar(),
              _buildNavigation(),
              const SizedBox(height: 16),
              Expanded(child: _buildCurrentScreen()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3GS Training',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Member & Session Management',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSessionBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active Session: ${_activeSession!.participantIds.length} participants, ${_activeSession!.runs.length} runs',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _navButton(Icons.people, 'Members', AppScreen.members),
          const SizedBox(width: 4),
          _navButton(Icons.calendar_today, 'Session', AppScreen.session),
          const SizedBox(width: 4),
          _navButton(Icons.history, 'History', AppScreen.history),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, String label, AppScreen screen) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => setState(() => _currentScreen = screen),
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: _currentScreen == screen
              ? Colors.blue
              : AppConstants.cardBg,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case AppScreen.members:
        return MembersScreen(
          members: _members,
          sessionHistory: _sessionHistory,
          onAddMember: _addMember,
          onDeleteMember: _deleteMember,
          onUpdateMember: _updateMember,
        );
      case AppScreen.session:
        return SessionScreen(
          members: _members,
          activeSession: _activeSession,
          onStartSession: _startSession,
          onAddRun: _addRun,
          onDeleteRun: _deleteRun,
          onUpdateRun: _updateRun,
          onEndSession: _endSession,
          onUpdateShootingOrder: _updateShootingOrder,
          onUpdateSessionSettings: _updateSessionMaxPoints,
        );
      case AppScreen.history:
        return HistoryScreen(
          members: _members,
          sessionHistory: _sessionHistory,
          onDeleteSession: _deleteHistorySession,
          onResumeSession: _resumeSession,
        );
    }
  }
}