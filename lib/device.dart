import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'themes.dart' as themer;
import 'dart:collection';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';

class DevicePage extends StatelessWidget {
  var authProvider;

  final String deviceName = "August Device";
  // Map <String, BluetoothService?> realServices = {
  //   "0000f0de-bc9a-7856-3412-004200000069": null,
  //   "0001f0de-bc9a-7856-3412-004200000069": null,
  //   "0002f0de-bc9a-7856-3412-004200000069": null

  // };
  final WIFI_SERVICE_UUID = "0001f0de-bc9a-7856-3412-004200000069";
  final WIFI_SSID_UUID = "0101f0de-bc9a-7856-3412-004200000069";
  final WIFI_USERNAME_UUID = "0201f0de-bc9a-7856-3412-004200000069";
  final WIFI_IDENTITY_UUID = "0301f0de-bc9a-7856-3412-004200000069";
  final WIFI_PASSWORD_UUID = "0401f0de-bc9a-7856-3412-004200000069";
  final WIFI_CONNECT_UUID = "0501f0de-bc9a-7856-3412-004200000069";

  final VIBRATOR_SERVICE_UUID = "0000f0de-bc9a-7856-3412-004200000069";
  final VIBRATOR_CTRL_UUID = "0100f0de-bc9a-7856-3412-004200000069";

  final API_SERVICE_UUID = "0002f0de-bc9a-7856-3412-004200000069";
  final API_TOKEN_UUID = "0102f0de-bc9a-7856-3412-004200000069";

  final ValueNotifier<bool> _isDeviceConnected = ValueNotifier<bool>(false);
  final DEVICE_NAME = "August Device";
  var realDevice;
  // 3 Services
  // Wifi Service
  // Wifi SSID      - network name? Get that somehow
  // Wifi Username
  // Wifi Identity  - same as username
  // Wifi Password
  // Wifi Connect   - write 1 to make device connect, 0 to stop
  // Vibration Service
  // Vibe value - 32 bits for vibe pattern
  // API Service
  // Access Token Characteristic
  Map<String, BluetoothService> realServices =
      new Map<String, BluetoothService>();
  Map<String, BluetoothCharacteristic> realCharacteristics =
      new Map<String, BluetoothCharacteristic>();
  DevicePage({super.key});

  Future<void> ScanForBluetoothDevices() async {
    print("Scanning For Bluetooth Devices");
    FlutterBlue fb = FlutterBlue.instance;
    fb.startScan(timeout: Duration(seconds: 30));
    // ("Damnb");

    // Listen to scan results
    var device = null;
    late var subscription;
    subscription = fb.scanResults.listen(
      (results) {
        // do something with scan results
        // print(results);
        for (ScanResult r in results) {
          if (r.device.name == deviceName) {
            _isDeviceConnected.value = true;
            print("Found $deviceName");
            realDevice = r.device;
            connectToDevice(realDevice);
            fb.stopScan();
            device.state.listen((state) {
              if (state == BluetoothDeviceState.connected) {
                print("Device connected: ${device.name}");
                // Handle connection success, perform your operations
              } else if (state == BluetoothDeviceState.disconnected) {
                print("Device disconnected: ${device.name}");
                // Handle reconnection logic here if needed
                reconnectToDevice(device);
              }
            });
            // getServices(device);
            // print("Connected to August Device");
            // subscription.cancel();
            // break;
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

    // eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJmcmVzaCI6ZmFsc2UsImlhdCI6MTc0MTYzNzAyMSwianRpIjoiZDA2YTIxZDktZjUxNy00ZTBlLWIzNWUtNzk5MWUwNzMyOTc1IiwidHlwZSI6ImFjY2VzcyIsInN1YiI6IjEiLCJuYmYiOjE3NDE2MzcwMjEsImNzcmYiOiIzMWI4NmNhYy1hZTc1LTRlNGEtOGI5MC00ZGZkMmEyNWQ1YmUiLCJleHAiOjE3NDE2NDA2MjF9.lMdMwxqcfFlWlc1opn26SELTRCIETsaWdS-qNhEXoCo
    print("Exited subscription");
    print("Stopped Scan");

    // Stop scanning
    fb.stopScan();
  }

  Future connectToDevice(BluetoothDevice device) async {
    await device.connect(timeout: Duration(seconds: 120));
    var mtu = await realDevice.mtu.first;
    print("AD MTU = $mtu");
    // await device.requestMtu(23);
    print("Connected to " + device.name);

    getServices(device);
  }

  Future reconnectToDevice(BluetoothDevice device) async {
    await Future.delayed(Duration(seconds: 3)); // Delay before retrying
    await device.connect();
  }

  Future getServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    print("Services Found");
    var targetService = null;
    for (BluetoothService service in services) {
      realServices[service.uuid.toString()] = service;
      // print("Serve me babey");
      // if (service.uuid.toString() == ARPI_SERVICE_UUID) {
      // print("Found Api Service");
      for (BluetoothCharacteristic c in service.characteristics) {
        realCharacteristics[c.uuid.toString()] = c;
        print(c.uuid.toString());
        if (c.uuid.toString() == VIBRATOR_CTRL_UUID) {
          print("Found Vibration Char");
          // await writeToCharacteristic(
          //     c, await authProvider.getToken() as String ?? "");
          // print("Finished writing");
        }
        // await readCharacteristic(c); // print(c.uuid.toString());
        // print("UUID: " + c.uuid.toString());
        // print("Wifer: " + WIFI_IDENTITY_UUID);
        // print("Window");
      }
      // } else {
      //   print("Did not find Wifi Service");
      // }
      print(realServices.length);
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
    List<int> chars = input.runes.toList();
    c.write(chars);
    // c.write(chars.sublist(0, ((chars.length - 1) / 2).round()));
    // c.write(chars.sublist(((chars.length - 1) / 2).round(), chars.length - 1));

    // await c.write(chars);
    // print("Written");
    // await readCharacteristic(c);

    return c.write(chars);
  }

  Future writeToWifi(String username, String password) {
    BluetoothService wifiService =
        realServices[WIFI_SERVICE_UUID] as BluetoothService;
    if (wifiService == null) print("NO WIFI SERVICE");
    writeToCharacteristic(
        realCharacteristics[WIFI_USERNAME_UUID] as BluetoothCharacteristic,
        username);
    writeToCharacteristic(
        realCharacteristics[WIFI_IDENTITY_UUID] as BluetoothCharacteristic,
        username);
    writeToCharacteristic(
        realCharacteristics[WIFI_PASSWORD_UUID] as BluetoothCharacteristic,
        password);
    writeToCharacteristic(
        realCharacteristics[WIFI_SSID_UUID] as BluetoothCharacteristic,
        "UCF_WPA2");
    return writeToCharacteristic(
        realCharacteristics[WIFI_CONNECT_UUID] as BluetoothCharacteristic, "1");
  }

  Future writeToVibrator(int vibe) async {
    if(!_isDeviceConnected.value){
      print("Device not connected");
      await ScanForBluetoothDevices();
      await Future.delayed(Duration(seconds:30));      // return Future<void>.value();
    }
      print("Done with allat");
        print("Vibration Service: $VIBRATOR_SERVICE_UUID");
        print("Vibration Char: $VIBRATOR_CTRL_UUID");
        print("Services length: $realServices.length");
        print("Chars length: $realCharacteristics.length");
    BluetoothService vibrationService =
        realServices[VIBRATOR_SERVICE_UUID] as BluetoothService;
      if (vibrationService == null) print("NO VIBRATION SERVICE");
      if (realCharacteristics[VIBRATOR_CTRL_UUID] == null) print("NO VIBRATION CHAR");
    return writeToCharacteristic(realCharacteristics[VIBRATOR_CTRL_UUID] as BluetoothCharacteristic, vibe.toString());
  }
  // Future readCharValue(Future<List<int>> val) async {
  //   for (var indie in val) {
  //     print(indie);
  //   }
  // }

  Widget deviceDisconnectedBox(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    return (Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 40),
        // height: 10000,
        // width: 10000,
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
                        heightFactor: 0.35,
                        widthFactor: 1,
                        child: Container(
                          // color: none,
                          child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 70),
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
            ))));
  }

  final _formKey = GlobalKey<FormState>();
  var wifiUsername = "";
  var wifiPassword = "";

  Widget deviceConnectedBox(BuildContext context) {
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    return (Container(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 40),
        // height: 10000,
        // width: 10000,
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          color: Colors.white,
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
                        heightFactor: 0.35,
                        widthFactor: 1,
                        child: Container(
                          // color: none,
                          child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 70),
                              child: Text(
                                "Device Connected!",
                                style: textTheme.titleMedium,
                              )),
                        ))),
                Form(
                  key: _formKey,
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'Wifi Username',
                            ),
                            onChanged: (value) {
                              wifiUsername = value ?? '';
                            },
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Wifi Password',
                            ),
                            onChanged: (value) {
                              wifiPassword = value ?? '';
                            },
                            validator: (String? value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter some text';
                              }
                              return null;
                            },
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: ElevatedButton(
                                onPressed: () {
                                  writeToWifi(wifiUsername, wifiPassword);
                                  // if (this.header == "Register") {
                                  //   register(username, pwd);
                                  //   print("Pushed da register button");
                                  // } else {
                                  //   login(username, pwd);
                                  //   print("Pushed da login button");
                                  // }
                                  // print("Username: $username, Password:$pwd");
                                },
                                child: const Text('Submit Wifi'),
                              ),
                              
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: ElevatedButton(
                                onPressed: () {
                                  writeToVibrator(1);
                                  print("vibing");
                                  // if (this.header == "Register") {
                                  //   register(username, pwd);
                                  //   print("Pushed da register button");
                                  // } else {
                                  //   login(username, pwd);
                                  //   print("Pushed da login button");
                                  // }
                                  // print("Username: $username, Password:$pwd");
                                },
                                child: const Text('Vibe rate'),
                              ),
                              
                            ),
                          )
                        ],
                      )),
                ),
                // Align(
                //   alignment: Alignment.bottomCenter,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       ScanForBluetoothDevices();
                //     },
                //     child: const Text('Pair a Device'),
                //   ),
                // )
              ],
            ))));
  }

  @override
  Widget build(BuildContext context) {
    authProvider = Provider.of<AuthProvider>(context);
    ThemeData themey = Theme.of(context);
    ColorScheme colorScheme = themey.colorScheme;
    TextTheme textTheme = themey.textTheme;
    return Scaffold(
        appBar: AppBar(
          title: const Text('Device Pairing'),
        ),
        body: Center(
          child: ValueListenableBuilder<bool>(
            valueListenable: _isDeviceConnected,
            builder: (context, isFirst, child) {
              return _isDeviceConnected.value
                  ? deviceConnectedBox(context)
                  : deviceDisconnectedBox(context);
            },
          ),
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
