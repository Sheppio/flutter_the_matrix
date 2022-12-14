import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image/image.dart' as image;
import '../models/cell.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

//part 'items_repository_riverpod.g.dart';

// @riverpod
// ItemsRepositoryRiverpod itemsRepositoryRiverpod(
//     ItemsRepositoryRiverpodRef ref) {
//   debugPrint('boohoo arse');
//   return ItemsRepositoryRiverpod(
//     sharedPreferences:
//         ref.read(sharedPreferencesProvider), // a constant defined elsewhere
//   );
// }

final boardRepositoryRiverpodProvider =
    NotifierProvider<BoardRepository, List<List<Cell>>>(BoardRepository.new);

class BoardRepository extends Notifier<List<List<Cell>>> {
  ItemsRepositoryRiverpod() {
    debugPrint('ItemsRepositoryRiverpod constrctor called.');
  }

  var cols = 16;
  var rows = 16;

  var board = [<Cell>[]];

  late WebSocketChannel? wsChannel;

  @override
  List<List<Cell>> build() {
    print('BoardRepository build() called.');
    //primaryColors = generatePrimaryColors();
    board = List.generate(
        cols, (i) => List.filled(rows, Cell(red: 224, green: 224, blue: 224)),
        growable: false);

    wsChannel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.73:8080/ws'),
    );
    wsChannel!.stream.listen((message) {
      print(message.toString());
      var tokens = message.toString().split('#');
      if (tokens.isNotEmpty) {
        var command = tokens[0];
        print(tokens);
        switch (command) {
          case 'UPDATECELL':
            print(command);
            var col = int.parse(tokens[1]);
            var row = int.parse(tokens[2]);
            var cell = Cell.fromJson(jsonDecode(tokens[3]));
            setCell(col, row, cell, shouldReportToServer: false);
            break;
          default:
            print('Command $command not yet implemented');
        }
      }
    });

    return board;
  }

  _refreshState() {
    debugPrint("_refreshState() called");
    // items.forEach(((element) {
    //   print(element.toJson());
    // }));
    state = List<List<Cell>>.from(board);
  }

  String getBoardJson() {
    return jsonEncode(board);
  }

  List<List<Cell>> getBoardFromJson(String json) {
    var x = jsonDecode(json);
    var nb = [<Cell>[]];
    for (int c = 0; c < x.length; c++) {
      nb.add(<Cell>[]);
      for (int r = 0; r < x[c].length; r++) {
        nb[c].add(Cell.fromJson(x[c][r]));
      }
    }
    return board;
  }

  setCell(int colIndex, int rowIndex, Cell cell,
      {shouldReportToServer = true}) async {
    _setCell(colIndex, rowIndex, cell);
    _refreshState();
    if (shouldReportToServer && wsChannel != null) {
      wsChannel!.sink
          .add("SETCELL#$colIndex#$rowIndex#${jsonEncode(cell.toJson())}");
    }
    // var remoteCell = await _remoteSetCell(colIndex, rowIndex, cell);
    // if (remoteCell != cell) {
    //   _setCell(colIndex, rowIndex, remoteCell);
    //   _refreshState();
    // }
  }

  _setCell(int colIndex, int rowIndex, Cell cell) {
    board[colIndex][rowIndex] = cell;
  }

  Future<Cell> _remoteSetCell(int colIndex, int rowIndex, Cell cell) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var rnd = Random();
    return rnd.nextDouble() < 0.5
        ? cell
        : Cell(
            red: rnd.nextInt(255),
            green: rnd.nextInt(255),
            blue: rnd.nextInt(255));
  }

  loadRandomPhoto() async {
    try {
      Response<List<int>> rs;
      rs = await Dio().get<List<int>>(
        'https://picsum.photos/200',
        options: Options(
            responseType: ResponseType.bytes), // set responseType to `bytes`
      );
      var imageFile = rs.data!;
      var pic = image.decodeImage(imageFile);
      pic = image.copyResize(pic!, width: cols, height: rows);
      for (var r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          var color = Color(pic.getPixel(c, r));
          _setCell(
              c, r, Cell(red: color.red, green: color.green, blue: color.blue));
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
