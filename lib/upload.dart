import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

class UploadPage extends StatelessWidget {
  UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: TimelineSection(), // No SingleChildScrollView needed
          );
        },
      ),
    );
  }
}

class TimelineSection extends StatelessWidget {
  final List<String> events = [
    "Project Start",
    "Design Phase",
    "Development",
    "Testing",
    "Deployment"
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(0),
      child: FixedTimeline.tileBuilder(
        theme: TimelineThemeData(
          nodePosition: 0.025,
          indicatorTheme: IndicatorThemeData(size: 20, color: Colors.purple),
          connectorTheme: ConnectorThemeData(thickness: 8, color: Colors.purple),
        ),
        builder: TimelineTileBuilder.connected(

          itemCount: events.length,
          connectorBuilder: (context, index, type) {
            return SolidLineConnector(color: Colors.purple);
          },
          indicatorBuilder: (context, index) {
            return DotIndicator(
              color: Colors.purple,
              child: Icon(Icons.circle, size: 10, color: Colors.white),
            );
          },
          contentsBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 16.0),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  events[index],
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
