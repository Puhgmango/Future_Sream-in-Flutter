import 'package:flutter/material.dart';

class ControlButtons extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const ControlButtons({
    super.key,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          label: 'Bắt đầu',
          color: const Color(0xFF00B8D4), // Teal accent
          onPressed: onStart,
        ),
        const SizedBox(width: 16),
        _buildButton(
          label: 'Tạm dừng',
          color: Colors.orangeAccent,
          onPressed: onPause,
        ),
        const SizedBox(width: 16),
        _buildButton(
          label: 'Đặt lại',
          color: Colors.redAccent,
          onPressed: onReset,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}
