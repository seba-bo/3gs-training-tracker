// models/member.dart

class Member {
  final int id;
  final String name;
  final String? memberNumber;

  Member({
    required this.id,
    required this.name,
    this.memberNumber,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'memberNumber': memberNumber,
      };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
        id: json['id'],
        name: json['name'],
        memberNumber: json['memberNumber'],
      );

  Member copyWith({
    int? id,
    String? name,
    String? memberNumber,
  }) =>
      Member(
        id: id ?? this.id,
        name: name ?? this.name,
        memberNumber: memberNumber ?? this.memberNumber,
      );
}