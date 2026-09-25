import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/exceptions.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models/document.dart';
import '../../../domain/models/segment.dart';
import '../../../domain/services/text_segmenter.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/background_audio_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/tts_manager.dart';

/// État de lecture d'un document.
enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  stopped,
}

class PlayerState {
  final PlaybackStatus status;
  final Document? document;
  final List<ReadingParagraph> paragraphs;
  final int currentParagraphIndex;
  final int currentSegmentIndex;
  final double speed;
  final int elapsedMs;
  final int totalDurationMs;
  final String? errorMessage;

  const PlayerState({
    this.status = PlaybackStatus.idle,
    this.document,
    this.paragraphs = const [],
    this.currentParagraphIndex = 0,
    this.currentSegmentIndex = 0,
    this.speed = AppConstants.defaultSpeed,
    this.elapsedMs = 0,
    this.totalDurationMs = 0,
    this.errorMessage,
  });

  int get totalSegments =>
      paragraphs.fold(0, (sum, p) => sum + p.segments.length);

  double get progress =>
      TextUtils.calculateProgress(currentSegmentIndex, totalSegments);

  int get remainingMs =>
      (totalDurationMs - elapsedMs).clamp(0, totalDurationMs);

  String get currentParagraphText {
    if (paragraphs.isEmpty ||
        currentParagraphIndex < 0 ||
        currentParagraphIndex >= paragraphs.length) {
      return '';
    }
    return paragraphs[currentParagraphIndex].displayText;
  }

  PlayerState copyWith({
    PlaybackStatus? status,
    Document? document,
    List<ReadingParagraph>? paragraphs,
    int? currentParagraphIndex,
    int? currentSegmentIndex,
    double? speed,
    int? elapsedMs,
    int? totalDurationMs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      status: status ?? this.status,
      document: document ?? this.document,
      paragraphs: paragraphs ?? this.paragraphs,
      currentParagraphIndex:
          currentParagraphIndex ?? this.currentParagraphIndex,
      currentSegmentIndex: currentSegmentIndex ?? this.currentSegmentIndex,
      speed: speed ?? this.speed,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Notifier principal du lecteur audio.
class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier(this._ref, this._tts) : super(const PlayerState());

  final Ref _ref;
  final TtsManager _tts;
  Timer? _saveTimer;
  bool _playbackCancelled = false;

  Future<void> loadDocument(Document document, {double? speed}) async {
    state = state.copyWith(status: PlaybackStatus.loading, clearError: true);

    try {
      final textPath = document.textPath;
      if (textPath == null || !await File(textPath).exists()) {
        throw TtsException('Le texte extrait du document est introuvable');
      }

      final text = await File(textPath).readAsString();
      final paragraphs = TextSegmenter.segmentIntoParagraphs(text);
      final totalSegments = TextSegmenter.flattenSegments(paragraphs).length;
      final totalDuration = document.durationMs > 0
          ? document.durationMs
          : TextUtils.estimateReadingDurationMs(text);

      final settings = await _ref.read(settingsRepositoryProvider).loadSettings();
      final playbackSpeed = speed ?? settings.defaultSpeed;

      final safePosition = document.lastPosition.clamp(0, totalSegments);
      final paragraphIndex = TextSegmenter.paragraphIndexForSegment(
        paragraphs,
        safePosition,
      );

      await _tts.setLanguage(document.language);
      await _tts.setSpeed(playbackSpeed);

      state = state.copyWith(
        status: PlaybackStatus.paused,
        document: document,
        paragraphs: paragraphs,
        currentParagraphIndex: paragraphIndex,
        currentSegmentIndex: safePosition,
        speed: playbackSpeed,
        elapsedMs: _estimateElapsed(safePosition, totalSegments, totalDuration),
        totalDurationMs: totalDuration,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.stopped,
        errorMessage: e is VoxLibriException
            ? e.message
            : 'Impossible de charger le document',
      );
    }
  }

  Future<void> play() async {
    if (state.paragraphs.isEmpty) return;

    try {
      await BackgroundAudioService.enableWakelock();
      await _initBackgroundService();
      state = state.copyWith(status: PlaybackStatus.playing, clearError: true);
      _startSaveTimer();
      await _updateNotification(true);
      await _playFromCurrentSegment();
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.paused,
        errorMessage: 'Erreur de lecture : $e',
      );
    }
  }

  Future<void> pause() async {
    _playbackCancelled = true;
    await _tts.stop();
    _stopSaveTimer();
    state = state.copyWith(status: PlaybackStatus.paused);
    await _saveProgress();
    await _updateNotification(false);
    _updateBackgroundHandler(false);
  }

  Future<void> stop() async {
    _playbackCancelled = true;
    await _tts.stop();
    _stopSaveTimer();
    await BackgroundAudioService.disableWakelock();
    await NotificationService.instance.cancel(1);
    state = state.copyWith(status: PlaybackStatus.stopped);
    await _saveProgress();
    _updateBackgroundHandler(false);
  }

  Future<void> skipNext() async {
    await _interruptPlayback();

    final settings = await _ref.read(settingsRepositoryProvider).loadSettings();
    if (settings.skipUnit == SkipUnit.paragraph) {
      final nextParagraph = state.currentParagraphIndex + 1;
      if (nextParagraph >= state.paragraphs.length) return;
      _updatePosition(
        nextParagraph,
        TextSegmenter.globalIndexForParagraph(state.paragraphs, nextParagraph),
      );
    } else {
      _skipPhrase(forward: true);
    }

    if (state.status == PlaybackStatus.playing) {
      await play();
    } else {
      await _saveProgress();
    }
  }

  Future<void> skipPrevious() async {
    await _interruptPlayback();

    final paragraphStart = TextSegmenter.globalIndexForParagraph(
      state.paragraphs,
      state.currentParagraphIndex,
    );

    if (state.currentSegmentIndex > paragraphStart) {
      _updatePosition(state.currentParagraphIndex, paragraphStart);
    } else if (state.currentParagraphIndex > 0) {
      final prevParagraph = state.currentParagraphIndex - 1;
      _updatePosition(
        prevParagraph,
        TextSegmenter.globalIndexForParagraph(state.paragraphs, prevParagraph),
      );
    }

    if (state.status == PlaybackStatus.playing) {
      await play();
    } else {
      await _saveProgress();
    }
  }

  Future<void> seekToProgress(double value) async {
    final wasPlaying = state.status == PlaybackStatus.playing;
    await _interruptPlayback();

    final targetIndex = (value * state.totalSegments).round().clamp(
          0,
          state.totalSegments > 0 ? state.totalSegments - 1 : 0,
        );
    final paragraphIndex = TextSegmenter.paragraphIndexForSegment(
      state.paragraphs,
      targetIndex,
    );

    _updatePosition(paragraphIndex, targetIndex);

    if (wasPlaying) {
      await play();
    } else {
      await _saveProgress();
    }
  }

  Future<void> setSpeed(double speed) async {
    final clamped = speed.clamp(AppConstants.minSpeed, AppConstants.maxSpeed);
    await _tts.setSpeed(clamped);
    state = state.copyWith(speed: clamped);
  }

  Future<void> _interruptPlayback() async {
    _playbackCancelled = true;
    await _tts.stop();
  }

  Future<void> _playFromCurrentSegment() async {
    _playbackCancelled = false;

    while (!_playbackCancelled &&
        state.status == PlaybackStatus.playing &&
        state.currentParagraphIndex < state.paragraphs.length) {
      final paragraph = state.paragraphs[state.currentParagraphIndex];
      final globalStart = TextSegmenter.globalIndexForParagraph(
        state.paragraphs,
        state.currentParagraphIndex,
      );
      final localStart = (state.currentSegmentIndex - globalStart)
          .clamp(0, paragraph.segments.length - 1);
      final segmentsToSpeak = paragraph.segments.sublist(localStart);

      state = state.copyWith(
        elapsedMs: _estimateElapsed(
          state.currentSegmentIndex,
          state.totalSegments,
          state.totalDurationMs,
        ),
      );
      _updateBackgroundHandler(true);

      await _tts.speakSegments(
        segmentsToSpeak,
        onChunkComplete: (endLocalIndex) {
          if (_playbackCancelled || state.status != PlaybackStatus.playing) return;
          final newSegmentIndex = globalStart + localStart + endLocalIndex + 1;
          if (newSegmentIndex < globalStart + paragraph.segments.length) {
            _updatePosition(state.currentParagraphIndex, newSegmentIndex);
            _updateBackgroundHandler(true);
          }
        },
      );
      if (_playbackCancelled || state.status != PlaybackStatus.playing) break;

      final nextParagraph = state.currentParagraphIndex + 1;
      if (nextParagraph >= state.paragraphs.length) {
        await stop();
        return;
      }

      _updatePosition(
        nextParagraph,
        TextSegmenter.globalIndexForParagraph(state.paragraphs, nextParagraph),
      );
    }

    if (!_playbackCancelled && state.status == PlaybackStatus.playing) {
      await pause();
    }
  }

  void _skipPhrase({required bool forward}) {
    final all = TextSegmenter.flattenSegments(state.paragraphs);
    var index = state.currentSegmentIndex;

    if (forward) {
      while (index < all.length - 1) {
        index++;
        if (all[index].type == SegmentType.sentenceEnd ||
            all[index].type == SegmentType.paragraphBreak) {
          break;
        }
      }
    } else {
      while (index > 0) {
        index--;
        if (all[index].type == SegmentType.sentenceEnd) break;
      }
    }

    final paragraphIndex = TextSegmenter.paragraphIndexForSegment(
      state.paragraphs,
      index,
    );
    _updatePosition(paragraphIndex, index);
  }

  void _updatePosition(int paragraphIndex, int segmentIndex) {
    state = state.copyWith(
      currentParagraphIndex: paragraphIndex,
      currentSegmentIndex: segmentIndex,
      elapsedMs: _estimateElapsed(
        segmentIndex,
        state.totalSegments,
        state.totalDurationMs,
      ),
    );
  }

  int _estimateElapsed(int segmentIndex, int totalSegments, int totalDuration) {
    if (totalSegments <= 0) return 0;
    return ((segmentIndex / totalSegments) * totalDuration).round();
  }

  Future<void> _saveProgress() async {
    final doc = state.document;
    if (doc == null) return;

    try {
      final repository = _ref.read(documentRepositoryProvider);
      final updated = doc.copyWith(
        progress: state.progress,
        lastPosition: state.currentSegmentIndex,
        updatedAt: DateTime.now(),
      );
      await repository.updateDocument(updated);
      state = state.copyWith(document: updated);
    } catch (_) {
      // Sauvegarde silencieuse en cas d'échec
    }
  }

  void _startSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(
      const Duration(seconds: AppConstants.progressSaveIntervalSeconds),
      (_) => _saveProgress(),
    );
  }

  void _stopSaveTimer() {
    _saveTimer?.cancel();
  }

  Future<void> _initBackgroundService() async {
    await BackgroundAudioService.init(
      onPlayRequested: play,
      onPauseRequested: pause,
      onStopRequested: stop,
      onSkipNext: skipNext,
      onSkipPrevious: skipPrevious,
    );
  }

  void _updateBackgroundHandler(bool playing) {
    BackgroundAudioService.handler?.syncPlaybackState(
      title: state.document?.title ?? AppConstants.appName,
      position: Duration(milliseconds: state.elapsedMs),
      duration: Duration(milliseconds: state.totalDurationMs),
      playing: playing,
    );
  }

  Future<void> _updateNotification(bool isPlaying) async {
    await NotificationService.instance.showPlaybackNotification(
      id: 1,
      title: state.document?.title ?? AppConstants.appName,
      isPlaying: isPlaying,
    );
  }

  @override
  void dispose() {
    _stopSaveTimer();
    super.dispose();
  }
}
