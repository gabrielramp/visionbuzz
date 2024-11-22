import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'themes.dart' as themer;

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  void ScanForBluetoothDevices() {
    print("Scanning For Bluetooth Devices");
    FlutterBlue fb = FlutterBlue.instance;
    fb.startScan(timeout: Duration(seconds: 4));
    // ("Damnb");

    // Listen to scan results
    // var subscription = fb.scanResults.listen((results) {
    //   // do something with scan results
    //   // print(results);
    //   for (ScanResult r in results) {
    //     print('${r.device.name} found! rssi: ${r.rssi}');
    //   }
    // });

    // Stop scanning
    // fb.stopScan();
  }

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
