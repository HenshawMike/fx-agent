import 'package:flutter/material.dart';

class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool toggled;
  final IconData? icon;
  const AccentButton({required this.label, required this.onPressed, this.toggled = false, this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: toggled ? const Color(0xFFFF3C38) : Colors.transparent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: Color(0xFFFF3C38)),
        elevation: toggled ? 8 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      onPressed: onPressed,
    );
  }
}
