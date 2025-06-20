import 'package:flutter/material.dart';

class Logo extends StatelessWidget {
  final double size;
  const Logo({this.size = 120, super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset('assets/logo.png', width: size, height: size);
  }
}
