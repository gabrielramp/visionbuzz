import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'contacts.dart' as contactsWidget;
import 'upload.dart' as uploadWidget;
import 'device.dart' as deviceWidget;
import 'settings.dart' as settingsWidget;
import 'home.dart' as homeWidget;
import 'main.dart' as mainPage;
import 'themes.dart' as themes;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions for iOS
  NotificationSettings settings = await messaging.requestPermission();
  print('User granted permission: ${settings.authorizationStatus}');

  // Get the device token
  String? token = await messaging.getToken();
  print("Firebase device token: $token");
  runApp(const MyApp());
}

const double iconSize = 40;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/home': (context) => MyApp(),
        '/contacts': (context) => contactsWidget.ContactsPage(),
        '/upload': (context) => uploadWidget.UploadPage(),
        '/device': (context) => deviceWidget.DevicePage(),
        '/settings': (context) => settingsWidget.SettingsPage(),
        '/tabs': (context) => homeWidget.HomePage(),
      },
      title: 'Flutter Demo',
      theme: themes.Themes.main,
      home: DefaultTabController(
        initialIndex: 3,
        length: 5,
        child: const MyHomePage(title: 'VisionBuzz'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  goToPage(String route) {
    return Navigator.pushNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        // appBar: AppBar(
        //   // TRY THIS: Try changing the color here to a specific color (to
        //   // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        //   // change color while the other colors stay the same.
        //   backgroundColor: colorScheme.inversePrimary,
        //   // Here we take the value from the MyHomePage object that was created by
        //   // the App.build method, and use it to set our appbar title.
        //   title: Text(widget.title),
        // ),
        body: TabBarView(
          // Center is a layout widget. It takes a single child and positions it
          // in the middle of the parent.
          children: [
            uploadWidget.UploadPage(),
            contactsWidget.ContactsPage(),
            homeWidget.HomePage(),
            deviceWidget.DevicePage(),
            settingsWidget.SettingsPage(),
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
