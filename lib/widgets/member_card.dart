import 'package:flutter/material.dart';
import '../models/member.dart';
import '../utils/constants.dart';

class MemberCard extends StatelessWidget {
  final Member member;
  final int totalSessions;
  final int totalRuns;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const MemberCard({
    super.key,
    required this.member,
    required this.totalSessions,
    required this.totalRuns,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.cardBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$totalSessions sessions',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.timeline, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$totalRuns runs',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'Edit member',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Delete member',
          ),
        ],
      ),
    );
  }
}