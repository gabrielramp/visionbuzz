import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  void ScanForBluetoothDevices() {
    print("Scanning For Bluetooth Devices");
    FlutterBlue fb = FlutterBlue.instance;
    fb.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    var subscription = fb.scanResults.listen((results) {
      // do something with scan results
      // print(results);
      for (ScanResult r in results) {
        print('${r.device.name} found! rssi: ${r.rssi}');
      }
    });

    // Stop scanning
    // fb.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ScanForBluetoothDevices();
          },
          child: const Text('Go back!'),
        ),
      ),
    );
  }
}
