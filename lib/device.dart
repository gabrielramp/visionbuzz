import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'themes.dart' as themer;

class DevicePage extends StatelessWidget {
  final WIFI_SERVICE_UUID = "0001f0de-bc9a-7856-3412-004200000069";
  const DevicePage({super.key});

  void ScanForBluetoothDevices() async {
    print("Scanning For Bluetooth Devices");
    FlutterBlue fb = FlutterBlue.instance;
    fb.startScan(timeout: Duration(seconds: 10));
    // ("Damnb");

    // Listen to scan results
    var device = null;
    late var subscription;
    subscription = fb.scanResults.listen(
      (results) {
        // do something with scan results
        // print(results);
        for (ScanResult r in results) {
          if (r.device.name == "August Device") {
            print("Found August Device");
            device = r.device;
            connectToDevice(device);
            // getServices(device);
            // print("Connected to August Device");

            subscription.cancel();
            fb.stopScan();
            break;
          } else {
            print('${r.device.name} not AD');
          }
        }
      },
      onDone: () {
        print("finito");
      },
      // on
    );
    // if (device.name == "August Device") {
    //   device.connect();
    //   print("Conected to August Device");
    // } else {
    //   print("No Device Found");
    // }
    // await device.connect();
    // print("Conected to August Device");
    // List<BluetoothService> services = await device.discoverServices();

    print("Exited subscription");
    print("Stopped Scan");

    // Stop scanning
    fb.stopScan();
  }

  Future connectToDevice(BluetoothDevice device) async {
    await device.connect();
    print("Connected to " + device.name);
    getServices(device);
  }

  Future getServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    var wifiService = null;
    for (BluetoothService service in services) {
      if (service.uuid.toString() == WIFI_SERVICE_UUID) {
        wifiService = service;
        print("Found Wifi Service");
        for (BluetoothCharacteristic c in wifiService.characteristics) {
          readCharacteristic(c); // print(c.uuid.toString());
        }
      } else {
        print("Did not find Wifi Service");
      }
    }
    // print(services);
  }

  Future readCharacteristic(BluetoothCharacteristic c) {
    print("RELEVANT DATA");
    c.value.listen((value) => print(value));
    return c.read();
  }

  // Future readCharValue(Future<List<int>> val) async {
  //   for (var indie in val) {
  //     print(indie);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;

    return Scaffold(
        appBar: AppBar(
          title: const Text('Device Pairing'),
        ),
        body: Center(
          child: Container(
              margin: EdgeInsets.symmetric(horizontal: 60, vertical: 80),
              height: 10000,
              width: 10000,
              decoration: ShapeDecoration(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20))),
                color: Colors.grey,
              ),
              child: CustomPaint(
                  size: Size(400, 200.toDouble()),
                  painter: CornerBorderPainter(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                          child: FractionallySizedBox(
                              heightFactor: 0.5,
                              widthFactor: 1,
                              child: Container(
                                // color: none,
                                child: Center(
                                    child: Text(
                                  "No Device Connected",
                                  style: textTheme.titleMedium,
                                )),
                              ))),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ElevatedButton(
                          onPressed: () {
                            ScanForBluetoothDevices();
                          },
                          child: const Text('Pair a Device'),
                        ),
                      )
                    ],
                  ))),
          // child: ElevatedButton(
          //   onPressed: () {
          //     ScanForBluetoothDevices();
          //   },
          //   child: const Text('Go back!'),
          // ),
        ));
  }
}

class CornerBorderPainter extends CustomPainter {
  static final ColorScheme colorScheme =
      themer.Themes().getAppThemes()[0].colorScheme;
  static final double cornerWidth = 100;
  @override
  final Paint stroke = Paint()
    ..color = colorScheme.primary
    ..style = PaintingStyle.stroke
    ..strokeWidth = 10
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Path paintCorner(
      double cornerX, double cornerY, double width, double height) {
    Path path = Path();
    path.moveTo(cornerX, cornerY);
    path.lineTo(cornerX + width, cornerY);
    path.moveTo(cornerX, cornerY);
    path.lineTo(cornerX, cornerY + height);
    return path;
  }

  void paint(Canvas canvas, Size size) {
    List<double> widths = [(size.width * 1 / 16), (size.width * 15 / 16)];
    List<double> heights = [(size.height * 15 / 16), (size.height * 1 / 16)];
    for (int c = 0; c < 4; c++) {
      int widthMod = -2 * (c % 2) + 1;
      int heightMod = 2 * (c / 2).toInt() - 1;
      canvas.drawPath(
          paintCorner(widths[(c % 2)], heights[(c ~/ 2)],
              cornerWidth * widthMod, cornerWidth * heightMod),
          stroke);
      // print("Width: ${cornerWidth * widthMod}, Height: ${cornerWidth * heightMod}");
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
