// models/training_session.dart

import 'run.dart';

class TrainingSession {
  final int id;
  final DateTime date;
  final List<int> participantIds;
  final List<Run> runs;
  final String? notes;
  final List<int> shootingOrder; // Order for quick mode
  final int? maxPoints; // Maximum points for this session (for perfect score calculation)

  TrainingSession({
    required this.id,
    required this.date,
    required this.participantIds,
    required this.runs,
    this.notes,
    List<int>? shootingOrder,
    this.maxPoints,
  }) : shootingOrder = shootingOrder ?? participantIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'participantIds': participantIds,
        'runs': runs.map((r) => r.toJson()).toList(),
        'notes': notes,
        'shootingOrder': shootingOrder,
        'maxPoints': maxPoints,
      };

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      TrainingSession(
        id: json['id'],
        date: DateTime.parse(json['date']),
        participantIds: List<int>.from(json['participantIds']),
        runs: (json['runs'] as List).map((r) => Run.fromJson(r)).toList(),
        notes: json['notes'],
        shootingOrder: json['shootingOrder'] != null 
            ? List<int>.from(json['shootingOrder'])
            : List<int>.from(json['participantIds']),
        maxPoints: json['maxPoints'],
      );

  TrainingSession copyWith({
    int? id,
    DateTime? date,
    List<int>? participantIds,
    List<Run>? runs,
    String? notes,
    List<int>? shootingOrder,
    int? maxPoints,
  }) =>
      TrainingSession(
        id: id ?? this.id,
        date: date ?? this.date,
        participantIds: participantIds ?? this.participantIds,
        runs: runs ?? this.runs,
        notes: notes ?? this.notes,
        shootingOrder: shootingOrder ?? this.shootingOrder,
        maxPoints: maxPoints ?? this.maxPoints,
      );
}