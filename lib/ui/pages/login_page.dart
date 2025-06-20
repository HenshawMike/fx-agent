import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/accent_button.dart';
import '../widgets/logo.dart';
import 'dashboard_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                const Logo(size: 200),
                const SizedBox(height: 24),
                TextField(decoration: InputDecoration(labelText: 'Email')),
                const SizedBox(height: 16),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                const SizedBox(height: 24),
                AccentButton(
                  label: 'Login',
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const DashboardPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                AccentButton(
                  label: 'Sign in with Google',
                  onPressed: () {},
                  icon: Icons.login,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Register',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
