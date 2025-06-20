import 'package:flutter/material.dart';
import '../widgets/accent_button.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF23242B),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF181A20)),
              child: Center(
                child: Text(
                  'Stroud AI',
                  style: TextStyle(
                    color: Color(0xFFFF3C38),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.white70),
              title: const Text(
                'Dashboard',
                style: TextStyle(color: Colors.white),
              ),
              onTap:
                  () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_input_antenna,
                color: Colors.white70,
              ),
              title: const Text(
                'Agent Control',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pushReplacementNamed(context, '/agent'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.white70),
              title: const Text('Logs', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/logs'),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Profile Info
            const Text('Profile', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // API Key
            const Text('API Key', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: 'API Key',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            // Broker Connection
            Row(
              children: [
                const Text(
                  'Broker Connection:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(width: 8),
                Icon(Icons.check_circle, color: Colors.greenAccent),
                const SizedBox(width: 4),
                const Text(
                  'Connected',
                  style: TextStyle(color: Colors.greenAccent),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Subscription Status
            const Text('Subscription', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF23242B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.workspace_premium,
                  color: Color(0xFFFF3C38),
                ),
                title: const Text(
                  'Pro Plan',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Active - Billed monthly',
                  style: TextStyle(color: Colors.white54),
                ),
                trailing: AccentButton(label: 'Manage', onPressed: () {}),
              ),
            ),
            const SizedBox(height: 24),
            // Billing Card
            const Text('Billing', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Card(
              color: const Color(0xFF23242B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.credit_card, color: Colors.white54),
                title: const Text(
                  '**** **** **** 1234',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'Exp: 12/27',
                  style: TextStyle(color: Colors.white54),
                ),
                trailing: AccentButton(label: 'Update', onPressed: () {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
