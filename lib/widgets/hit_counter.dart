import 'package:flutter/material.dart';

class HitCounter extends StatefulWidget {
  final ValueChanged<int> onPointsChanged;
  final int initialPoints;

  const HitCounter({
    super.key,
    required this.onPointsChanged,
    this.initialPoints = 0,
  });

  @override
  State<HitCounter> createState() => _HitCounterState();
}

class _HitEntry {
  final String label;
  final int points;

  _HitEntry(this.label, this.points);
}

class _HitCounterState extends State<HitCounter> {
  late int _totalPoints;
  final List<_HitEntry> _selectedHits = [];
  bool _majorScoring = false;

  @override
  void initState() {
    super.initState();
    _totalPoints = widget.initialPoints;
  }

  void _addHit(String hitType, int points) {
    setState(() {
      _selectedHits.add(_HitEntry(hitType, points));
      _totalPoints += points;
    });
    widget.onPointsChanged(_totalPoints);
  }

  void _undoLastHit() {
    if (_selectedHits.isNotEmpty) {
      final lastHit = _selectedHits.removeLast();
      setState(() {
        _totalPoints -= lastHit.points;
      });
      widget.onPointsChanged(_totalPoints);
    }
  }

  void _reset() {
    setState(() {
      _selectedHits.clear();
      _totalPoints = 0;
    });
    widget.onPointsChanged(0);
  }

  int _scoreForHitType(String hitType) {
    switch (hitType) {
      case 'A':
        return 5;
      case 'C':
        return _majorScoring ? 4 : 3;
      case 'D':
        return _majorScoring ? 2 : 1;
      case 'Penalty':
        return -10;
      default:
        return 0;
    }
  }

  Widget _buildHitButton(String label, int points, Color color) {
    return ElevatedButton(
      onPressed: () => _addHit(label, points),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            '$points pts',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scoring Calculator',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Minor')),
                  ButtonSegment(value: true, label: Text('Major')),
                ],
                selected: {_majorScoring},
                onSelectionChanged: (value) {
                  setState(() {
                    _majorScoring = value.first;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Hit buttons grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildHitButton('A', _scoreForHitType('A'), Colors.green),
            _buildHitButton('C', _scoreForHitType('C'), Colors.orange),
            _buildHitButton('D', _scoreForHitType('D'), Colors.amber),
            _buildHitButton('Penalty', _scoreForHitType('Penalty'), Colors.red),
          ],
        ),
        const SizedBox(height: 16),
        // Display total points and hit history
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a2a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[700]!),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Points',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _totalPoints.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Shots Taken',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _selectedHits.length.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_selectedHits.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  children: _selectedHits
                      .map(
                        (hit) => Chip(
                          label: Text(hit.label),
                          onDeleted: () {
                            setState(() {
                              _selectedHits.remove(hit);
                              _totalPoints -= hit.points;
                            });
                            widget.onPointsChanged(_totalPoints);
                          },
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Undo and Reset buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedHits.isEmpty ? null : _undoLastHit,
                icon: const Icon(Icons.undo),
                label: const Text('Undo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedHits.isEmpty ? null : _reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
