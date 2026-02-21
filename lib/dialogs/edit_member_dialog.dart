import 'package:flutter/material.dart';
import '../models/member.dart';
import '../widgets/custom_input.dart';
import '../utils/constants.dart';

class EditMemberDialog extends StatefulWidget {
  final Member member;
  final Function(Member) onSave;

  const EditMemberDialog({
    super.key,
    required this.member,
    required this.onSave,
  });

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _numberCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.member.name);
    _numberCtrl = TextEditingController(text: widget.member.memberNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final updatedMember = widget.member.copyWith(
      name: _nameCtrl.text.trim(),
      memberNumber: _numberCtrl.text.trim().isEmpty
          ? null
          : _numberCtrl.text.trim(),
    );

    widget.onSave(updatedMember);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Member',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Member Name',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            CustomInput(
              hint: 'Enter name',
              controller: _nameCtrl,
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Member Number (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            CustomInput(
              hint: 'e.g., #123',
              controller: _numberCtrl,
              onSubmitted: (_) => _save(),
            ),
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
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}