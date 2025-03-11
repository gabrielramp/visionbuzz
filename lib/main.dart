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
import 'main.dart' as mainPage;
import 'themes.dart' as themes;
import 'package:provider/provider.dart';
import 'auth_provider.dart';

var yahoo = "bingo";
@pragma('vm:entry-point')
Future<void> handleNotification(RemoteMessage message) async {
  await Firebase.initializeApp();
  yahoo = "poopoo";
  print("Poopooo");
  await deviceWidget.DevicePage().writeToVibrator(1);
  print(message);
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

  FirebaseMessaging.onBackgroundMessage(handleNotification);

  // Request permissions for iOS
  print('User granted permission: ${settings.authorizationStatus}');

  // Get the device token
  String? token = await messaging.getToken();
  final FlutterSecureStorage keyStore = const FlutterSecureStorage();
  // keyStore.write(
  //     key: DateTime.timestamp().microsecondsSinceEpoch.toString(),
  //     value: "Kill Me");
  print("Firebase device token: $token");
  runApp(ChangeNotifierProvider(
      create: (_) => AuthProvider(), child: MyApp(fbToken: token as String)));
}

const double iconSize = 40;

class MyApp extends StatelessWidget {
  final String fbToken;
  const MyApp({super.key, required this.fbToken});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/home': (context) => MyApp(
              fbToken: this.fbToken,
            ),
        '/contacts': (context) => contactsWidget.ContactsPage(),
        '/upload': (context) => uploadWidget.UploadPage(),
        '/device': (context) => deviceWidget.DevicePage(),
        '/settings': (context) => settingsWidget.SettingsPage(fbToken: fbToken),
        '/tabs': (context) => homeWidget.HomePage(),
      },
      title: 'Flutter Demo',
      theme: themes.Themes.main,
      home: DefaultTabController(
        initialIndex: 2,
        length: 5,
        child: MyHomePage(
          title: 'VisionBuzz',
          fbToken: fbToken,
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String fbToken;
  const MyHomePage({super.key, required this.title, required this.fbToken});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState(fbToken: fbToken);
}

class _MyHomePageState extends State<MyHomePage> {
  final String fbToken;
  _MyHomePageState({required this.fbToken});
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  goToPage(String route) {
    return Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
        body: TabBarView(
          children: [
            uploadWidget.UploadPage(),
            contactsWidget.ContactsPage(),
            homeWidget.HomePage(),
            deviceWidget.DevicePage(),
            settingsWidget.SettingsPage(
              fbToken: this.fbToken,
            ),
          ],
        ),
        bottomNavigationBar: ColoredBox(
          color: colorScheme.primary,
          child: TabBar(
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
        ));
  }
}
