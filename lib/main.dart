import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'ui/pages/login_page.dart';
import 'ui/pages/dashboard_page.dart';
import 'ui/pages/agent_control_page.dart';
import 'ui/pages/logs_page.dart';
import 'ui/pages/settings_page.dart';

void main() {
  runApp(const StroudAIApp());
}

class StroudAIApp extends StatelessWidget {
  const StroudAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stroud AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/agent': (context) => const AgentControlPage(),
        '/logs': (context) => const LogsPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
