import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class Event {
  String name;
  String time;
  bool seen;
  Event({required this.name, required this.time, required this.seen});
}

Future<http.Response> makeGetCall() {
  return http.get(Uri.parse('http://159.223.99.186/api/v1/register'));
}

class HomePage extends StatelessWidget {
  HomePage({super.key});
  var numDays = Random().nextInt(3) + 5; // Get this from database
  final ScrollController _controller = ScrollController();

  void _defaultToBottom() {
    _controller.jumpTo(_controller.position.maxScrollExtent);
  }

  @override
  Widget build(BuildContext context) {
    final List<Event> events = [
      new Event(name: "Person A", time: "1 PM", seen: true),
      new Event(name: "Person B", time: "2 PM", seen: false),
      new Event(name: "Person C", time: "3 PM", seen: false),
      new Event(name: "Person D", time: "4 PM", seen: true),
      new Event(name: "Person E", time: "5 PM", seen: true),
      new Event(name: "Person F", time: "6 PM", seen: false),
      new Event(name: "Person G", time: "7 PM", seen: false),
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Timeline'),
      ),
      body: ListView.builder(
        reverse: true,
        controller: _controller,
        itemCount: numDays,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TimelineSection(
                events: events), // No SingleChildScrollView needed
          );
        },
      ),
    );
  }
}

class TimelineSection extends StatelessWidget {
  var events;
  var authProvider;

  TimelineSection({required this.events});
  @override
  Widget build(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(0),
      child: Column(children: [
        Text(
          "Date moment",
          style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary),
        ),
        FixedTimeline.tileBuilder(
          theme: TimelineThemeData(
            nodePosition: 0.025, // Away from left edge, 0-1
            indicatorTheme:
                IndicatorThemeData(size: 50, color: colorScheme.secondary),
            connectorTheme:
                ConnectorThemeData(thickness: 8, color: colorScheme.primary),
          ),
          builder: TimelineTileBuilder.connected(
            itemCount: Random().nextInt(3) + 3,
            connectorBuilder: (context, index, type) {
              return SolidLineConnector(color: colorScheme.primary);
            },
            indicatorBuilder: (context, index) {
              return DotIndicator(
                color: colorScheme.primary,
                child: Icon(Icons.circle,
                    size: 30,
                    color: events[index].seen
                        ? colorScheme.secondary
                        : colorScheme.primary),
              );
            },
            contentsBuilder: (context, index) {
              return GestureDetector(
                  onTap: () {
                    // if (authProvider.isLoggedIn) {
                    //   print("All good in the hood (We are logged in)");
                    // } else {
                    //   print("You're hosed (not logged in)");
                    // }
                    editContact(context, events[index]);
                  },
                  onDoubleTap: () {
                    authProvider.logout();

                    print("Double clicked + logged out + ratio");
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
                      height: 150,
                      child: Column(
                        children: [
                          Text(
                            events[index].name,
                            style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          Text(
                            "Time: ${events[index].time}",
                            style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
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
  } // TimelineSection Widget

  Future<void> editContact(BuildContext context, Event event) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return editContactDialog(context: context, event: event);
      },
    );
  }
} // TimelineSection Class

class editContactDialog extends StatelessWidget {
  var event;
  editContactDialog({required context, this.event});

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
                ))
              ],
            ))
      ]),
    ));
  }
}
