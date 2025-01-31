import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'themes.dart' as themer;

class DevicePage extends StatelessWidget {
  final VIBRATOR_SERVICE_UUID = "0000f0de-bc9a-7856-3412-004200000069";
  final VIBRATOR_CTRL_UUID = "0010f0de-bc9a-7856-3412-004200000069";
  final WIFI_SERVICE_UUID = "0001f0de-bc9a-7856-3412-004200000069";
  final WIFI_SSID_UUID = "0101f0de-bc9a-7856-3412-004200000069";
  final WIFI_USERNAME_UUID = "0201f0de-bc9a-7856-3412-004200000069";
  final WIFI_IDENTITY_UUID = "0301f0de-bc9a-7856-3412-004200000069";
  final WIFI_PASSWORD_UUID = "0401f0de-bc9a-7856-3412-004200000069";
  final WIFI_CONNECT_UUID = "0501f0de-bc9a-7856-3412-004200000069";

  final DEVICE_NAME = "August Device";
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
    print("Services Found");
    var wifiService = null;
    for (BluetoothService service in services) {
      if (service.uuid.toString() == WIFI_SERVICE_UUID) {
        wifiService = service;
        print("Found Wifi Service");
        for (BluetoothCharacteristic c in wifiService.characteristics) {
          if (c.uuid.toString() == WIFI_USERNAME_UUID) {
            print("Found Wifi Username Char");
            await writeToCharacteristic(c, "we ballin");
            print("Finished writing");
          }

          await readCharacteristic(c); // print(c.uuid.toString());
          // print("UUID: " + c.uuid.toString());
          // print("Wifer: " + WIFI_IDENTITY_UUID);
          // print("Window");
        }
      } else {
        print("Did not find Wifi Service");
      }
    }
    // print(services);
  }

  Future readCharacteristic(BluetoothCharacteristic c) async {
    print("RELEVANT DATA");
    c.value.listen((value) {
      String total = "";
      for (int valley in value) {
        total += String.fromCharCode(valley);
        // print(String.fromCharCode(valley))
      }
      print("Characteristic UUID = " + c.uuid.toString());
      print("Characteristic value = " + total);
    });
    return c.read();
  }

  Future writeToCharacteristic(BluetoothCharacteristic c, String input) async {
    print("Writing " + input + " to " + c.uuid.toString());
    var chars = input.runes.toList();
    // await c.write(chars);
    // print("Written");
    // await readCharacteristic(c);
    return c.write(chars);
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
  static final double cornerWidth = 50;
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
