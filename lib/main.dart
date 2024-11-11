import 'package:flutter/material.dart';
import 'contacts.dart' as contactsWidget;
import 'upload.dart' as uploadWidget;
import 'device.dart' as deviceWidget;
import 'settings.dart' as settingsWidget;

void main() {
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
        '/settings': (context) => settingsWidget.SettingsPage()
      },
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            primary: const Color(0xff4f009e),
            secondary: const Color(0xffffffff),
            // surface: const Color(0xff00000),
            seedColor: Colors.red),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Theme.of(context).colorScheme.surface,
            icon: Icon(Icons.business),
            label: 'Business',
          ),
          BottomNavigationBarItem(
            backgroundColor: Theme.of(context).colorScheme.surface,
            icon: Icon(Icons.school),
            label: 'School',
          )
        ],
        currentIndex: 0,
        selectedItemColor: Colors.amber[800],
        // shape: const CircularNotchedRectangle(),

        // onTap: _onItemTapped,
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        padding: EdgeInsets.symmetric(vertical: 0, horizontal: 100.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            // Upload Button
            FloatingActionButton(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder(),
              onPressed: () => goToPage('/upload'),
              heroTag: null,
              child: Icon(Icons.upload, size: iconSize),
            ),

            // Contacts Button
            FloatingActionButton(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder(),
              onPressed: () => goToPage('/contacts'),
              heroTag: null,
              child: Icon(Icons.person, size: iconSize),
            ),

            // Home Button
            FloatingActionButton(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder(),
              onPressed: () => goToPage('/home'),
              heroTag: null,
              child: Icon(Icons.home_filled, size: iconSize),
            ),

            // Device Button
            FloatingActionButton(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder(),
              onPressed: () => goToPage('/device'),
              heroTag: null,
              child: Icon(Icons.linked_camera, size: iconSize),
            ),

            // Settings Button
            FloatingActionButton(
              foregroundColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: CircleBorder(),
              onPressed: () => goToPage('/settings'),
              heroTag: null,
              child: Icon(Icons.settings, size: iconSize),
            ),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
