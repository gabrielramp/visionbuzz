import 'package:flutter/material.dart';
import 'themes.dart' as themes;
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'dart:convert';
import 'auth_service.dart';
//stupidmanthing
//imfuckingballing
class ContactsPage extends StatelessWidget {
  ContactsPage({super.key});
  var authService;
  var authProvider;
  
  Future<http.Response> getContacts() async{
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
      for(var c=0; c<3; c++){
      var body = await response.body;
      print("All good");
      print(body);}
      // var accessToken = jsonDecode(response.body)['access_token'];
      // print("Specifically access token = " + accessToken);
      // authProvider.login(accessToken);
    } else if (response.statusCode == 401) {
      print("Bad login info");
      print(jsonDecode(response.body));
    } else {
      print("Something unforeseen went wrong");
      print("Error Code: "+response.statusCode.toString());
      print(response.body);

    }
    return response;
  }

  final List<String> letterHeads = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    '?'
  ];

  final String customizableLeadingString = "What";
  final int maxContacts = 10;

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    if(authProvider.isLoggedIn){
      print(getContacts());
    }
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: false,
      ),
      body: Align(
        alignment: Alignment.topLeft,
        child: alphabetSections(context),
      ),
    );
  }

  Widget alphabetSections(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: 27,
      itemBuilder: (BuildContext context, int index) {
        return Column(
            // height: 50,
            // color: Colors.amber[colorCodes[index]],
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  letterHeads[index],
                  style: textTheme.headlineMedium,
                ),
              ),
              letterContacts(context, Random().nextInt(maxContacts - 1) + 1,
                  letterHeads[index])
            ]);
      },
      separatorBuilder: (BuildContext context, int index) =>
          Divider(color: colorScheme.primary, thickness: 1, height: 2),
    );
  }

  Widget letterContacts(
      BuildContext context, int contactsInSection, String startsWith) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: contactsInSection,
      itemBuilder: (BuildContext context, int index) {
        return contactRow(context,
            "$startsWith Contact #${index + 1} / $customizableLeadingString");
      },
      separatorBuilder: (BuildContext context, int index) => Divider(
        color: colorScheme.primary,
      ),
    );
  }

  Widget contactRow(BuildContext context, String name) {
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
                    margin: const EdgeInsets.only(right:20),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                    child: Container(
                      padding:const EdgeInsets.symmetric(horizontal: 10),
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
