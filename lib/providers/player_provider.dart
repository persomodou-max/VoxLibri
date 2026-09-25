import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tts_manager.dart';
import '../features/reader/notifiers/player_notifier.dart';

final ttsManagerProvider = Provider<TtsManager>((ref) {
  final tts = TtsManager();
  ref.onDispose(tts.dispose);
  return tts;
});

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  final tts = ref.watch(ttsManagerProvider);
  return PlayerNotifier(ref, tts);
});
