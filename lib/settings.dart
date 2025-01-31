import 'package:flutter/material.dart';
import 'themes.dart' as themer;
import 'package:settings_ui/settings_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  final List<String> settingsHeaders = <String>[
    'Login & Registration',
    'Account',
    ''
  ];

  Future<http.Response> makeGetCall() {
    return http.get(Uri.parse('http://159.223.99.186/api/v1/register'));
  }

  final List<int> sectionLengths = <int>[2, 2, 0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: SettingsList(
          sections: [
            SettingsSection(
              title: Text('Login & Registration'),
              tiles: <SettingsTile>[
                SettingsTile.navigation(
                  leading: Icon(Icons.login),
                  title: Text('Login'),
                  onPressed: (context) {
                    // Custom onPressed action
                    clickedMe(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AccountScreen(header: "Login"),
                      ),
                    );
                  },
                  // value: Text('English'),
                ),
                SettingsTile.navigation(
                  leading: Icon(Icons.app_registration),
                  title: Text('Register'),
                  onPressed: (context) {
                    // Custom onPressed action
                    clickedMe(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AccountScreen(header: "Register"),
                      ),
                    );
                  },
                  // value: Text('English'),
                ),
                // SettingsTile.switchTile(
                //   onToggle: (value) {},
                //   initialValue: true,
                //   leading: Icon(Icons.format_paint),
                //   title: Text('Enable custom theme'),
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  dynamic clickedMe(BuildContext context) {
    print("FUCK");
  }

  Widget settingsSections(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: 3,
      itemBuilder: (BuildContext context, int index) {
        return Column(
            // height: 50,
            // color: Colors.amber[colorCodes[index]],
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  settingsHeaders[index],
                  style: textTheme.headlineMedium,
                ),
              ),
              settingsRows(context, sectionLengths[index], 'C')
            ]);
      },
      separatorBuilder: (BuildContext context, int index) =>
          Divider(color: colorScheme.primary, thickness: 1, height: 2),
    );
  }

  Widget settingsRows(
      BuildContext context, int contactsInSection, String startsWith) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: contactsInSection,
      itemBuilder: (BuildContext context, int index) {
        return individualSetting(
            context, "${startsWith} Contact #${index + 1}");
      },
      separatorBuilder: (BuildContext context, int index) => Divider(
        color: colorScheme.primary,
      ),
    );
  }

  Widget individualSetting(BuildContext context, String name) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    return Container(
        // color: Colors.red,
        height: 75,
        // width: MediaQuery.of(context).size.width,
        child: FractionallySizedBox(
          heightFactor: 1,
          widthFactor: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  name,
                  style: textTheme.headlineSmall,
                )
              ],
            ),
          ),
        ));
  }
}

final _formKey = GlobalKey<FormState>();

class AccountScreen extends StatelessWidget {
  final String header;

  void register(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://159.223.99.186/api/v1/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, String>{'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      print(response.body);
    }
  }

  AccountScreen({required this.header});
  @override
  Widget build(BuildContext context) {
    String username = "";
    String pwd = "";
    return Scaffold(
        appBar: AppBar(
          title: Text(header),
          centerTitle: false,
        ),
        body: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Enter your username',
                ),
                onSaved: (value) {
                  username = value ?? '';
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                ),
                onSaved: (value) {
                  pwd = value ?? '';
                },
                validator: (String? value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter some text';
                  }
                  return null;
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    _formKey.currentState?.save();
                    if (this.header == "Register") {
                      register(username, pwd);
                    }
                    // print("Username: $username, Password:$pwd");
                  },
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ));
  }
}

// class UserInfo {
//   final String username;
//   final String password;

//   const UserInfo({required this.username, required this.password});

//   factory UserInfo.fromJson(Map<String, dynamic> json) {
//     return switch (json) {
//       {
//         'id': int id,
//         'title': String title,
//       } =>
//         UserInfo(
//           id: id,
//           title: title,
//         ),
//       _ => throw const FormatException('Failed to load album.'),
//     };
// }
