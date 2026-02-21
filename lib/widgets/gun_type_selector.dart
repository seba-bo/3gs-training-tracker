import 'package:flutter/material.dart';
import '../models/gun_type.dart';
import '../utils/gun_helpers.dart';
import '../utils/constants.dart';

class GunTypeSelector extends StatelessWidget {
  final GunType selected;
  final Function(GunType) onChanged;
  final bool compact;

  const GunTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: GunType.values.map((gun) {
        final isLast = gun == GunType.shotgun;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : (compact ? 4 : 8)),
            child: ElevatedButton(
              onPressed: () => onChanged(gun),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected == gun
                    ? Colors.blue
                    : AppConstants.cardBg,
                padding: EdgeInsets.symmetric(
                  vertical: compact ? 8 : 12,
                ),
              ),
              child: Text(
                GunHelpers.getFullName(gun),
                style: TextStyle(fontSize: compact ? 11 : 14),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}