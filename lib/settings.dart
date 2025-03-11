import 'package:flutter/material.dart';
import 'package:visionbuzz/auth_provider.dart';
import 'themes.dart' as themer;
import 'package:settings_ui/settings_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class SettingsPage extends StatelessWidget {
  final String fbToken;
  SettingsPage({super.key, required this.fbToken});
  var authProvider;

  final List<String> settingsHeaders = <String>[
    'Login & Registration',
    'Account',
    'Logout',
    ''
  ];

  Future<http.Response> makeGetCall() {
    return http.get(Uri.parse('http://159.223.99.186/api/v1/register'));
  }
  // 401 = Username taken
  // 200 = hunky dory

  final List<int> sectionLengths = <int>[2, 2, 0];

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);

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
                        builder: (context) => AccountScreen(header: "Login", fbToken:this.fbToken),
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
                        builder: (context) => AccountScreen(header: "Register", fbToken:this.fbToken),
                      ),
                    );
                  },
                  // value: Text('English'),
                ),
                SettingsTile.navigation(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onPressed: (context) {
                    // Custom onPressed action
                    print("Logged Out");

                    authProvider.logout();
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

final _formKey = GlobalKey<FormState>(); // CJ - Check this out later

class AccountScreen extends StatelessWidget {
  final String header;
  var authProvider;
  final String fbToken;

  AccountScreen({required this.header, required this.fbToken});

  void register(String username, String password, String token) async {
    final response = await http.post(
      Uri.parse('http://159.223.99.186/api/v1/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, String>{'username': username, 'password': password, 'firebase_token': token}),
    );
    if (response.statusCode == 200) {
      // print(response.body);
      print("REGISTER PASS");
      var accessToken = jsonDecode(response.body)['access_token'];
      print("Specifically access token = " + accessToken);
      authProvider.login(accessToken);
    } else if (response.statusCode == 401) {
      print("Username taken");
    } else {
      print("Something went wrong");
    }
  }

  void login(String username, String password) async {
    final response = await http.post(
      Uri.parse('http://159.223.99.186/api/v1/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(
          <String, String>{'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      // print(response.body);
      print("Login PASS");
      var accessToken = jsonDecode(response.body)['access_token'];
      print("Specifically access token = " + accessToken);
      authProvider.login(accessToken);
    } else if (response.statusCode == 401) {
      print("Bad login info");
    } else {
      print("Something unforeseen went wrong");
    }
  }

  @override
  Widget build(BuildContext context) {
    String username = "";
    String pwd = "";
    this.authProvider = Provider.of<AuthProvider>(context);
    return GestureDetector(
        onTap: () {
          // print("Fook");
        },
        behavior: HitTestBehavior.translucent,
        child: Scaffold(
            appBar: AppBar(
              title: Text(header),
              centerTitle: false,
            ),
            body: Form(
              key: _formKey,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 50.0),
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
                        obscureText: true,
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
                              register(username, pwd, fbToken);
                              print("Pushed da register button");
                            } else {
                              login(username, pwd);
                              print("Pushed da login button");
                            }
                            // print("Username: $username, Password:$pwd");
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  )),
            )));
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
