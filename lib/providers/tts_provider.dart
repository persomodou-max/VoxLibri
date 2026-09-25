import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/tts_manager.dart';
import '../providers/player_provider.dart';

/// Provider du gestionnaire TTS partagé.
final ttsProvider = Provider<TtsManager>((ref) {
  return ref.watch(ttsManagerProvider);
});
