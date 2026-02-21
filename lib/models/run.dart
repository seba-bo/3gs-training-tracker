// models/run.dart

import 'gun_type.dart';

class Run {
  final int id;
  final int memberId;
  final double time;
  final int points;
  final GunType gun;
  final int penalties;
  final String? stageName;
  final String? notes;

  Run({
    required this.id,
    required this.memberId,
    required this.time,
    required this.points,
    required this.gun,
    this.penalties = 0,
    this.stageName,
    this.notes,
  });

  int get finalPoints => points - penalties;
  double get finalHitFactor => (((finalPoints / time) * 100).floor() / 100);

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'time': time,
        'points': points,
        'gun': gun.name,
        'penalties': penalties,
        'stageName': stageName,
        'notes': notes,
      };

  factory Run.fromJson(Map<String, dynamic> json) => Run(
        id: json['id'],
        memberId: json['memberId'],
        time: json['time'],
        points: json['points'],
        gun: GunType.values.firstWhere((e) => e.name == json['gun']),
        penalties: json['penalties'] ?? 0,
        stageName: json['stageName'],
        notes: json['notes'],
      );

  Run copyWith({
    int? id,
    int? memberId,
    double? time,
    int? points,
    GunType? gun,
    int? penalties,
    String? stageName,
    String? notes,
  }) =>
      Run(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        time: time ?? this.time,
        points: points ?? this.points,
        gun: gun ?? this.gun,
        penalties: penalties ?? this.penalties,
        stageName: stageName ?? this.stageName,
        notes: notes ?? this.notes,
      );
}