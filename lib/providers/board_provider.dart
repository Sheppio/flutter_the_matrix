import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:image/image.dart' as image;

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
    NotifierProvider<BoardRepository, List<List<Color>>>(BoardRepository.new);

class BoardRepository extends Notifier<List<List<Color>>> {
  ItemsRepositoryRiverpod() {
    debugPrint('ItemsRepositoryRiverpod constrctor called.');
  }

  var cols = 32;
  var rows = 32;

  var board = [<Color>[]];

  @override
  List<List<Color>> build() {
    debugPrint('ItemsRepositoryRiverpod build() called.');
    board = List.generate(cols, (i) => List.filled(rows, Colors.grey),
        growable: false);
    return board;
  }

  _refreshState() {
    debugPrint("_refreshState() called");
    // items.forEach(((element) {
    //   print(element.toJson());
    // }));
    state = List<List<Color>>.from(board);
  }

  setCell(int colIndex, int rowIndex, Color color) async {
    _setCell(colIndex, rowIndex, color);
    _refreshState();
    var remoteCol = await _remoteSetCell(colIndex, rowIndex, color);
    if (remoteCol != color) {
      _setCell(colIndex, rowIndex, remoteCol);
      _refreshState();
    }
    ;
  }

  _setCell(int colIndex, int rowIndex, Color color) {
    board[colIndex][rowIndex] = color;
  }

  Future<Color> _remoteSetCell(int colIndex, int rowIndex, Color color) async {
    await Future.delayed(const Duration(milliseconds: 500));
    var rnd = Random();
    return rnd.nextDouble() < 0.5
        ? color
        : Colors.primaries[rnd.nextInt(Colors.primaries.length)];
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
          _setCell(c, r, Color(pic.getPixel(c, r)));
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
