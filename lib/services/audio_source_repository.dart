import 'package:just_audio/just_audio.dart';
import 'package:just_audio_test/model/lim_part.dart';

class AudioSourceRepository {
  static ConcatenatingAudioSource? _audioSourceCache;

  Future<ConcatenatingAudioSource> loadAudioSource(
      bool forceReload, List<LimPhrase> limPhrases) async {
    if (_audioSourceCache != null &&
        _audioSourceCache?.children != null &&
        _audioSourceCache!.children.isNotEmpty &&
        !forceReload) {
      return _audioSourceCache!;
    }
    if (_audioSourceCache != null) {
      await _audioSourceCache!.clear();
    }
    final List<ClippingAudioSource> audioSources = limPhrases
        .map((LimPhrase limPhrase) => ClippingAudioSource(
              start:
                  Duration(milliseconds: limPhrase.startOffsetInMilliseconds),
              end: Duration(milliseconds: limPhrase.endOffsetInMilliseconds),
              child: AudioSource.uri(
                  Uri.parse('asset:///${limPhrase.audioFileName}')),
            ))
        .toList();
    _audioSourceCache = ConcatenatingAudioSource(children: audioSources);
    return _audioSourceCache!;
  }
}
