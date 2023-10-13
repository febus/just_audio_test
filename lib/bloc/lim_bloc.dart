import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_test/drawer_content.dart';
import 'package:just_audio_test/model/drawer_chapter.dart';
import 'package:just_audio_test/model/lim_part.dart';
import 'package:just_audio_test/services/abstract_lim_phrases_repository.dart';
import 'package:just_audio_test/services/assets_lim_phrases_repository.dart';
import 'package:just_audio_test/services/audio_source_repository.dart';

//==============================================================================
abstract class UIEventBase {}

class LimChapterSelectedEvent extends UIEventBase {
  LimChapterSelectedEvent(this.drawerChapter);
  DrawerChapter drawerChapter;
}

class StartPageEvent extends UIEventBase {}

//==============================================================================
abstract class AppStateBase {}

class SelectedChapterState extends AppStateBase {
  SelectedChapterState(this.drawerChapter);
  DrawerChapter drawerChapter;
}

class StartPageState extends AppStateBase {}

//==============================================================================
// Bloc class
class LimBloc {
  LimBloc() {
    _inputEventController.stream.listen(_mapEventToState);
  }
  final StreamController<UIEventBase> _inputEventController =
      StreamController<UIEventBase>();
  StreamSink<UIEventBase> get inputEventSink => _inputEventController.sink;

  final StreamController<AppStateBase> _outputStateController =
      StreamController<AppStateBase>();
  Stream<AppStateBase> get outputStateStream => _outputStateController.stream;
  StreamSink<AppStateBase> get outputStateSink => _outputStateController.sink;

  void _mapEventToState(UIEventBase event) {
    if (event is LimChapterSelectedEvent) {
      final LimChapterSelectedEvent chapterSelectedEvent = event;
      outputStateSink
          .add(SelectedChapterState(chapterSelectedEvent.drawerChapter));
    } else if (event is StartPageEvent) {
      outputStateSink.add(StartPageState());
    } else {
      throw Exception('wrong event type');
    }
  }

  void dispose() {
    _inputEventController.close();
    _outputStateController.close();
    _player?.dispose();
  }

  void initState() {
    _drawerContent = DrawerContent(this);
    // Future.delayed(Duration.zero, () async {
    //   wavPaths = await enlistFiles('.wav');
    // });
    //_init();
    initPlayer();
  }

  Future<void> initPlayer() async {
    _player = AudioPlayer();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
    ));
    //_limPhrases = await enlistLimPhrases();
    final AudioSession session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    _player?.playbackEventStream.listen((PlaybackEvent event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });

    _player?.currentIndexStream.listen((int? index) async {
      if (index != null && index >= 0 &&
          index < _visibilityMap.length &&
          _visibilityMap[index]! < 1.0) {
        await ensureCurrentVisible(_chapterGlobalKeys[index].currentContext!);
      }
      // if (index % 9 != 0) {
      //   return;
      // }
      // await ensureCurrentVisible(_chapterGlobalKeys[index].currentContext);
    });
  }

  Future<void> ensureCurrentVisible(BuildContext currentContext) async {
    if (currentContext != null) {
      await _scrollController.position.ensureVisible(
        currentContext.findRenderObject()!,
        alignment: 0.02,
        duration: const Duration(milliseconds: 100),
      );
    }
  }

  Future<void> loadDrawerContent() async {
    await _drawerContent?.load();
  }

  Future<ConcatenatingAudioSource> loadAudioSource(bool forceReload,
      [int start = -1, int end = -1]) async {
    await loadDrawerContent();
    _limPhrases =
        await _limPhrasesRepository.loadLimPhrases(forceReload, start, end);

    _globalKeys.clear();
    for (int i = 0; i < _limPhrases.length; i++) {
      _globalKeys.add(GlobalKey());
    }

    for (int i = 0; i < _limPhrases.length; i++) {
      _visibilityMap[i] = 0;
    }
    return await _audioSourceRepository.loadAudioSource(
        forceReload, _limPhrases);
  }

  Iterable<ListTile> buildListTiles() {
    return _drawerContent!.buildListTiles()!;
  }

  void processSelectedChapterState(
      SelectedChapterState state, ConcatenatingAudioSource cas) {
    try {
      final ConcatenatingAudioSource audioSource = cas;
      final List<AudioSource> chapterAudioSources = audioSource.children
          .skipTake(
              state.drawerChapter.startPhrase, state.drawerChapter.endPhrase);
      _chapterPhrases = _limPhrases.skipTake(
          state.drawerChapter.startPhrase, state.drawerChapter.endPhrase);
      _chapterGlobalKeys = _globalKeys.skipTake(
          state.drawerChapter.startPhrase, state.drawerChapter.endPhrase);
      final ConcatenatingAudioSource chapterAudioSrc =
          ConcatenatingAudioSource(children: chapterAudioSources);

      if (_player!.playing) {
        _player?.pause().then((_) => _player
            !.setAudioSource(chapterAudioSrc)
            .then((_) => _player!.seek(Duration.zero, index: 0).then((_) =>
                ensureCurrentVisible(_chapterGlobalKeys[0].currentContext!)
                    .then((_) => _player!.play()))));
      } else {
        _player!.setAudioSource(chapterAudioSrc).then(
            (_) => ensureCurrentVisible(_chapterGlobalKeys[0].currentContext!));
      }
    } catch (e) {
      // Catch load errors: 404, invalid url ...
      print("Error loading playlist: $e");
    }
  }

  void setVisibilityFraction(int index, double fraction) {
    if (index >= 0 && index < _visibilityMap.length) {
      _visibilityMap[index] = fraction;
    }
  }

  List<LimPhrase> get limPhrases => _limPhrases;
  List<LimPhrase> get chapterPhrases => _chapterPhrases;
  List<GlobalKey> get globalKeys => _globalKeys;
  List<GlobalKey> get chapterGlobalKeys => _chapterGlobalKeys;
  AudioPlayer? get player => _player;
  ScrollController get scrollController => _scrollController;

  AudioPlayer? _player;
  final AbstractLimPhrasesRepository _limPhrasesRepository =
      AssetsLimPhrasesRepository();

  List<LimPhrase> _limPhrases = <LimPhrase>[];

  final AudioSourceRepository _audioSourceRepository = AudioSourceRepository();

  DrawerContent? _drawerContent;

  final List<GlobalKey> _globalKeys = <GlobalKey>[];
  List<GlobalKey> _chapterGlobalKeys = <GlobalKey>[];
  List<LimPhrase> _chapterPhrases = <LimPhrase>[];
  final ScrollController _scrollController = ScrollController();

  final Map<int, double> _visibilityMap = <int, double>{};
}
