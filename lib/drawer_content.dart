import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_test/bloc/lim_bloc.dart';

import 'model/drawer_chapter.dart';

class DrawerContent {
  DrawerContent(this._limBloc);

  late List<DrawerChapter> _chapters;
  late final LimBloc _limBloc;

  Future<void> load() async {
    _chapters = <DrawerChapter>[];
    final String content =
        await rootBundle.loadString('assets/drawer_content.json');
    final List<dynamic> data = json.decode(content) as List<dynamic>;
    for (final dynamic jsonObject in data) {
      final Map<String, dynamic> map = jsonObject as Map<String, dynamic>;
      final DrawerChapter chapter = DrawerChapter.fromJson(map);
      _chapters.add(chapter);
    }
  }

  Iterable<ListTile> buildListTiles() {
    final List<ListTile> listTiles = <ListTile>[];
    _chapters.asMap().forEach((int index, DrawerChapter chapter) {
      listTiles.add(ListTile(
        title: Text(chapter.foreignText),
        subtitle: Text(chapter.nativeText),
        onTap: () {
          _limBloc.inputEventSink.add(LimChapterSelectedEvent(chapter));
        },
      ));
    });
    return listTiles;
    //  .map((DrawerChapter phrase) => ListTile(
    //       title: Text(phrase.foreignText),
    //       subtitle: Text(phrase.nativeText),
    //     ));
  }
}
