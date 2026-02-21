import 'package:flutter/material.dart';
import '../models/run.dart';
import '../utils/gun_helpers.dart';

class RunItem extends StatelessWidget {
  final Run run;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const RunItem({
    super.key,
    required this.run,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white10),
        ),
      ),
      child: Row(
        children: [
          Text(
            GunHelpers.getIcon(run.gun),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      run.finalHitFactor.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'HF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${run.finalPoints} pts',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${run.time}s',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (run.penalties > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '-${run.penalties} pen',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ],
                  ],
                ),
                if (run.stageName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    run.stageName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (run.notes != null && run.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    run.notes!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
            tooltip: 'Edit run',
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            tooltip: 'Delete run',
          ),
        ],
      ),
    );
  }
}