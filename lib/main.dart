// main.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_the_matrix/rainbow_gradient.dart';
import 'dart:io' as io;
import 'package:dio/dio.dart';

import 'package:image/image.dart' as image;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'The Matrix',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: MyPainter(),
    );
  }
}

// main.dart

class MyPainter extends StatefulWidget {
  @override
  State<MyPainter> createState() => _MyPainterState();
}

class _MyPainterState extends State<MyPainter> {
  var cols = 32;
  var rows = 32;
  Color screenPickerColor = Colors.red;

  late List<List<Color>> colorMatrix;
  late List<List<Color>> colors;

  @override
  void initState() {
    var prims = [Colors.black, Colors.white, ...Colors.primaries];
    colors = List.generate(prims.length, (i) => [prims[i]]);
    colorMatrix = List.generate(cols, (i) => List.filled(rows, Colors.grey),
        growable: false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                try {
                  Response<List<int>> rs;
                  rs = await Dio().get<List<int>>(
                    'https://picsum.photos/200',
                    options: Options(
                        responseType:
                            ResponseType.bytes), // set responseType to `bytes`
                  );
                  var imageFile = rs.data!;
                  var pic = image.decodeImage(imageFile);
                  pic = image.copyResize(pic!, width: cols, height: rows);
                  setState(() {
                    for (var r = 0; r < rows; r++) {
                      for (int c = 0; c < cols; c++) {
                        var color = Color(pic!.getPixel(c, r));
                        colorMatrix[c][r] = color;
                      }
                    }
                  });
                } catch (e) {
                  print(e);
                }
              },
              icon: Icon(Icons.file_download)),
        ],
        title: Center(
          child: Text(
            'The Matrix',
            style: TextStyle(color: Colors.black87),
          ),
        ),
        flexibleSpace: Container(
          height: 250.0,
          decoration: BoxDecoration(
            gradient: RainbowGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFFFF0064),
                const Color(0xFFFF7600),
                const Color(0xFFFFD500),
                //const Color(0xFF8CFE00),
                const Color(0xFF00E86C),
                // const Color(0xFF00F4F2),
                const Color(0xFF00CCFF),
                //const Color(0xFF70A2FF),
                const Color(0xFFA96CFF),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: LayoutBuilder(builder: (context, constraints) {
                //debugPrint('GS size: ${constraints.biggest}');
                return GestureDetector(
                  onLongPressStart: (details) => setState(() {
                    print('Longpress');
                    var colWidth = constraints.biggest.width / cols;
                    var rowHeight = constraints.biggest.height / rows;
                    var selectedCol =
                        (details.localPosition.dx / colWidth).floor();
                    var selectedRow =
                        (details.localPosition.dy / rowHeight).floor();
                    screenPickerColor = colorMatrix[selectedCol][selectedRow];
                  }),
                  onTapUp: (details) {
                    //debugPrint(details.localPosition.toString());
                    var colWidth = constraints.biggest.width / cols;
                    var rowHeight = constraints.biggest.height / rows;
                    var selectedCol =
                        (details.localPosition.dx / colWidth).floor();
                    var selectedRow =
                        (details.localPosition.dy / rowHeight).floor();
                    //debugPrint('$selectedCol, $selectedRow');
                    setState(() {
                      print('tapup');
                      colorMatrix[selectedCol][selectedRow] = screenPickerColor;
                    });
                  },
                  child: CustomPaint(
                    painter: ShapePainter(colorMatrix),
                    child: Container(),
                  ),
                );
              }),
            ),
            ColorPicker(
              pickersEnabled: const <ColorPickerType, bool>{
                ColorPickerType.both: false,
                ColorPickerType.primary: false,
                ColorPickerType.accent: false,
                ColorPickerType.bw: false,
                ColorPickerType.custom: false,
                ColorPickerType.wheel: true
              },
              wheelSquarePadding: 10,
              enableShadesSelection: false,
              showRecentColors: true,
              recentColors: [Colors.red, Colors.green],
              // Use the screenPickerColor as start color.
              color: screenPickerColor,
              // Update the screenPickerColor using the callback.
              onColorChangeEnd: (Color color) => setState(() {
                print('boo');
                screenPickerColor = color;
              }),
              onColorChanged: (value) {},

              width: 20,
              height: 20,
              borderRadius: 22,
              heading: Text(
                'Select color',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              subheading: Text(
                'Select color shade',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            // Expanded(
            //   flex: 1,
            //   child: Center(
            //     child: FractionallySizedBox(
            //       widthFactor: 0.8,
            //       heightFactor: 0.2,
            //       child: CustomPaint(
            //         painter: ShapePainter(colors),
            //         child: Container(),
            //       ),
            //     ),
            //   ),
            // )
          ],
        ),
      ),
    );
  }
}

// main.dart

// FOR PAINTING LINES
class ShapePainter extends CustomPainter {
  ShapePainter(this.colorMatrix);
  List<List<Color>> colorMatrix;
  var paintCache = <Color, Paint>{};

  var rnd = Random();

  var fills = Colors.primaries
      .map((e) => Paint()
        ..color = e
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill)
      .toList();

  @override
  void paint(Canvas canvas, Size size) {
    final stopwatch = Stopwatch();
    stopwatch.start();
    var cols = colorMatrix.length;
    var rows = colorMatrix[0].length;
    var segmentSize = Size(size.width / cols, size.height / rows);
    //debugPrint('Size: $size');
    var border = Paint()
      ..color = Colors.black
      ..strokeWidth = segmentSize.shortestSide * 0.03
      ..strokeCap = StrokeCap.round;
    border.style = PaintingStyle.stroke;

    var fill = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    for (var r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        drawSegment(
            Offset((c * (segmentSize.width)) + (segmentSize.width / 2),
                (r * (size.height / rows)) + (segmentSize.height / 2)),
            Size((size.width / cols) * .9, (size.height / rows) * .9),
            canvas,
            border,
            getFill(colorMatrix[c][r])
            //fills[rnd.nextInt(fills.length)]
            );
      }
    }
    stopwatch.stop();

    debugPrint('exe time: ${stopwatch.elapsedMicroseconds}');
    debugPrint('PaintCache size: ${paintCache.length}');
  }

  Paint getFill(Color color) {
    if (!paintCache.containsKey(color)) {
      paintCache[color] = Paint()
        ..color = color
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill;
    }
    return paintCache[color]!;
  }

  drawSegment(
      Offset offset, Size size, Canvas canvas, Paint border, Paint fill) {
    var radius = Radius.circular(size.shortestSide * 0.2);
    var rect = Rect.fromLTWH(offset.dx - (size.width / 2),
        offset.dy - (size.height / 2), size.width, size.height);
    if (size.shortestSide < 16.0) {
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, border);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), fill);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), border);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
