class LimPhrase {
  String audioFileName;
  String nativeText;
  String foreignText;
  int startOffsetInMilliseconds;
  int endOffsetInMilliseconds;

  // ignore: sort_constructors_first
  LimPhrase(
      {required this.audioFileName,
      required this.nativeText,
      required this.foreignText,
      required this.startOffsetInMilliseconds,
      required this.endOffsetInMilliseconds});
}
