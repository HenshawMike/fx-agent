import 'package:flutter/material.dart';

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Agent Logs', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Live Logs', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF23242B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListView(
                  children: const [
                    Text(
                      '[12:01] Trade executed: BUY EUR/USD @ 1.0850',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '[12:03] PnL updated: +0.46%',
                      style: TextStyle(color: Colors.greenAccent),
                    ),
                    Text(
                      '[12:05] Trade executed: SELL GBP/JPY @ 180.20',
                      style: TextStyle(color: Colors.white),
                    ),
                    Text(
                      '[12:07] PnL updated: -0.22%',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Toast notification example
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3C38).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: const Text(
                  'Trade executed!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
