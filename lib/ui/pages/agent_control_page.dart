import 'package:flutter/material.dart';
import '../widgets/accent_button.dart';

class AgentControlPage extends StatefulWidget {
  const AgentControlPage({super.key});

  @override
  State<AgentControlPage> createState() => _AgentControlPageState();
}

class _AgentControlPageState extends State<AgentControlPage> {
  String _strategy = 'Scalper';
  double _risk = 0.5;
  String _selectedPair = 'EUR/USD';
  final List<String> _pairs = [
    'EUR/USD',
    'GBP/USD',
    'USD/JPY',
    'BTC/USD',
    'ETH/USD',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181A20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Agent Control',
          style: TextStyle(color: Colors.white),
        ),
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
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strategy Toggle
            Text('Strategy', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            ToggleButtons(
              borderRadius: BorderRadius.circular(16),
              fillColor: const Color(0xFFFF3C38).withOpacity(0.15),
              selectedColor: const Color(0xFFFF3C38),
              color: Colors.white70,
              isSelected: [
                _strategy == 'Scalper',
                _strategy == 'Swing',
                _strategy == 'Day',
              ],
              onPressed: (index) {
                setState(() {
                  _strategy = ['Scalper', 'Swing', 'Day'][index];
                });
              },
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Scalper'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Swing'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text('Day'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Risk Level Slider
            Text('Risk Level', style: TextStyle(color: Colors.white70)),
            Slider(
              value: _risk,
              min: 0,
              max: 1,
              divisions: 10,
              label: (_risk * 100).toStringAsFixed(0) + '%',
              activeColor: const Color(0xFFFF3C38),
              onChanged: (v) => setState(() => _risk = v),
            ),
            const SizedBox(height: 24),
            // Asset Pair Selector
            Text('Asset Pair', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedPair,
              dropdownColor: const Color(0xFF23242B),
              style: const TextStyle(color: Colors.white),
              iconEnabledColor: const Color(0xFFFF3C38),
              borderRadius: BorderRadius.circular(16),
              items:
                  _pairs
                      .map(
                        (pair) =>
                            DropdownMenuItem(value: pair, child: Text(pair)),
                      )
                      .toList(),
              onChanged: (v) => setState(() => _selectedPair = v!),
            ),
            const Spacer(),
            AccentButton(
              label: 'Save & Deploy',
              onPressed: () {},
              toggled: true,
            ),
          ],
        ),
      ),
    );
  }
}
