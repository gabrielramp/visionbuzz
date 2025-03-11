import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'auth_provider.dart';

// Improved cache with alphabetical organization
class ContactsCache {
  static List<Contact> contacts = [];
  static Map<String, List<Contact>> contactsByLetter = {};
  static List<String> orderedLetters = [];
  static bool loaded = false;
  
  // To force FutureBuilder to rebuild with a new Future
  static int refreshCounter = 0;
  
  // Call this to force a refresh
  static void invalidate() {
    loaded = false;
    // Increment counter to force new Future creation
    refreshCounter++;
  }
  
  // Organize contacts by first letter
  static void organizeByLetter() {
    contactsByLetter.clear();
    orderedLetters.clear();
    
    // Sort contacts alphabetically by name
    contacts.sort((a, b) => a.name.compareTo(b.name));
    
    // Group contacts by first letter
    for (var contact in contacts) {
      String firstLetter = contact.name.trim()[0].toUpperCase();
      if (!contactsByLetter.containsKey(firstLetter)) {
        contactsByLetter[firstLetter] = [];
        orderedLetters.add(firstLetter);
      }
      contactsByLetter[firstLetter]!.add(contact);
    }
    
    // Sort letters alphabetically
    orderedLetters.sort();
  }
}

class Contact {
  int cid;
  String last_seen;
  String name;
  var vibration;
  Contact({required this.cid, required this.name, required this.last_seen, required this.vibration});

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

class ContactsPage extends StatefulWidget {
  ContactsPage({Key? key}) : super(key: key);
  
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  var authProvider;
  // This key will change whenever we need to refresh the FutureBuilder
  late Key _futureBuilderKey;
  
  @override
  void initState() {
    super.initState();
    _futureBuilderKey = ValueKey(ContactsCache.refreshCounter);
  }

  // This will create a new Future each time it's called
  Future<http.Response> getContacts() async {
    // If data is already loaded, no need to reload
    if (ContactsCache.loaded && ContactsCache.contacts.isNotEmpty) {
      return Future<http.Response>.value(
          http.Response("Already loaded", 200));
    }
    
    // Always clear data before loading - this prevents duplicates
    ContactsCache.contacts = [];
    
    var token = await authProvider.getToken();
    print("Fetching contacts with token: $token");
    final response = await http.get(
      Uri.parse('http://159.223.99.186/api/v1/pull_contacts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': ('Bearer ' + token),
      },
    );
    
    if (response.statusCode == 200) {
      print("CONTACTS HERE");
      print(response.body);
      List<dynamic> body = jsonDecode(response.body);
      
      for (dynamic contact in body) {
        var contactName = contact['name'] == "" ? "Unnamed Contact" : contact['name'];
        
        ContactsCache.contacts.add(Contact(
            cid: contact['cid'],
            name: contactName,
            last_seen: contact['last_seen'],
            vibration: contact['vib_pattern']));
      }
      
      // Organize contacts by first letter for proper display
      ContactsCache.organizeByLetter();
      ContactsCache.loaded = true;
    } else if (response.statusCode == 401) {
      print("Bad login info");
      print(jsonDecode(response.body));
    } else {
      print("Something unforeseen went wrong");
      print("Error Code: " + response.statusCode.toString());
      print(response.body);
    }
    
    return response;
  }

  // Added function to delete a contact
  Future<bool> deleteContact(int cid) async {
    var token = await authProvider.getToken();
    
    final response = await http.delete(
      Uri.parse("http://159.223.99.186/api/v1/delete_contact/$cid"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': ('Bearer ' + token),
      },
    );
    
    if (response.statusCode == 200) {
      print("deleteContact PASS");
      // Invalidate cache after successful deletion
      ContactsCache.invalidate();
      return true;
    } else {
      print("Delete failed: ${response.statusCode}");
      return false;
    }
  }

  // Method to refresh UI - now updates state
  void refreshUI() {
    setState(() {
      // Update the key to force FutureBuilder to rebuild with a new Future
      _futureBuilderKey = ValueKey(ContactsCache.refreshCounter);
    });
  }

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    ThemeData themey = Theme.of(context);
    
    return Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          centerTitle: false,
          // Simple refresh button that forces reload
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () {
                ContactsCache.invalidate();
                refreshUI();
              },
            )
          ],
        ),
        body: FutureBuilder(
            key: _futureBuilderKey, // This is crucial for refresh to work
            future: getContacts(),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && 
                  ContactsCache.contacts.isEmpty) {
                return Center(child: CircularProgressIndicator());
              }
              return Align(
                alignment: Alignment.topLeft,
                child: alphabetSections(context),
              );
            }));
  }
  
  // Completely revised UI methods to properly display alphabetical sections
  Widget alphabetSections(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    
    if (ContactsCache.contacts.isEmpty) {
      return Center(child: Text("No contacts found", style: textTheme.headlineMedium));
    }
    
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: ContactsCache.orderedLetters.length,
      itemBuilder: (BuildContext context, int index) {
        String letter = ContactsCache.orderedLetters[index];
        List<Contact> contactsInSection = ContactsCache.contactsByLetter[letter] ?? [];
        
        return Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  letter,
                  style: textTheme.headlineMedium,
                ),
              ),
              contactsForLetter(context, letter, contactsInSection)
            ]);
      },
      separatorBuilder: (BuildContext context, int index) =>
          Divider(color: colorScheme.primary, thickness: 1, height: 2),
    );
  }

  Widget contactsForLetter(
      BuildContext context, String letter, List<Contact> contactsInSection) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: contactsInSection.length,
      itemBuilder: (BuildContext context, int index) {
        Contact contact = contactsInSection[index];
        return GestureDetector(
            onTap: () {
              editContactPopup(context, contact);
            },
            onLongPress: () {
              // Show delete confirmation on long press
              showDeleteConfirmation(context, contact);
            },
            child: contactRow(context, contact.name));
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
        height: 100,
        child: FractionallySizedBox(
          heightFactor: 1,
          widthFactor: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
                color: colorScheme.secondary,
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
                )),
          ),
        ));
  }

  // Added delete confirmation dialog
  Future<void> showDeleteConfirmation(BuildContext context, Contact contact) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Contact'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete ${contact.name}?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                // Delete the contact
                bool success = await deleteContact(contact.cid);
                Navigator.of(context).pop();
                
                if (success) {
                  // Cache is already invalidated in deleteContact()
                  refreshUI();
                  
                  // Show success feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Contact deleted successfully'))
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> editContactPopup(BuildContext context, Contact contact) async {
    var result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return EditContactDialog(
          contact: contact,
          authProvider: authProvider,
          onSuccess: () {
            // Immediately refresh after successful edit
            refreshUI();
          },
        );
      },
    );
  }
}

// Improved dialog that handles its own API calls and returns success status
class EditContactDialog extends StatefulWidget {
  final Contact contact;
  final authProvider;
  final Function onSuccess;
  
  EditContactDialog({
    required this.contact, 
    required this.authProvider,
    required this.onSuccess,
  });
  
  @override
  _EditContactDialogState createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<EditContactDialog> {
  late TextEditingController nameController;
  late TextEditingController vibrationController;
  bool isSaving = false;
  
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.contact.name);
    vibrationController = TextEditingController(
      text: widget.contact.vibration != null ? widget.contact.vibration.toString() : "0"
    );
  }
  
  @override
  void dispose() {
    nameController.dispose();
    vibrationController.dispose();
    super.dispose();
  }
  
  Future<void> saveContact() async {
    setState(() {
      isSaving = true;
    });
    
    String name = nameController.text;
    int vibPattern = int.tryParse(vibrationController.text) ?? 0;
    
    var token = await widget.authProvider.getToken();
    print("Params: ${widget.contact.cid}, $name, $vibPattern");
    
    final response = await http.patch(
      Uri.parse("http://159.223.99.186/api/v1/edit_contact/${widget.contact.cid}"),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': ('Bearer ' + token),
      },
      body: jsonEncode({'name': name, 'vib_pattern': vibPattern}),
    );
    
    setState(() {
      isSaving = false;
    });
    
    if (response.statusCode == 200) {
      print("editContact PASS");
      // Invalidate cache after successful edit
      ContactsCache.invalidate();
      
      // Call onSuccess callback before dismissing dialog
      widget.onSuccess();
      
      // Close the dialog
      Navigator.of(context).pop(true);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Contact updated successfully'))
      );
    } else {
      print("Edit failed: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update contact'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;

    return Dialog(
      child: SizedBox(
        height: 800,
        child: Column(
          children: [
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
                      )
                    )
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: nameController,
                      style: textTheme.headlineMedium,
                    )
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: vibrationController,
                      style: textTheme.headlineMedium,
                      keyboardType: TextInputType.number,
                    )
                  ),
                  isSaving 
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: saveContact,
                        child: Text("Save")
                      )
                ],
              )
            )
          ], 
          mainAxisSize: MainAxisSize.max
        ),
      )
    );
  }
}