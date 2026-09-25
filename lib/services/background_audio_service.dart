import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../core/constants.dart';

/// Handler audio pour la lecture en arrière-plan via audio_service.
class VoxLibriAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  VoxLibriAudioHandler({
    required this.onPlayRequested,
    required this.onPauseRequested,
    required this.onStopRequested,
    required this.onSkipNext,
    required this.onSkipPrevious,
  });

  final Future<void> Function() onPlayRequested;
  final Future<void> Function() onPauseRequested;
  final Future<void> Function() onStopRequested;
  final Future<void> Function() onSkipNext;
  final Future<void> Function() onSkipPrevious;

  /// Met à jour l'état de lecture affiché dans la notification système.
  void syncPlaybackState({
    required String title,
    required Duration position,
    required Duration duration,
    required bool playing,
  }) {
    mediaItem.add(
      MediaItem(
        id: 'current_document',
        title: title,
        artist: AppConstants.appName,
        duration: duration,
      ),
    );
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.ready,
        playing: playing,
        updatePosition: position,
        bufferedPosition: duration,
        speed: 1.0,
      ),
    );
  }

  @override
  Future<void> play() => onPlayRequested();

  @override
  Future<void> pause() => onPauseRequested();

  @override
  Future<void> stop() async {
    await onStopRequested();
    await super.stop();
  }

  @override
  Future<void> skipToNext() => onSkipNext();

  @override
  Future<void> skipToPrevious() => onSkipPrevious();
}

/// Initialise et gère le service audio en arrière-plan.
class BackgroundAudioService {
  BackgroundAudioService._();

  static VoxLibriAudioHandler? _handler;

  static VoxLibriAudioHandler? get handler => _handler;

  static Future<VoxLibriAudioHandler> init({
    required Future<void> Function() onPlayRequested,
    required Future<void> Function() onPauseRequested,
    required Future<void> Function() onStopRequested,
    required Future<void> Function() onSkipNext,
    required Future<void> Function() onSkipPrevious,
  }) async {
    if (_handler != null) return _handler!;

    _handler = await AudioService.init(
      builder: () => VoxLibriAudioHandler(
        onPlayRequested: onPlayRequested,
        onPauseRequested: onPauseRequested,
        onStopRequested: onStopRequested,
        onSkipNext: onSkipNext,
        onSkipPrevious: onSkipPrevious,
      ),
      config: AudioServiceConfig(
        androidNotificationChannelId: AppConstants.notificationChannelId,
        androidNotificationChannelName: AppConstants.notificationChannelName,
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: false,
      ),
    );

    return _handler!;
  }

  /// Active le wakelock pour maintenir la lecture active.
  static Future<void> enableWakelock() async {
    await WakelockPlus.enable();
  }

  /// Désactive le wakelock.
  static Future<void> disableWakelock() async {
    await WakelockPlus.disable();
  }
}
