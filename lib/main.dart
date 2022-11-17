// main.dart

import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_the_matrix/models/cell.dart';
import 'package:flutter_the_matrix/providers/board_provider.dart';
import 'package:flutter_the_matrix/rainbow_gradient.dart';
import 'dart:io' as io;
import 'package:dio/dio.dart';

import 'package:image/image.dart' as image;

void main() => runApp(ProviderScope(child: MyApp()));

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

class MyPainter extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyPainter> createState() => _MyPainterState();
}

class _MyPainterState extends ConsumerState<MyPainter> {
  //var cols = 32;
  //var rows = 32;
  Color screenPickerColor = Colors.red;

  //late List<List<Color>> colorMatrix;
  late List<List<Color>> colors;

  @override
  void initState() {
    var prims = [Colors.black, Colors.white, ...Colors.primaries];
    colors = List.generate(prims.length, (i) => [prims[i]]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var colorMatrix = ref.watch(boardRepositoryRiverpodProvider);
    var rows = colorMatrix.length;
    var cols = colorMatrix[0].length;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: ref
                  .read(boardRepositoryRiverpodProvider.notifier)
                  .loadRandomPhoto,
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
                    var cell = colorMatrix[selectedCol][selectedRow];
                    screenPickerColor =
                        Color.fromARGB(255, cell.red, cell.green, cell.blue);
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
                    print('tapup');
                    ref.read(boardRepositoryRiverpodProvider.notifier).setCell(
                        selectedCol,
                        selectedRow,
                        Cell(
                            red: screenPickerColor.red,
                            green: screenPickerColor.green,
                            blue: screenPickerColor.blue));
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
  List<List<Cell>> colorMatrix;
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

    // var fill = Paint()
    //   ..color = Colors.red
    //   ..strokeWidth = 2
    //   ..strokeCap = StrokeCap.round
    //   ..style = PaintingStyle.fill;

    for (var r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        var cell = colorMatrix[c][r];
        var cellColor = Color.fromARGB(255, cell.red, cell.green, cell.blue);
        drawSegment(
            Offset((c * (segmentSize.width)) + (segmentSize.width / 2),
                (r * (size.height / rows)) + (segmentSize.height / 2)),
            Size((size.width / cols) * .9, (size.height / rows) * .9),
            canvas,
            border,
            getFill(cellColor)
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
