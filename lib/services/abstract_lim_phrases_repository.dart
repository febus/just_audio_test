import 'package:just_audio_test/model/lim_part.dart';

abstract class AbstractLimPhrasesRepository {
  Future<List<LimPhrase>> loadLimPhrases(bool forceReload,
      [int start = -1, int end = -1]);
}
