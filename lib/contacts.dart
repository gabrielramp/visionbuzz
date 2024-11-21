import 'package:flutter/material.dart';
import 'themes.dart' as themes;
import 'dart:math';

class ContactsPage extends StatelessWidget {
  ContactsPage({super.key});

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

  final String customizableLeadingString = "Whatever you want really";
  final int maxContacts = 10;

  @override
  Widget build(BuildContext context) {
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
      physics: NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: contactsInSection,
      itemBuilder: (BuildContext context, int index) {
        return contactRow(context,
            "${startsWith} Contact #${index + 1} / ${customizableLeadingString}");
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
    return Container(
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
                    height: 100,
                    margin: EdgeInsets.only(right:20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey,
                    ),
                    child: Container(
                      padding:EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                      Icons.person,
                      size: 90,
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
