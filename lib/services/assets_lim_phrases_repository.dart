import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:collection/collection.dart';
import 'package:just_audio_test/model/lim_part.dart';
import 'package:just_audio_test/services/abstract_lim_phrases_repository.dart';

class AssetsLimPhrasesRepository extends AbstractLimPhrasesRepository {
  static List<LimPhrase>? _limPhrasesCache;
  @override
  Future<List<LimPhrase>> loadLimPhrases(bool forceReload,
      [int start = -1, int end = -1]) async {
    if (_limPhrasesCache != null &&
        _limPhrasesCache!.isNotEmpty &&
        !forceReload) {
      return _limPhrasesCache!;
    }
    if (_limPhrasesCache != null) {
      _limPhrasesCache?.clear();
    }
    final String assetsFile = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap =
        json.decode(assetsFile) as Map<String, dynamic>;

    final Map<String, List<String>> limChapters = groupBy<String, String>(
        manifestMap.keys.where((String key) => key.contains('lim/')),
        (String obj) => obj.substring(0, 15));
//https://stackoverflow.com/questions/51106934/my-async-call-is-returning-before-list-is-populated-in-foreach-loop
    final List<LimPhrase> limPhrases = <LimPhrase>[];
    //const int iChapter = 0;
    //int lineNo = 0;
    for (final String folder in limChapters.keys) {
      final List<String> files = limChapters[folder]!;
      final String foreignFileName =
          files.firstWhere((String element) => element.contains('Eng.lim'));
      final List<String> foreignLines =
          await readUtf16AssetContent(foreignFileName);
      final String audioFile =
          files.firstWhere((String element) => element.contains('.mp3'));
      final String nativeFileName =
          files.firstWhere((String element) => element.contains('Rus.lim'));
      final List<String> nativeLines =
          await readUtf16AssetContent(nativeFileName);
      final String startPosFileName =
          files.firstWhere((String element) => element.contains('SPos.lim'));
      final List<String> startPositionLines =
          await readUtf8AssetContent(startPosFileName);
      final List<int> startPositions = await readPositions(startPositionLines);

      final String endPosFileName =
          files.firstWhere((String element) => element.contains('EPos.lim'));
      final List<String> endPositionLines =
          await readUtf8AssetContent(endPosFileName);
      final List<int> endPositions = await readPositions(endPositionLines);

      for (int iLine = 0; iLine < foreignLines.length; iLine++) {
        final LimPhrase phrase = LimPhrase(
            audioFileName: audioFile,
            foreignText: foreignLines[iLine],
            nativeText: nativeLines[iLine],
            //nativeText: '${lineNo++}. ${nativeLines[iLine]}',
            startOffsetInMilliseconds: startPositions[iLine],
            endOffsetInMilliseconds: endPositions[iLine]);
        limPhrases.add(phrase);
      }
    }

    return limPhrases.skipTake(start, end);
  }

  Future<List<String>> readUtf16AssetContent(String assetName,
      [int start = -1, int end = -1]) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final ByteBuffer buffer = bytes.buffer;
    final List<String> fileLines = String.fromCharCodes(buffer.asUint16List())
        .split('\n')
        .where((String element) => element != '')
        .skipTake(start, end);
    return fileLines;
  }

  Future<List<String>> readUtf8AssetContent(String assetName,
      [int start = -1, int end = -1]) async {
    final ByteData bytes = await rootBundle.load(assetName);
    final ByteBuffer buffer = bytes.buffer;
    final List<String> fileLines = String.fromCharCodes(buffer.asUint8List())
        .split('\n')
        .where((String element) => element != '')
        .skipTake(start, end);

    return fileLines;
  }

  Future<List<int>> readPositions(Iterable<String> positionLines,
      [int start = -1, int end = -1]) async {
    //final List<String> allPositions = skipTake(positionLines, start, end);

    final List<int> positions = positionLines
        .skipTake(start, end)
        .map((String e) => int.parse(e))
        .toList();
    return positions;
  }
}

extension SkipTakeIterable<T> on Iterable<T> {
  List<T> skipTake(int start, int end) {
    return skip(start > 0 ? start : 0)
        .take(end > 0 && end >= start ? min(end - start + 1, length) : length)
        .toList();
  }
}
