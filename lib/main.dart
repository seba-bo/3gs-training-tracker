import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const IPSCTrackerApp());
}

class IPSCTrackerApp extends StatelessWidget {
  const IPSCTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3GS Training',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF0f172a),
      ),
      home: const IPSCTrackerHome(),
    );
  }
}

class Shooter {
  final int id;
  final String name;
  final List<Run> runs;

  Shooter({required this.id, required this.name, required this.runs});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'runs': runs.map((r) => r.toJson()).toList(),
  };

  factory Shooter.fromJson(Map<String, dynamic> json) {
    return Shooter(
      id: json['id'],
      name: json['name'],
      runs: (json['runs'] as List).map((r) => Run.fromJson(r)).toList(),
    );
  }
}

class Run {
  final int id;
  final double time;
  final int points;
  final double hitFactor;
  final String gun;

  Run({
    required this.id,
    required this.time,
    required this.points,
    required this.hitFactor,
    required this.gun,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'time': time,
    'points': points,
    'hitFactor': hitFactor,
    'gun': gun,
  };

  factory Run.fromJson(Map<String, dynamic> json) {
    return Run(
      id: json['id'],
      time: json['time'],
      points: json['points'],
      hitFactor: json['hitFactor'],
      gun: json['gun'],
    );
  }
}

// Small value object to return icon + label together
class GunInfo {
  final String icon;
  final String label;
  const GunInfo(this.icon, this.label);
}

class IPSCTrackerHome extends StatefulWidget {
  const IPSCTrackerHome({super.key});

  @override
  State<IPSCTrackerHome> createState() => _IPSCTrackerHomeState();
}

class _IPSCTrackerHomeState extends State<IPSCTrackerHome> {
  int _currentScreen = 0;
  List<Shooter> shooters = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  Shooter? _selectedShooter;
  String _gunType = 'pistol';
  String _leaderboardView = 'hitfactor';
  String _gunFilter = 'pistol';
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    final data = _prefs.getString('shooters');
    if (data != null) {
      final List<dynamic> jsonList = jsonDecode(data);
      setState(() {
        shooters = jsonList.map((s) => Shooter.fromJson(s)).toList();
      });
    }
  }

  Future<void> _saveData() async {
    final jsonList = shooters.map((s) => s.toJson()).toList();
    await _prefs.setString('shooters', jsonEncode(jsonList));
  }

  void _cleanBoard() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean Board'),
        content: const Text('Are you sure you want to delete all shooters and runs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                shooters.clear();
              });
              _saveData();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addShooter() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        shooters.add(Shooter(
          id: DateTime.now().millisecondsSinceEpoch,
          name: _nameController.text.trim(),
          runs: [],
        ));
        _nameController.clear();
      });
      _saveData();
    }
  }
  void _removeShooter(int id) {
    setState(() {
      shooters.removeWhere((s) => s.id == id);
    });
    _saveData();
  }

  void _recordScore() {
    final time = double.tryParse(_timeController.text);
    final points = int.tryParse(_pointsController.text);

    if (time != null && time > 0 && points != null && points >= 0) {
      setState(() {
        final shooter = shooters.firstWhere((s) => s.id == _selectedShooter!.id);
        shooter.runs.add(Run(
          id: DateTime.now().millisecondsSinceEpoch,
          time: time,
          points: points,
          hitFactor: points / time,
          gun: _gunType,
        ));
        _timeController.clear();
        _pointsController.clear();
        _gunType = 'pistol';
        _selectedShooter = null;
        _currentScreen = 0;
      });
      _saveData();
    }
  }

  void _deleteRun(int shooterId, int runId) {
    setState(() {
      final shooter = shooters.firstWhere((s) => s.id == shooterId);
      shooter.runs.removeWhere((r) => r.id == runId);
    });
    _saveData();
  }

  Run? _getBestRun(Shooter shooter, String criterion, String? filterGun) {
    var runs = filterGun != null
        ? shooter.runs.where((r) => r.gun == filterGun).toList()
        : shooter.runs;

    if (runs.isEmpty) return null;

    if (criterion == 'hitfactor') {
      return runs.reduce((a, b) => a.hitFactor > b.hitFactor ? a : b);
    } else {
      return runs.reduce((a, b) => a.points > b.points ? a : b);
    }
  }

  List<Shooter> _getSortedShooters() {
    final filterGun = _gunFilter;
    final filtered = shooters.where((s) {
      final best = _getBestRun(s, _leaderboardView, filterGun);
      return best != null;
    }).toList();

    filtered.sort((a, b) {
      final bestA = _getBestRun(a, _leaderboardView, filterGun)!;
      final bestB = _getBestRun(b, _leaderboardView, filterGun)!;
      if (_leaderboardView == 'hitfactor') {
        return bestB.hitFactor.compareTo(bestA.hitFactor);
      } else {
        return bestB.points.compareTo(bestA.points);
      }
    });

    return filtered;
  }

  GunInfo _getGunInfo(String gun) {
    switch (gun) {
      case 'pistol':
        return const GunInfo('🔫', 'Pistol');
      case 'pcc':
        return const GunInfo('🏹', 'PCC');
      case 'shotgun':
        return const GunInfo('💥', 'Shotgun');
      default:
        return const GunInfo('❓', 'Unknown');
    }
  }

  void _copyLeaderboardToClipboard() {
    final sorted = _getSortedShooters();
    final buffer = StringBuffer();

    buffer.writeln(_leaderboardView == 'hitfactor'
        ? 'Rankings by Best Hit Factor'
        : 'Rankings by Best Points');
    buffer.writeln('(${_getGunInfo(_gunFilter).label})');
    buffer.writeln();

    if (sorted.isEmpty) {
      buffer.writeln('No scores recorded yet for ${_getGunInfo(_gunFilter).label}');
    } else {
      for (final entry in sorted.asMap().entries) {
        final index = entry.key;
        final shooter = entry.value;
        final best = _getBestRun(
          shooter,
          _leaderboardView,
          _gunFilter,
        )!;

        final medal = index == 0
            ? '🥇'
            : index == 1
                ? '🥈'
                : index == 2
                    ? '🥉'
                    : '${index + 1}';

        buffer.write('$medal ${shooter.name}: ');
        if (_leaderboardView == 'hitfactor') {
          buffer.write(best.hitFactor.toStringAsFixed(2));
        } else {
          buffer.write(best.points);
        }
        buffer.writeln(' (${best.points} pts in ${best.time}s)');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Leaderboard copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0f172a), Color(0xFF1e293b)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('🎯', style: TextStyle(fontSize: 32)),
                        SizedBox(width: 8),
                        Text(
                          '3GS Training Tracker',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Multiple runs - Best score counts',
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _currentScreen = 0),
                        icon: const Icon(Icons.people),
                        label: const Text('Shooters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentScreen == 0
                              ? Colors.blue
                              : const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _currentScreen = 1),
                        icon: const Icon(Icons.emoji_events),
                        label: const Text('Rankings'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentScreen == 1
                              ? Colors.blue
                              : const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: _currentScreen == 0
                    ? _buildRosterScreen()
                    : _selectedShooter != null
                        ? _buildScoreScreen()
                        : _buildLeaderboardScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRosterScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Add Shooter and Clean Board
          Row(
            children: [
              Container(
                width: 80,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Reset',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _cleanBoard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(40, 40),
                      ),
                      child: const Icon(Icons.delete_forever),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Shooter',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                hintText: 'Shooter name',
                                filled: true,
                                fillColor: const Color(0xFF334155),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              onSubmitted: (_) => _addShooter(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addShooter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Shooters List
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1e293b),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shooters (${shooters.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                shooters.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No shooters added yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: shooters.map((shooter) {
                          final pistolRuns = shooter.runs.where((r) => r.gun == 'pistol').toList();
                          final pccRuns = shooter.runs.where((r) => r.gun == 'pcc').toList();
                          final shotgunRuns = shooter.runs.where((r) => r.gun == 'shotgun').toList();
                          final bestPistol = pistolRuns.isNotEmpty
                              ? _getBestRun(Shooter(id: 0, name: '', runs: pistolRuns), 'hitfactor', null)
                              : null;
                          final bestPcc = pccRuns.isNotEmpty
                              ? _getBestRun(Shooter(id: 0, name: '', runs: pccRuns), 'hitfactor', null)
                              : null;
                          final bestShotgun = shotgunRuns.isNotEmpty
                              ? _getBestRun(Shooter(id: 0, name: '', runs: shotgunRuns), 'hitfactor', null)
                              : null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF334155),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              shooter.name,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (shooter.runs.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              if (bestPistol != null)
                                                Text(
                                                  '${_getGunInfo('pistol').icon} ${_getGunInfo('pistol').label} best: ${bestPistol.hitFactor.toStringAsFixed(2)} (${pistolRuns.length} run${pistolRuns.length != 1 ? 's' : ''})',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              if (bestPcc != null)
                                                Text(
                                                  '${_getGunInfo('pcc').icon} ${_getGunInfo('pcc').label} best: ${bestPcc.hitFactor.toStringAsFixed(2)} (${pccRuns.length} run${pccRuns.length != 1 ? 's' : ''})',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              if (bestShotgun != null)
                                                Text(
                                                  '${_getGunInfo('shotgun').icon} ${_getGunInfo('shotgun').label} best: ${bestShotgun.hitFactor.toStringAsFixed(2)} (${shotgunRuns.length} run${shotgunRuns.length != 1 ? 's' : ''})',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                            ] else
                                              Text(
                                                'No runs yet',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedShooter = shooter;
                                            _currentScreen = 1;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: const Text('Add Run'),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _removeShooter(shooter.id),
                                        icon: const Icon(Icons.close),
                                        color: Colors.red,
                                      ),
                                    ],
                                  ),
                                ),
                                // Show the shooter's run history here (deleteable).
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: shooter.runs.isNotEmpty
                                      ? shooter.runs.map((r) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  '${_getGunInfo(r.gun).icon} ${r.points} pts • ${r.time}s • HF ${r.hitFactor.toStringAsFixed(2)}',
                                                  style: TextStyle(fontSize: 12, color: Colors.grey[300]),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  onPressed: () => _deleteRun(shooter.id, r.id),
                                                  icon: const Icon(Icons.delete, size: 18),
                                                  color: Colors.red,
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList()
                                      : [const SizedBox.shrink()],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreScreen() {
    final hitFactor = double.tryParse(_timeController.text) != null &&
            double.parse(_timeController.text) > 0 &&
            int.tryParse(_pointsController.text) != null
        ? int.parse(_pointsController.text) / double.parse(_timeController.text)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedShooter!.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Run #${_selectedShooter!.runs.length + 1}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(height: 24),

            // Gun Type
            const Text(
              'Gun Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _gunType = 'pistol'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gunType == 'pistol'
                          ? Colors.blue
                          : const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('${_getGunInfo('pistol').icon} ${_getGunInfo('pistol').label}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _gunType = 'pcc'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gunType == 'pcc'
                          ? Colors.blue
                          : const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('${_getGunInfo('pcc').icon} ${_getGunInfo('pcc').label}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _gunType = 'shotgun'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gunType == 'shotgun'
                          ? Colors.blue
                          : const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('${_getGunInfo('shotgun').icon} ${_getGunInfo('shotgun').label}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Time
            const Text(
              'Time (seconds)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _timeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g., 12.45',
                filled: true,
                fillColor: const Color(0xFF334155),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Points
            const Text(
              'Points',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g., 85',
                filled: true,
                fillColor: const Color(0xFF334155),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Hit Factor Display
            if (hitFactor != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'Hit Factor',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hitFactor.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedShooter = null;
                        _timeController.clear();
                        _pointsController.clear();
                        _gunType = 'pistol';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: hitFactor != null ? _recordScore : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Run'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

Widget _buildGunFilterRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _gunFilter = 'pistol'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gunFilter == 'pistol'
                  ? Colors.purple
                  : const Color(0xFF334155),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('${_getGunInfo('pistol').icon} ${_getGunInfo('pistol').label}', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _gunFilter = 'pcc'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gunFilter == 'pcc'
                  ? Colors.purple
                  : const Color(0xFF334155),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('${_getGunInfo('pcc').icon} ${_getGunInfo('pcc').label}', style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _gunFilter = 'shotgun'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gunFilter == 'shotgun'
                  ? Colors.purple
                  : const Color(0xFF334155),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: Text('${_getGunInfo('shotgun').icon} ${_getGunInfo('shotgun').label}', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreTypeRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _leaderboardView = 'hitfactor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _leaderboardView == 'hitfactor'
                  ? Colors.blue
                  : const Color(0xFF334155),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('By Hit Factor'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _leaderboardView = 'points'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _leaderboardView == 'points'
                  ? Colors.blue
                  : const Color(0xFF334155),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text('By Points'),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardContent() {
    final sorted = _getSortedShooters();

    return GestureDetector(
      onLongPress: _copyLeaderboardToClipboard,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _leaderboardView == 'hitfactor'
                      ? Icons.emoji_events
                      : Icons.military_tech,
                  color: _leaderboardView == 'hitfactor'
                      ? Colors.yellow
                      : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _leaderboardView == 'hitfactor'
                        ? 'Rankings by Best Hit Factor'
                        : 'Rankings by Best Points',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (_gunFilter != 'all')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '(${_getGunInfo(_gunFilter).label} only)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ),
            const SizedBox(height: 16),
            sorted.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No scores recorded yet${_gunFilter != 'all' ? ' for ${_getGunInfo(_gunFilter).label}' : ''}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : Column(
                    children: sorted.asMap().entries.map((entry) {
                      final index = entry.key;
                      final shooter = entry.value;
                      final best = _getBestRun(
                        shooter,
                        _leaderboardView,
                        _gunFilter == 'all' ? null : _gunFilter,
                      )!;
                      final filteredRuns = _gunFilter == 'all'
                          ? shooter.runs
                          : shooter.runs.where((r) => r.gun == _gunFilter).toList();

                      final medal = index == 0
                          ? '🥇'
                          : index == 1
                              ? '🥈'
                              : index == 2
                                  ? '🥉'
                                  : '${index + 1}';

                      final bgColor = index == 0
                          ? const Color(0xFF854d0e)
                          : index == 1
                              ? const Color(0xFF334155)
                              : index == 2
                                  ? const Color(0xFF7c2d12)
                                  : const Color(0xFF334155);

                      final borderColor = index == 0
                          ? Colors.yellow
                          : index == 1
                              ? Colors.grey
                              : index == 2
                                  ? Colors.orange
                                  : Colors.transparent;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(
                            color: borderColor,
                            width: index < 3 ? 2 : 0,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32,
                              child: Text(
                                medal,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_getGunInfo(best.gun).icon} ${shooter.name}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${best.points} pts in ${best.time}s',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _leaderboardView == 'hitfactor'
                                      ? best.hitFactor.toStringAsFixed(2)
                                      : best.points.toString(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _leaderboardView == 'hitfactor'
                                        ? Colors.green
                                        : Colors.blue,
                                  ),
                                ),
                                Text(
                                  _leaderboardView == 'hitfactor'
                                      ? 'best HF'
                                      : 'best points',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Gun Filter
          _buildGunFilterRow(),
          const SizedBox(height: 8),

          // Score Type
          _buildScoreTypeRow(),
          const SizedBox(height: 16),

          // Leaderboard
          _buildLeaderboardContent(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

}
