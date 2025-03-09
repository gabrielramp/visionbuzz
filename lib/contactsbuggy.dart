import 'dart:ffi';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'themes.dart' as themes;
import 'auth_provider.dart';
import 'auth_service.dart';
//stupidmanthing
//imfuckingballing

class Contact {
  int cid;
  String last_seen;
  String name;
  var vibration;
  Contact({required this.cid, required this.name, required this.last_seen});

  @override
  String toString() {
    return ("name: " +
        this.name +
        " cid: " +
        this.cid.toString() +
        " last_seen: " +
        this.last_seen);
  }
}

class ContactsPage extends StatelessWidget {
  ContactsPage({super.key});
  var authService;
  var authProvider;
  int numSections = 0;
  List<Contact> contacts = new List<Contact>.empty(growable: true);
  Map<String, int> letters = {
    'A': 0,
    'B': 0,
    'C': 0,
    'D': 0,
    'E': 0,
    'F': 0,
    'G': 0,
    'H': 0,
    'I': 0,
    'J': 0,
    'K': 0,
    'L': 0,
    'M': 0,
    'N': 0,
    'O': 0,
    'P': 0,
    'Q': 0,
    'R': 0,
    'S': 0,
    'T': 0,
    'U': 0,
    'V': 0,
    'W': 0,
    'X': 0,
    'Y': 0,
    'Z': 0,
    '?': 0
  };
  Map<String, int> filledLetters = new Map<String, int>();

  Future<http.Response> getContacts() async {
    var token = await authProvider.getToken();
    print(token);
    final response = await http.get(
      Uri.parse('http://159.223.99.186/api/v1/pull_contacts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': ('Bearer ' + token),
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> body = await jsonDecode(response.body);
      print("All good");
      for (dynamic contact in body) {
        this.contacts.add(new Contact(
            cid: contact['cid'],
            name: contact['name'],
            last_seen: contact['last_seen']));
        //letters.add
        String firstLetter = contact['name'].trim()[0].toUpperCase();
        if (letters[firstLetter] != null) if (letters[firstLetter] == 0)
          numSections += 1;
        letters[firstLetter] = (letters[firstLetter] ?? 0) + 1;
      }
      // var accessToken = jsonDecode(response.body)['access_token'];
      // print("Specifically access token = " + accessToken);
      // authProvider.login(accessToken);
    } else if (response.statusCode == 401) {
      print("Bad login info");
      print(jsonDecode(response.body));
    } else {
      print("Something unforeseen went wrong");
      print("Error Code: " + response.statusCode.toString());
      print(response.body);
    }
    this.contacts.sort(contactComparison);
    return response;
  }

    void editContact(int cid, String name, int vib_pattern) async {
    final response = await http.patch(
      Uri.parse('http://159.223.99.186/api/v1/edit_contact'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'cid': cid, 'name': name, 'vib_pattern': vib_pattern}),
    );
    if (response.statusCode == 200) {
      // print(response.body);
      print("editContact PASS");
    } else if (response.statusCode == 401) {
      print("Bad call info");
    } else {
      print("Something unforeseen went wrong");
    }
  }

  int contactComparison(Contact a, Contact b) {
    String aname = a.name;
    String bname = b.name;
    return aname.compareTo(bname);
  }

  final String customizableLeadingString = "What";
  final int maxContacts = 10;

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    // if (authProvider.isLoggedIn) {
    //   getContacts();
    //   print(this.contacts);
    // }
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    // this.contacts = getContacts();
    return Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          centerTitle: false,
        ),
        body: FutureBuilder(
            future: getContacts(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              return Align(
                  alignment: Alignment.topLeft,
                  child: GestureDetector(
                    onTap: () => print(this.contacts),
                    child: alphabetSections(context),
                  ));
            }));
  }

  Widget alphabetSections(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    print(this.numSections);
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: this.numSections,
      itemBuilder: (BuildContext context, int index) {
        return Column(
            // height: 50,
            // color: Colors.amber[colorCodes[index]],
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  contacts[index].name.trim()[0].toUpperCase(),
                  style: textTheme.headlineMedium,
                ),
              ),
              letterContacts(
                  context,
                  (letters[contacts[index].name.trim()[0].toUpperCase()] ?? 0),
                  index)
            ]);
      },
      separatorBuilder: (BuildContext context, int index) =>
          Divider(color: colorScheme.primary, thickness: 1, height: 2),
    );
  }

  Widget letterContacts(
      BuildContext context, int contactsInSection, int bigIndex) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: contactsInSection,
      itemBuilder: (BuildContext context, int index) {
        return contactRow(context, contacts[bigIndex].name);
      },
      separatorBuilder: (BuildContext context, int index) => Divider(
        color: colorScheme.primary,
      ),
    );
  }

  GestureDetector(
    onTap: () {
      editContactClick(context);
    },
    child: Widget contactRow(BuildContext context, String name) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    return SizedBox(
        // color: Colors.red,
        height: 100,
        // width: MediaQuery.of(context).size.width,
        child: FractionallySizedBox(
          heightFactor: 1,
          widthFactor: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                    height: 75,
                    margin: const EdgeInsets.only(right: 20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: colorScheme.secondary,
                        ))),
                Text(
                  name,
                  style: textTheme.headlineSmall,
                )
              ],
            ),
          ),
        ));
  });
  
  Future<void> editContactClick(BuildContext context) async {
    var canVibe = await Vibration.hasCustomVibrationsSupport();
    print(canVibe);
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        eturn editContactDialog(context: context);
      },
    );
    }
  // Widget contactRow(BuildContext context, String name) {
  //   ColorScheme colorScheme = Theme.of(context).colorScheme;
  //   return SizedBox(
  //     // color: Colors.blue,
  //     height: 100,
  //     // width: MediaQuery.of(context).size.width,
  //     child: Align(
  //       alignment: Alignment.centerLeft,
  //       child: Row(
  //         children: [
  //           Icon(Icons.person, size: 100, color: colorScheme.secondary),
  //           Text(name)
  //         ],
  //       ),
  //     ),
  //   );
  // }
}


class editContactDialog extends StatelessWidget {
  var event;
  editContactDialog({required context});

  @override
  Widget build(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;

    return Dialog(
        child: SizedBox(
      // color: Colors.red,
      height: 800,
      // width: MediaQuery.of(context).size.width,
      child: Column(children: [
        Padding(
            padding: EdgeInsets.only(top: 20),
            child: Row(
              children: [
                Container(
                    margin: const EdgeInsets.only(right: 5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.person,
                          size: 70,
                          color: colorScheme.secondary,
                        ))),
                Expanded(
                    child: TextField(
                  controller: TextEditingController(text: event.name),
                  style: textTheme.headlineMedium,
                )),
                ElevatedButton(
                    onPressed: () => {
                      HapticFeedback.vibrate()},
                    child: Text("Vibes"))
              ],
            ))
      ]),
    ));
  }
}
