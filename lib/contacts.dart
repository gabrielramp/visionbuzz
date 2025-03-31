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
    contacts.clear();
    contactsByLetter.clear();
    orderedLetters.clear();
    // Increment counter to force new Future creation
    refreshCounter++;
  }
  
  // Reset everything - call this during logout
  static void reset() {
    loaded = false;
    contacts.clear();
    contactsByLetter.clear();
    orderedLetters.clear();
    refreshCounter = 0;
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
  int vibration; // 8-bit value representing vibration pattern
  Contact({required this.cid, required this.name, required this.last_seen, required this.vibration});

  @override
  String toString() {
    return "name: $name cid: $cid last_seen: $last_seen";
  }
  
  // Convert vibration int to bit array
  List<bool> getVibrationPattern() {
    List<bool> pattern = List.filled(8, false);
    for (int i = 0; i < 8; i++) {
      pattern[7-i] = ((vibration >> i) & 1) == 1;
    }
    return pattern;
  }
  
  // Convert bit array to vibration int
  void setVibrationPattern(List<bool> pattern) {
    int value = 0;
    for (int i = 0; i < 8; i++) {
      if (pattern[7-i]) {
        value |= (1 << i);
      }
    }
    vibration = value;
  }
}

class ContactsPage extends StatefulWidget {
  ContactsPage({Key? key}) : super(key: key);
  
  @override
  _ContactsPageState createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  var authProvider;
  // This key will change whenever we need to refresh the FutureBuilder
  late Key _futureBuilderKey;
  bool _isVisible = false;
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _futureBuilderKey = ValueKey(ContactsCache.refreshCounter);
    WidgetsBinding.instance.addObserver(this);
    
    // Check if we're visible on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print("Mounted? $mounted");
        print("Visible? $_isVisible");
        _checkVisibility();
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkVisibility();
    }
  }
  
  void _checkVisibility() {
    // This would be called when the tab becomes visible
    bool isCurrentlyVisible = true; // In a real app, we'd check if this tab is selected
    
    if (isCurrentlyVisible && !_isVisible) {
      // We've just become visible, refresh
      _isVisible = true;
      refreshUI();
    } else if (!isCurrentlyVisible && _isVisible) {
      _isVisible = false;
    }
  }

  // This will create a new Future each time it's called
  Future<http.Response> getContacts() async {
    // If data is already loaded, no need to reload
    if (ContactsCache.loaded && ContactsCache.contacts.isNotEmpty) {
      return Future<http.Response>.value(
          http.Response("Already loaded", 200));
    }
    
    // Always clear data before loading - this prevents duplicates
    
    var token = await authProvider.getToken();
    print("Fetching contacts with token: $token");
    final response = await http.get(
      Uri.parse('http://137.184.156.253/api/v1/pull_contacts'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': ('Bearer ' + token),
      },
    );
    
    ContactsCache.contacts.clear();
    
    if (response.statusCode == 200) {
      print("CONTACTS HERE");
      print(response.body);
      List<dynamic> body = jsonDecode(response.body);
      
      for (dynamic contact in body) {
        var contactName = contact['name'] == "" ? "Unnamed Contact" : contact['name'];
        
        // Ensure vibration is an int and within 8-bit range
        int vibPattern = 0;
        if (contact['vib_pattern'] != null) {
          if (contact['vib_pattern'] is int) {
            vibPattern = (contact['vib_pattern'] as int).clamp(0, 255);
          } else {
            try {
              vibPattern = int.parse(contact['vib_pattern'].toString()).clamp(0, 255);
            } catch (e) {
              vibPattern = 0; // Default if parsing fails
            }
          }
        }
        
        ContactsCache.contacts.add(Contact(
            cid: contact['cid'],
            name: contactName,
            last_seen: contact['last_seen'] ?? "Unknown",
            vibration: vibPattern));
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
      Uri.parse("http://137.184.156.253/api/v1/delete_contact/$cid"),
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
      ContactsCache.invalidate();
      // Update the key to force FutureBuilder to rebuild with a new Future
      _futureBuilderKey = ValueKey(ContactsCache.refreshCounter);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    authProvider = Provider.of<AuthProvider>(context);
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    
    // Check visibility when building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
    
    return Scaffold(
        appBar: AppBar(
          title: const Text('Contacts'),
          centerTitle: false,
          // Simple refresh button that forces reload
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: refreshUI,
            )
          ],
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              refreshUI();
            },
            child: FutureBuilder(
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
                })));
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
        
        return Semantics(
          label: "Contacts that begin with the letter $letter",
          hint: "Tap on a box to edit vibration patterns and contact data",
          child:Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    letter,
                    style: textTheme.headlineMedium?.copyWith(
                      fontSize: 24, // Ensure the font size isn't too large
                    ),
                  ),
                ),
              ),
              contactsForLetter(context, letter, contactsInSection)
            ]));
      },
      separatorBuilder: (BuildContext context, int index) =>
          Divider(color: colorScheme.primary, thickness: 1, height: 16),
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
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () {
              editContactPopup(context, contact);
            },
            onLongPress: () {
              // Show delete confirmation on long press
              showDeleteConfirmation(context, contact);
            },
            borderRadius: BorderRadius.circular(12),
            child: contactRow(context, contact),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => SizedBox(height: 8),
    );
  }

  // Helper to convert binary to a visual pattern representation
  Widget patternVisualization(int vibPattern, ColorScheme colorScheme, {double height = 16}) {
    List<bool> bits = [];
    for (int i = 0; i < 8; i++) {
      bits.add(((vibPattern >> (7-i)) & 1) == 1);
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: bits.map((bit) => Container(
        width: 5,
        height: bit ? height : height / 2,
        margin: EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: bit ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      )).toList(),
    );
  }

  Widget contactRow(BuildContext context, Contact contact) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    
    // Format last seen to prevent overflow
    String lastSeen = contact.last_seen;
    if (lastSeen.length > 20) {
      lastSeen = lastSeen.substring(0, 18) + "...";
    }
    
    return Semantics(
      label:"${contact.name}, Vibration Pattern: ${contact.vibration}, Last Seen: ${lastSeen} ",
      hint:"Tap to edit the contact info for ${contact.name}",
      enabled: true,
      child:Container(
      padding: EdgeInsets.all(12),
      child: Semantics(
        enabled: false,
        child:Row(
        children: [
          // Avatar container
          Container(
            height: 50,
            width: 50,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.2),
            ),
            child: Center(
              child: Icon(
                Icons.person,
                size: 30,
                color: colorScheme.primary,
              ),
            ),
          ),
          // Contact info - using Expanded to prevent overflow
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis, // Prevent overflow
                  maxLines: 1,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.vibration, size: 14, color: colorScheme.primary),
                    SizedBox(width: 4),
                    patternVisualization(contact.vibration, colorScheme),
                    SizedBox(width: 4),
                    Text(
                      "(${contact.vibration})",
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: colorScheme.primary),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Last seen: $lastSeen",
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Edit icon
          IconButton(
            icon: Icon(Icons.edit, color: colorScheme.primary),
            onPressed: () {
              editContactPopup(context, contact);
            },
            constraints: BoxConstraints(minWidth: 40, minHeight: 40),
            padding: EdgeInsets.zero,
          ),
        ],
      )),
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

// Binary pattern bit toggle button
class BitToggleButton extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;
  final int bitPosition;
  final Color activeColor;
  final Color inactiveColor;
  
  const BitToggleButton({
    Key? key,
    required this.value,
    required this.onChanged,
    required this.bitPosition,
    required this.activeColor,
    required this.inactiveColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bit position label
        Semantics(
          label:"",
          child:Text(
          '$bitPosition',
          style: TextStyle(
            fontSize: 10,
            color: Colors.black,
          ),
        )),
        SizedBox(height: 4),
        // Toggle button
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            width: 28,
            height: value ? 45 : 25, // Taller when active (1), shorter when inactive (0)
            decoration: BoxDecoration(
              color: value ? activeColor : inactiveColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: value ? activeColor.withOpacity(0.8) : Colors.grey[400]!,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                value ? '1' : '0',
                style: TextStyle(
                  color: value ? Colors.white : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
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
  List<bool> _vibrationPattern = List.filled(8, false);
  int _vibrationValue = 0;
  bool isSaving = false;
  bool _usePresets = false;
  
  // Preset patterns with descriptions
  final List<Map<String, dynamic>> presets = [
    {'name': 'Single Pulse', 'value': 1, 'pattern': [0, 0, 0, 0, 0, 0, 0, 1]},
    {'name': 'Double Pulse', 'value': 3, 'pattern': [0, 0, 0, 0, 0, 0, 1, 1]},
    {'name': 'SOS (...---...)', 'value': 83, 'pattern': [0, 1, 0, 1, 0, 1, 1, 1]},
    {'name': 'Alert', 'value': 170, 'pattern': [1, 0, 1, 0, 1, 0, 1, 0]},
    {'name': 'Heartbeat', 'value': 136, 'pattern': [1, 0, 0, 0, 1, 0, 0, 0]},
    {'name': 'All Long', 'value': 255, 'pattern': [1, 1, 1, 1, 1, 1, 1, 1]},
  ];
  
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.contact.name);
    _vibrationValue = widget.contact.vibration.clamp(0, 255);
    _vibrationPattern = widget.contact.getVibrationPattern();
  }
  
  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
  
  // Update pattern from decimal value
  void _updatePatternFromValue(int value) {
    List<bool> newPattern = [];
    for (int i = 0; i < 8; i++) {
      newPattern.add(((value >> (7-i)) & 1) == 1);
    }
    setState(() {
      _vibrationPattern = newPattern;
      _vibrationValue = value;
    });
  }
  
  // Update decimal value from pattern
  void _updateValueFromPattern() {
    int value = 0;
    for (int i = 0; i < 8; i++) {
      if (_vibrationPattern[i]) {
        value |= (1 << (7-i));
      }
    }
    setState(() {
      _vibrationValue = value;
    });
  }
  
  // Test the vibration pattern
  void _testVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      // Create a vibration pattern based on the bit pattern
      // 1 = long vibration (300ms), 0 = short vibration (100ms)
      // Each pause is 100ms
      print("Vibing");
      List<int> pattern = [];
      
      // Add first vibration without initial pause
      // pattern.add(_vibrationPattern[0] ? 300 : 100);
      
      // Add remaining vibrations with pauses
      for (int i = 0; i < 8; i++) {
        // Add pause            
        Vibration.vibrate(duration:_vibrationPattern[i] ? 300 : 100);
        await Future.delayed(Duration(milliseconds: 600)); // Delay before retrying

        // Add vibration
      }
      
    }
  }
  
  Future<void> saveContact() async {
    setState(() {
      isSaving = true;
    });
    
    String name = nameController.text;
    int vibPattern = _vibrationValue;
    
    var token = await widget.authProvider.getToken();
    print("Params: ${widget.contact.cid}, $name, $vibPattern");
    
    final response = await http.patch(
      Uri.parse("http://137.184.156.253/api/v1/edit_contact/${widget.contact.cid}"),
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
  
  // Widget to show vibration pattern visualization
  Widget _buildPatternVisualization(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _vibrationPattern.map((bit) => Container(
        width: 20,
        height: bit ? 40 : 20,
        margin: EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bit ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      )).toList(),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    
    // Use MediaQuery to get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double dialogWidth = screenSize.width > 600 ? 500 : screenSize.width * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 8,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: 600, // Limit maximum height
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: 28,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit Contact',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          fontSize: 20,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Name field
                Text(
                  'Contact Name',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: 'Enter contact name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                    contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  ),
                  maxLength: 50,
                ),
                SizedBox(height: 16),
                
                // Vibration Pattern section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vibration Pattern',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    // Decimal representation
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Value: $_vibrationValue',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                // Pattern visualization
                _buildPatternVisualization(colorScheme),
                SizedBox(height: 12),
                
                // Pattern bit toggles
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(8, (index) {
                          return BitToggleButton(
                            value: _vibrationPattern[index],
                            bitPosition: index,
                            activeColor: colorScheme.primary,
                            inactiveColor: Colors.grey[200]!,
                            onChanged: (value) {
                              setState(() {
                                _vibrationPattern[index] = value;
                                _updateValueFromPattern();
                              });
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 8),
                      Center(
                        child: Text(
                          '1 = Long vibration, 0 = Short vibration',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Preset patterns
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Preset Patterns',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Switch(
                      value: _usePresets,
                      onChanged: (value) {
                        setState(() {
                          _usePresets = value;
                        });
                      },
                      activeColor: colorScheme.primary,
                    ),
                  ],
                ),
                
                // Preset patterns dropdown or grid
                if (_usePresets) ...[
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: presets.map((preset) {
                        bool isSelected = _vibrationValue == preset['value'];
                        return InkWell(
                          onTap: () {
                            _updatePatternFromValue(preset['value']);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            margin: EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? colorScheme.primary.withOpacity(0.2) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? colorScheme.primary : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        preset['name'],
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? colorScheme.primary : Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Value: ${preset['value']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                // Mini visualization
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: (preset['pattern'] as List).map<Widget>((bit) => Container(
                                    width: 6,
                                    height: bit == 1 ? 20 : 10,
                                    margin: EdgeInsets.symmetric(horizontal: 1),
                                    decoration: BoxDecoration(
                                      color: bit == 1 ? colorScheme.primary : colorScheme.primary.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                SizedBox(height: 16),
                
                // Test vibration button
                Center(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.vibration),
                    label: Text("Test Vibration"),
                    onPressed: _testVibration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: Navigator.of(context).pop,
                      child: Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isSaving ? null : saveContact,
                      child: isSaving
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
