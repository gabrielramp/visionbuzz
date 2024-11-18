import 'package:flutter/material.dart';
import 'themes.dart' as themes;

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

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
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
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Expanded(
        child: ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: 27,
      itemBuilder: (BuildContext context, int index) {
        return Column(
            // height: 50,
            // color: Colors.amber[colorCodes[index]],
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(letterHeads[index]),
              ),
              letterContacts(context, 1, letterHeads[index])
            ]);
      },
      separatorBuilder: (BuildContext context, int index) => const Divider(),
    ));
  }

  Widget letterContacts(
      BuildContext context, int contactsInSection, String startsWith) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
        height: 100,
        child: ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: contactsInSection,
          itemBuilder: (BuildContext context, int index) {
            return Container(
                color: Colors.blue,
                height: 100,
                // width: MediaQuery.of(context).size.width,
                child: FractionallySizedBox(
                  heightFactor: 1,
                  widthFactor: 1,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.person,
                            size: 100, color: colorScheme.secondary),
                        Text("Contact Name Starting with ${startsWith} Here")
                      ],
                    ),
                  ),
                ));
          },
          separatorBuilder: (BuildContext context, int index) =>
              const Divider(),
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
