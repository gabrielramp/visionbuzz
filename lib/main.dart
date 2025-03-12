import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'contacts.dart' as contactsWidget;
import 'upload.dart' as uploadWidget;
import 'device.dart' as deviceWidget;
import 'settings.dart' as settingsWidget;
import 'home.dart' as homeWidget;
import 'themes.dart' as themes;
import 'auth_landing_page.dart';
import 'auth_provider.dart';

@pragma('vm:entry-point')
Future<void> handleForegroundNotifications(RemoteMessage message) async {
  print("Foregrounded");
  await deviceWidget.DevicePage().writeToVibrator(int.parse(message.data['vib_pattern']));
  print("Data: ${message.data}, vibe pattern: ${message.data['vib_pattern']}");
  print("ID: ${message.messageId}");
}

@pragma('vm:entry-point')
Future<void> handleBackgroundNotifications(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Background notification");
  await deviceWidget.DevicePage().writeToVibrator(int.parse(message.data['vib_pattern']));
  print("Data: ${message.data}, vibe pattern: ${message.data['vib_pattern']}");
  print("ID: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: true,
    sound: true,
  );
  await messaging.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  print('User granted permission: ${settings.authorizationStatus}');

  FirebaseMessaging.onBackgroundMessage(handleBackgroundNotifications);
  FirebaseMessaging.onMessage.listen(handleForegroundNotifications);

  // Request permissions for iOS
  print('User granted permission: ${settings.authorizationStatus}');

  // Get the device token
  String? token = await messaging.getToken();
  final FlutterSecureStorage keyStore = const FlutterSecureStorage();
  
  print("Firebase device token: $token");
  
  runApp(ChangeNotifierProvider(
    create: (_) => AuthProvider(), 
    child: MyApp(fbToken: token as String)
  ));
}

const double iconSize = 40;

class MyApp extends StatelessWidget {
  final String fbToken;
  const MyApp({super.key, required this.fbToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VisionBuzz',
      theme: themes.Themes.main,
      home: AuthStateHandler(fbToken: fbToken),
    );
  }
}

// New class to handle auth state changes
class AuthStateHandler extends StatefulWidget {
  final String fbToken;
  
  AuthStateHandler({required this.fbToken});
  
  @override
  _AuthStateHandlerState createState() => _AuthStateHandlerState();
}

class _AuthStateHandlerState extends State<AuthStateHandler> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If user is logged in, show MainAppScreen, otherwise show AuthLandingPage
        if (authProvider.isLoggedIn) {
          return MainAppScreen(
            fbToken: widget.fbToken,
            onLogout: () {
              // This will be called when logout is triggered
              authProvider.logout();
            },
          );
        } else {
          return AuthLandingPage(fbToken: widget.fbToken);
        }
      },
    );
  }
}

class MainAppScreen extends StatefulWidget {
  final String fbToken;
  final VoidCallback onLogout;
  
  MainAppScreen({
    required this.fbToken, 
    required this.onLogout,
  });
  
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 2;  // Start with Home tab selected
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      initialIndex: _currentIndex,
      length: 5,
      vsync: this,
    );
    
    // Listen for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: TabBarView(
        controller: _tabController,
        children: [
          uploadWidget.UploadPage(),
          contactsWidget.ContactsPage(),
          homeWidget.HomePage(),
          deviceWidget.DevicePage(),
          SettingsPage(
            fbToken: widget.fbToken,
            onLogout: widget.onLogout,
          ),
        ],
      ),
      bottomNavigationBar: ColoredBox(
        color: colorScheme.primary,
        child: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: "Upload",
              icon: Icon(Icons.upload,
                  size: iconSize, color: colorScheme.secondary),
            ),
            Tab(
              text: "Contacts",
              icon: Icon(Icons.person,
                  size: iconSize, color: colorScheme.secondary),
            ),
            Tab(
              text: "Home",
              icon: Icon(Icons.home_filled,
                  size: iconSize, color: colorScheme.secondary),
            ),
            Tab(
              text: "Device",
              icon: Icon(Icons.linked_camera,
                  size: iconSize, color: colorScheme.secondary),
            ),
            Tab(
              text: "Settings",
              icon: Icon(Icons.settings,
                  size: iconSize, color: colorScheme.secondary),
            ),
          ],
          overlayColor: MaterialStateProperty.all(colorScheme.secondary),
          indicatorColor: colorScheme.secondary,
          unselectedLabelColor: colorScheme.secondary,
          labelColor: colorScheme.secondary,
        ),
      ),
    );
  }
}

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Theme settings not implemented yet')),
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
