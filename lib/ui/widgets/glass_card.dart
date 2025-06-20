import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 16)],
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }
}
