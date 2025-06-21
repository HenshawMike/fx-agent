import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../widgets/accent_button.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mt5LoginController = TextEditingController();
  final TextEditingController _mt5PasswordController = TextEditingController();
  final TextEditingController _mt5ServerController = TextEditingController();
  final TextEditingController _mt5PathController = TextEditingController();

  String _connectionStatus = "Not Connected";
  Color _statusColor = Colors.orangeAccent;
  bool _isLoading = false;
  String _mt5LibraryStatus = "MT5 Library: Unknown";

  // TODO: Replace with your actual backend URL
  final String _baseUrl = "http://localhost:8000";

  @override
  void initState() {
    super.initState();
    _fetchConnectionStatus();
  }

  @override
  void dispose() {
    _mt5LoginController.dispose();
    _mt5PasswordController.dispose();
    _mt5ServerController.dispose();
    _mt5PathController.dispose();
    super.dispose();
  }

  Future<void> _fetchConnectionStatus() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('$_baseUrl/settings/mt5_credentials'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _mt5LoginController.text = data['login']?.toString() ?? '';
          _mt5ServerController.text = data['server'] ?? '';
          _mt5PathController.text = data['path'] ?? '';
          // Password is not returned by the GET endpoint, so don't try to set it.
          // _mt5PasswordController.text remains as user typed or empty.

          if (data['connected'] == true) {
            _connectionStatus = "Connected";
            _statusColor = Colors.greenAccent;
          } else {
            _connectionStatus = data['message'] ?? "Disconnected";
            _statusColor = Colors.redAccent;
          }
          _mt5LibraryStatus = data['mt5_library_available'] == true
              ? "MT5 Library: Available"
              : "MT5 Library: Not Available";
        });
      } else {
        setState(() {
          _connectionStatus = "Error fetching status: ${response.statusCode}";
          _statusColor = Colors.redAccent;
          _mt5LibraryStatus = "MT5 Library: Unknown";
        });
      }
    } catch (e) {
      setState(() {
        _connectionStatus = "Error: ${e.toString()}";
        _statusColor = Colors.redAccent;
        _mt5LibraryStatus = "MT5 Library: Unknown";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAndConnectMT5() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String login = _mt5LoginController.text;
      final String password = _mt5PasswordController.text;
      final String server = _mt5ServerController.text;
      final String? path = _mt5PathController.text.isNotEmpty ? _mt5PathController.text : null;

      // Basic validation for password as it's not part of the form validation (can be empty if not changing)
      // However, for an initial connection attempt, it's required.
      // The backend will ultimately validate.
      if (password.isEmpty && _connectionStatus.toLowerCase().contains("not connected")) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password is required to establish a new connection.')),
          );
          setState(() { _isLoading = false; });
          return;
      }


      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/settings/mt5_credentials'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'login': int.tryParse(login) ?? 0, // Ensure login is int
            'password': password,
            'server': server,
            if (path != null) 'path': path,
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['connected'] == true) {
          setState(() {
            _connectionStatus = "Connected";
            _statusColor = Colors.greenAccent;
            // Clear password field after successful submission for security
            _mt5PasswordController.clear();
             _mt5LibraryStatus = data['mt5_library_available'] == true
              ? "MT5 Library: Available"
              : "MT5 Library: Not Available";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('MT5 Credentials Saved & Connected!')),
          );
        } else {
          setState(() {
            _connectionStatus = data['message'] ?? "Connection Failed";
            _statusColor = Colors.redAccent;
             _mt5LibraryStatus = data['mt5_library_available'] == true
              ? "MT5 Library: Available"
              : "MT5 Library: Not Available";
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed: ${data['message'] ?? 'Unknown error'}')),
          );
        }
      } catch (e) {
        setState(() {
          _connectionStatus = "Error: ${e.toString()}";
          _statusColor = Colors.redAccent;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
        // Optionally, refresh status after attempt
        _fetchConnectionStatus();
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF3C38)),
      ),
      errorStyle: TextStyle(color: Colors.redAccent[100]),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent[100]!),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.redAccent[100]!, width: 2.0),
      ),
    );
  }

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
      drawer: Drawer( // Keep the existing drawer
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
              title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_input_antenna, color: Colors.white70),
              title: const Text('Agent Control', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/agent'),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt, color: Colors.white70),
              title: const Text('Logs', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/logs'),
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.white70),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Profile Info (Keep existing, or remove if not relevant to this task)
              const Text('Profile', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),

              // MetaTrader 5 Credentials
              const Text('MetaTrader 5 Credentials', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mt5LoginController,
                decoration: _inputDecoration('MT5 Login (e.g., 1234567)'),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter MT5 Login ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Login ID must be a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mt5PasswordController,
                decoration: _inputDecoration('MT5 Password'),
                style: const TextStyle(color: Colors.white),
                obscureText: true,
                // Password can be empty if user is only updating other fields and connection is already established
                // However, for a new connection, it's needed. This is handled in _saveAndConnectMT5.
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mt5ServerController,
                decoration: _inputDecoration('MT5 Server (e.g., MetaQuotes-Demo, YourBroker-Server)'),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter MT5 Server name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mt5PathController,
                decoration: _inputDecoration('MT5 Path (Optional, Windows: C:\\...\\terminal64.exe)'),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 24),
              AccentButton(
                label: _isLoading ? 'Connecting...' : 'Save & Connect MT5',
                onPressed: _isLoading ? null : _saveAndConnectMT5,
              ),
              const SizedBox(height: 24),

              // Broker Connection Status
              const Text('Broker Connection Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _connectionStatus == "Connected" ? Icons.check_circle : Icons.error_outline,
                    color: _statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded( // Use Expanded to allow text to wrap
                    child: Text(
                      _connectionStatus,
                      style: TextStyle(color: _statusColor, fontSize: 14),
                      softWrap: true,
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 8),
               Text(
                _mt5LibraryStatus,
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 24),

              // Existing Subscription and Billing sections (can be kept or removed as per focus)
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
