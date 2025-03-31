import 'package:flutter/material.dart';
import 'package:visionbuzz/auth_provider.dart';
import 'themes.dart' as themer;
import 'package:settings_ui/settings_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

// Updated Settings Page that only has logout (no login/register)
class SettingsPage extends StatelessWidget {
  final String fbToken;
  final VoidCallback onLogout;
  
  SettingsPage({
    required this.fbToken,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ColorScheme colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: ListView(
        children: [
          // Account section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[100],
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Firebase token info
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Device Information'),
            subtitle: Text('Your device is registered with our service'),
            onTap: () {
              // Show device token info
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Device Token'),
                  content: SingleChildScrollView(
                    child: Text(
                      fbToken,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('CLOSE'),
                    ),
                  ],
                ),
              );
            },
          ),
          
          Divider(),
          
          // Theme settings (placeholder for now)
          ListTile(
            leading: Icon(Icons.color_lens),
            title: Text('App Theme'),
            subtitle: Text('Change app appearance'),
            onTap: () {
              // Theme settings functionality could be added here
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Choose Theme:'),
                  content: Text('This will change the primary color of the app'),
                  actions: [
                    TextButton(
                      onPressed: () => colorScheme.primary,
                      child: Text('Blue'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Call the onLogout callback
                        onLogout();
                      },
                      child: Text(
                        'LOGOUT',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          Divider(),
          
          // Notification settings (placeholder for now)
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Manage notification settings'),
            onTap: () {
              // Notification settings functionality could be added here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notification settings not implemented yet')),
              );
            },
          ),
          
          Divider(),
          
          // Logout option
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Logout'),
                  content: Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Call the onLogout callback
                        onLogout();
                      },
                      child: Text(
                        'LOGOUT',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          
          SizedBox(height: 50),
          
          // App version info
          Center(
            child: Text(
              'VisionBuzz v1.0.0',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}