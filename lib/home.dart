// Builtin Dart Stuff
import 'dart:math';
import 'dart:convert';

// Resource Packages
import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:http/http.dart' as http;
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Our onboard stuff
import 'auth_provider.dart';

class Contact {
  final int cid;
  final String name;
  Contact({required this.cid, required this.name});

  @override
  String toString() {
    return "name: $name, cid: $cid";
  }
}

class TimelineEntry {
  final String clusterId;
  final List<String> timesSeen;
  String name;
  
  TimelineEntry({required this.clusterId, required this.timesSeen, this.name = "Unknown Person"});
  
  // Get the most recent time this person was seen
  DateTime getLatestTime() {
    if (timesSeen.isEmpty) return DateTime.now();
    
    List<DateTime> dates = [];
    for (String timestamp in timesSeen) {
      try {
        // Try to parse the timestamp in multiple formats
        dates.add(parseTimestamp(timestamp));
      } catch (e) {
        print("Error parsing timestamp: $timestamp - $e");
      }
    }
    
    if (dates.isEmpty) return DateTime.now();
    
    dates.sort((a, b) => b.compareTo(a)); // Sort descending
    return dates.first;
  }
  
  // Format time for display
  String getFormattedTime() {
    DateTime latest = getLatestTime();
    return DateFormat('h:mm a').format(latest);
  }
  
  // Get the date string for grouping
  String getDateString() {
    DateTime latest = getLatestTime();
    return DateFormat('yyyy-MM-dd').format(latest);
  }
  
  // Helper method to parse timestamps in different formats including RFC 822/RFC 1123
  DateTime parseTimestamp(String timestamp) {
    // Try different parsing approaches
    try {
      // Standard ISO format
      return DateTime.parse(timestamp);
    } catch (_) {
      try {
        // Try Unix timestamp (milliseconds)
        return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (_) {
        try {
          // Try Unix timestamp (seconds)
          return DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp) * 1000);
        } catch (_) {
          try {
            // Try RFC 822/RFC 1123 format: "Tue, 11 Mar 2025 00:21:53 GMT"
            return DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'").parse(timestamp);
          } catch (_) {
            try {
              // Try custom format: "YYYY-MM-DD HH:MM:SS"
              return DateFormat("yyyy-MM-dd HH:mm:ss").parse(timestamp);
            } catch (e) {
              print("Failed to parse timestamp: $timestamp");
              throw FormatException("Invalid date format: $timestamp");
            }
          }
        }
      }
    }
  }
}

class DayTimeline {
  final String date;
  final List<TimelineEntry> entries;
  
  DayTimeline({required this.date, required this.entries});
  
  // Get a formatted date string for display
  String getFormattedDate() {
    try {
      DateTime dateTime = DateTime.parse(date);
      return DateFormat('EEEE, MMMM d').format(dateTime);
    } catch (e) {
      // Fallback if date can't be parsed
      return date;
    }
  }
}

class HomePage extends StatefulWidget {
  HomePage({super.key});
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AuthProvider authProvider;
  bool isLoading = true;
  String errorMessage = '';
  List<DayTimeline> dayTimelines = [];
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadTimeline();
    });
  }

  void _scrollToBottom() {
    if (_controller.hasClients) {
      _controller.animateTo(
        _controller.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> loadTimeline() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      await getTimeline();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading timeline: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading timeline: $e';
      });
    }
  }

  Future<void> getTimeline() async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    var token = await authProvider.getToken();
    
    if (token == null) {
      print("Not logged in, can't fetch timeline");
      setState(() {
        errorMessage = 'Not logged in. Please log in to view your timeline.';
      });
      return;
    }
    
    print("Using token: $token");
    
    try {
      final response = await http.get(
        Uri.parse('http://159.223.99.186/api/v1/pull_timeline'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': "Bearer $token",
        },
      );
      
      if (response.statusCode == 200) {
        print("API Response: ${response.body}");
        Map<String, dynamic> body = jsonDecode(response.body);
        print("Timeline pulled successfully");
        
        // Process timeline data
        Map<String, List<TimelineEntry>> entriesByDate = {};
        
        body.forEach((clusterId, timestamps) {
          // Handle timestamps correctly - they might be a List<dynamic>
          List<String> timesList = [];
          if (timestamps is List) {
            timesList = timestamps.map((t) => t.toString()).toList();
          } else if (timestamps is String) {
            // If it's a single string, put it in a list
            timesList = [timestamps];
          }
          
          // Skip if no valid timestamps
          if (timesList.isEmpty) return;
          
          TimelineEntry entry = TimelineEntry(
            clusterId: clusterId,
            timesSeen: timesList,
            name: "Person $clusterId", // Default name with cluster ID
          );
          
          try {
            // Group by date
            String dateKey = entry.getDateString();
            
            if (!entriesByDate.containsKey(dateKey)) {
              entriesByDate[dateKey] = [];
            }
            
            entriesByDate[dateKey]!.add(entry);
          } catch (e) {
            print("Error processing entry: $e");
          }
        });
        
        // Convert to DayTimeline objects
        List<DayTimeline> timelines = [];
        entriesByDate.forEach((date, entries) {
          // Sort entries by latest time
          entries.sort((a, b) => 
            b.getLatestTime().compareTo(a.getLatestTime()));
          
          timelines.add(DayTimeline(
            date: date,
            entries: entries,
          ));
        });
        
        // Sort days by most recent first
        timelines.sort((a, b) => b.date.compareTo(a.date));
        
        setState(() {
          dayTimelines = timelines;
        });
        
      } else if (response.statusCode == 401) {
        print("Authentication error");
        String errorBody = response.body;
        try {
          var errorJson = jsonDecode(response.body);
          errorBody = errorJson.toString();
        } catch (_) {}
        
        setState(() {
          errorMessage = "Authentication error: $errorBody";
        });
      } else {
        print("Something unforeseen went wrong");
        print("Error Code: ${response.statusCode}");
        print(response.body);
        
        setState(() {
          errorMessage = "Error ${response.statusCode}: ${response.body}";
        });
      }
    } catch (e) {
      print("Exception during API call: $e");
      setState(() {
        errorMessage = "Error connecting to server: $e";
      });
    }
  }

  Future<void> createContact(String clusterId, String name) async {
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    var token = await authProvider.getToken();
    
    if (token == null) {
      print("Not logged in, can't create contact");
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('http://159.223.99.186/api/v1/create_contact'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': "Bearer $token",
        },
        body: jsonEncode({
          'cluster_id': clusterId, 
          'contact_name': name
        }),
      );
      
      if (response.statusCode == 200) {
        print("Contact created successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contact "$name" created successfully!'))
        );
        // Refresh the timeline after creating a contact
        await loadTimeline();
      } else if (response.statusCode == 401) {
        print("Authentication error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error. Please log in again.'))
        );
      } else {
        print("Failed to create contact");
        print("Error Code: ${response.statusCode}");
        print(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create contact: ${response.body}'))
        );
      }
    } catch (e) {
      print("Exception creating contact: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating contact: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Timeline'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: loadTimeline,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: loadTimeline,
                          child: Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : dayTimelines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timeline_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No timeline data available',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: loadTimeline,
                            child: Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _controller,
                      itemCount: dayTimelines.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: TimelineSection(
                            dayTimeline: dayTimelines[index],
                            onNameContact: (clusterId, name) => 
                              createContact(clusterId, name),
                          ),
                        );
                      },
                    ),
    );
  }
}

class TimelineSection extends StatelessWidget {
  final DayTimeline dayTimeline;
  final Function(String, String) onNameContact;

  TimelineSection({
    required this.dayTimeline,
    required this.onNameContact,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(children: [
        Text(
          dayTimeline.getFormattedDate(),
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary),
        ),
        FixedTimeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0.025, // Away from left edge, 0-1
            indicatorTheme:
                IndicatorThemeData(size: 30, color: colorScheme.secondary),
            connectorTheme:
                ConnectorThemeData(thickness: 5, color: colorScheme.primary),
          ),
          builder: TimelineTileBuilder.connected(
            itemCount: dayTimeline.entries.length,
            connectorBuilder: (context, index, type) {
              return SolidLineConnector(color: colorScheme.primary);
            },
            indicatorBuilder: (context, index) {
              return DotIndicator(
                color: colorScheme.primary,
                child: Icon(Icons.person,
                    size: 20,
                    color: colorScheme.secondary),
              );
            },
            contentsBuilder: (context, index) {
              TimelineEntry entry = dayTimeline.entries[index];
              return GestureDetector(
                  onTap: () {
                    editContactDialog(context, entry);
                  },
                  behavior: HitTestBehavior.translucent,
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 16.0, right: 16, bottom: 16.0),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.name,
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Last seen: ${entry.getFormattedTime()}",
                            style: TextStyle(
                                fontSize: 18,
                                color: colorScheme.secondary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Times seen today: ${entry.timesSeen.length}",
                            style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.secondary),
                          ),
                        ],
                      ),
                    ),
                  ));
            },
          ),
        ),
      ]),
    );
  }

  Future<void> editContactDialog(BuildContext context, TimelineEntry entry) async {
    String newName = entry.name;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Name This Person'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: entry.name),
                        decoration: InputDecoration(
                          labelText: 'Person Name',
                          hintText: 'Enter a name for this person',
                        ),
                        onChanged: (value) {
                          newName = value;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Cluster ID: ${entry.clusterId}',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  'Times seen: ${entry.timesSeen.length}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Save'),
              onPressed: () {
                // Save the contact name
                entry.name = newName;
                onNameContact(entry.clusterId, newName);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}