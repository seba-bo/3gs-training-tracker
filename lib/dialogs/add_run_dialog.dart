import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/run.dart';
import '../models/gun_type.dart';
import '../utils/constants.dart';
import '../widgets/gun_type_selector.dart';
import '../widgets/custom_input.dart';

class AddRunDialog extends StatefulWidget {
  final Member member;
  final Function(Run) onSave;
  final bool showSkip;
  final VoidCallback? onSkip;
  final Run? existingRun; // For editing

  const AddRunDialog({
    super.key,
    required this.member,
    required this.onSave,
    this.showSkip = false,
    this.onSkip,
    this.existingRun,
  });

  @override
  State<AddRunDialog> createState() => _AddRunDialogState();
}

class _AddRunDialogState extends State<AddRunDialog> {
  final _timeCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  
  late GunType _gunType;
  double? _hitFactor;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing run data if editing
    if (widget.existingRun != null) {
      _timeCtrl.text = widget.existingRun!.time.toString();
      _pointsCtrl.text = widget.existingRun!.points.toString();
      _gunType = widget.existingRun!.gun;
      _calculateHitFactor();
    } else {
      _gunType = GunType.pistol;
    }
  }

  @override
  void dispose() {
    _timeCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  void _calculateHitFactor() {
    final time = double.tryParse(_timeCtrl.text);
    final points = int.tryParse(_pointsCtrl.text);

    if (time != null && time > 0 && points != null) {
      setState(() => _hitFactor = ((points) / time * 100).floor() / 100);
    } else {
      setState(() => _hitFactor = null);
    }
  }

  void _save() {
    final time = double.tryParse(_timeCtrl.text);
    final points = int.tryParse(_pointsCtrl.text);

    if (time == null || points == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid time and points')),
      );
      return;
    }

    final run = Run(
      id: widget.existingRun?.id ?? DateTime.now().millisecondsSinceEpoch,
      memberId: widget.member.id,
      time: time,
      points: points,
      gun: _gunType
    );

    widget.onSave(run);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Don't do anything special on back button - just close
        return true;
      },
      child: Dialog(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.existingRun != null 
                      ? 'Edit Run for ${widget.member.name}'
                      : 'Add Run for ${widget.member.name}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                const Text('Gun Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GunTypeSelector(
                  selected: _gunType,
                  onChanged: (gun) => setState(() => _gunType = gun),
                ),
                const SizedBox(height: 16),
                _buildField('Time (seconds)', _timeCtrl, 'e.g., 12.45', isDecimal: true),
                _buildField('Points', _pointsCtrl, 'e.g., 85'),
                if (_hitFactor != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.cardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text('Hit Factor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          _hitFactor!.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.cardBg,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(widget.existingRun != null ? 'Update' : 'Save Run'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {bool isDecimal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          CustomInput(
            hint: hint,
            controller: ctrl,
            keyboardType: isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            onChanged: (_) => _calculateHitFactor(),
          ),
        ],
      ),
    );
  }
}