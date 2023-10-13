class DrawerChapter {
  DrawerChapter(
      {required this.foreignText, required this.nativeText, required this.startPhrase, required this.endPhrase});

  factory DrawerChapter.fromJson(Map<String, dynamic> parsedJson) {
    return DrawerChapter(
        foreignText: parsedJson['foreign_text'] as String,
        nativeText: parsedJson['native_text'] as String,
        startPhrase: parsedJson['start_phrase'] as int,
        endPhrase: parsedJson['end_phrase'] as int);
  }
  String foreignText;
  String nativeText;
  int startPhrase;
  int endPhrase;
}
