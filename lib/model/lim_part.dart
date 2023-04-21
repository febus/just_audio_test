class LimPhrase {
  String audioFileName;
  String nativeText;
  String foreignText;
  int startOffsetInMilliseconds;
  int endOffsetInMilliseconds;

  // ignore: sort_constructors_first
  LimPhrase(
      {this.audioFileName,
      this.nativeText,
      this.foreignText,
      this.startOffsetInMilliseconds,
      this.endOffsetInMilliseconds});
}
