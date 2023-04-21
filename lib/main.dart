import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'bloc/lim_bloc.dart';
import 'model/lim_part.dart';

//import 'package:rxdart/rxdart.dart';
//import 'dart:math';

/*
https://flutter.dev/docs/cookbook/design/drawer
https://pub.dev/packages/assets_audio_player
https://pub.dev/packages/just_audio
https://pub.dev/packages/audioplayers
https://api.dart.dev/stable/2.12.2/dart-convert/dart-convert-library.html
https://stackoverflow.com/questions/51901002/is-there-a-way-to-load-async-data-on-initstate-method
https://stackoverflow.com/questions/49457717/flutter-get-context-in-initstate-method
https://github.com/flutter/flutter/issues/66179 --> displaying text

https://stackoverflow.com/questions/50437687/flutter-initialising-variables-on-startup
https://www.codevscolor.com/dart-iterate-map
https://stackoverflow.com/questions/51415556/flutter-listview-item-click-listener
*/

Future<void> main() async {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  List<LimPhrase> limPhrases;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'С шуткой о серьезном',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'С шуткой о серьезном'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final LimBloc _limBloc = LimBloc();

  final Icon _playIcon = const Icon(Icons.play_circle_outline);
  final Icon _pauseIcon = const Icon(Icons.pause_circle_outline);

  AudioPlayer get _player => _limBloc.player;
  //List<LimPhrase> get _chapterPhrases => _limBloc.chapterPhrases;
  //List<GlobalKey> get _chapterGlobalKeys => _limBloc.globalKeys;

  @override
  void initState() {
    super.initState();
    _limBloc.initState();
    //  await _player.setSpeed(0.65);
  }

  Future<void> loadDrawerContent() async {
    await _limBloc.loadDrawerContent();
  }

  @override
  void dispose() {
    _limBloc.dispose();
    super.dispose();
  }

//https://stackoverflow.com/questions/50437687/flutter-initialising-variables-on-startup
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConcatenatingAudioSource>(
        future: loadAudioSource(false),
        builder: (BuildContext context,
            AsyncSnapshot<ConcatenatingAudioSource> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // This method is rerun every time setState is called, for instance as done
            // by the _incrementCounter method above.
            //
            // The Flutter framework has been optimized to make rerunning build methods
            // fast, so that you can just rebuild anything that needs updating rather
            // than having to individually change instances of widgets.
            return StreamBuilder<AppStateBase>(
                stream: _limBloc.outputStateStream,
                initialData: StartPageState(),
                builder: (BuildContext context,
                    AsyncSnapshot<AppStateBase> blocSnapshot) {
                  if (blocSnapshot.data is SelectedChapterState) {
                    _limBloc.processSelectedChapterState(
                        blocSnapshot.data as SelectedChapterState,
                        snapshot.data);
                  }
                  return SafeArea(
                    child: Scaffold(
                      drawer: Drawer(
                        child: ListView(
                          // Important: Remove any padding from the ListView.
                          padding: EdgeInsets.zero,
                          children: <Widget>[
                            const DrawerHeader(
                              padding: EdgeInsets.zero,
                              //child: const Text('Drawer Header'),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                image: DecorationImage(
                                    image:
                                        AssetImage('assets/images/title.png'),
                                    fit: BoxFit.fill),
                              ),
                              // decoration: const BoxDecoration(
                              //   color: Colors.blue,
                              // ),
                            ),
                            ..._limBloc.buildListTiles(),
                          ],
                        ),
                      ),
                      appBar: AppBar(
                        // Here we take the value from the MyHomePage object that was created by
                        // the App.build method, and use it to set our appbar title.
                        title: Text(widget.title),
                        actions: <Widget>[
                          StreamBuilder<bool>(
                              stream: _player.playingStream,
                              builder: (BuildContext strmContext,
                                  AsyncSnapshot<bool> snapshot) {
                                final bool playing = snapshot.data ?? false;
                                return IconButton(
                                  icon: playing ? _pauseIcon : _playIcon,
                                  onPressed: () async {
                                    if (!_player.playing) {
                                      //await _player.seek(Duration.zero, index: 0);
                                      await _player.play();
                                    } else {
                                      await _player.pause();
                                    }
                                  },
                                );
                              }),
                        ],
                      ),
                      body: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        color: const Color.fromARGB(
                            50, 112, 66, 20), //Colors.green[100],
                        child: ListView.builder(
                            itemCount: _limBloc.chapterPhrases.length,
                            controller: _limBloc.scrollController,
                            itemBuilder: (BuildContext context, int index) {
                              final LimPhrase phrase =
                                  _limBloc.chapterPhrases[index];
                              return StreamBuilder<int>(
                                  stream: _player.currentIndexStream,
                                  builder: (BuildContext strmContext,
                                      AsyncSnapshot<int> snapshot) {
                                    final int currentlyPlayingIndex =
                                        snapshot.data;

                                    return buildInkWell(
                                        index, phrase, currentlyPlayingIndex);
                                  });
                            }),
                      ),

                      // floatingActionButton: FloatingActionButton(
                      //   onPressed: _incrementCounter,
                      //   tooltip: 'Increment',
                      //   child: Icon(Icons.add),
                      // ), // This trailing comma makes auto-formatting nicer for build methods.
                    ),
                  );
                });
          } else {
            return const Scaffold(body: Center(child: Text('Loading...')));
          }
        });
  }

  void onVisibilityChanged(VisibilityInfo vi) {
    final ValueKey<String> vkey = vi.key as ValueKey<String>;
    final int index = int.tryParse(vkey.value.substring(1));
    _limBloc.setVisibilityFraction(index, vi.visibleFraction);
  }

  Widget buildInkWell(int index, LimPhrase phrase, int currentlyPlayingIndex) {
    return VisibilityDetector(
      key: Key('K$index'),
      onVisibilityChanged: onVisibilityChanged,
      child: InkWell(
        key: _limBloc.chapterGlobalKeys[index],
        onTap: () async {
          await _player.pause();
          await _player.seek(Duration.zero, index: index);
          await _player.play();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Text(phrase.foreignText,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: index == currentlyPlayingIndex
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(phrase.nativeText,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: index == currentlyPlayingIndex
                          ? FontWeight.bold
                          : FontWeight.normal)),
            ),
            const SizedBox(
              height: 10.0,
            )
          ],
        ),
      ),
    );
  }
  // InkWell buildInkWell(int index, LimPhrase phrase, int currentlyPlayingIndex) {
  //   return InkWell(
  //     key: _limBloc.chapterGlobalKeys[index],
  //     onTap: () async {
  //       await _player.pause();
  //       await _player.seek(Duration.zero, index: index);
  //       await _player.play();
  //     },
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.center,
  //       children: [
  //         Directionality(
  //           textDirection: TextDirection.rtl,
  //           child: Text(phrase.foreignText,
  //               style: TextStyle(
  //                   fontSize: 20,
  //                   fontWeight: index == currentlyPlayingIndex
  //                       ? FontWeight.bold
  //                       : FontWeight.normal)),
  //         ),
  //         Directionality(
  //           textDirection: TextDirection.ltr,
  //           child: Text(phrase.nativeText,
  //               style: TextStyle(
  //                   fontSize: 15,
  //                   fontWeight: index == currentlyPlayingIndex
  //                       ? FontWeight.bold
  //                       : FontWeight.normal)),
  //         ),
  //         const SizedBox(
  //           height: 10.0,
  //         )
  //       ],
  //     ),
  //   );
  // }

  Future<ConcatenatingAudioSource> loadAudioSource(bool forceReload,
      [int start = -1, int end = -1]) async {
    return await _limBloc.loadAudioSource(forceReload, start, end);
  }
}
