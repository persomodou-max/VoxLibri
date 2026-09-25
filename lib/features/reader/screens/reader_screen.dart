import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/utils/text_utils.dart';
import '../../../domain/models/document.dart';
import '../../../features/reader/notifiers/player_notifier.dart';
import '../../../providers/player_provider.dart';
import '../widgets/playback_controls.dart';
import '../widgets/progress_slider.dart';
import '../widgets/text_display.dart';

/// Écran de lecture d'un document.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.document});

  final Document document;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  double _sliderProgress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playerProvider.notifier).loadDocument(widget.document);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final notifier = ref.read(playerProvider.notifier);
    final theme = Theme.of(context);

    ref.listen(playerProvider, (previous, next) {
      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isPlaying = playerState.status == PlaybackStatus.playing;
    final isLoading = playerState.status == PlaybackStatus.loading;
    final displayProgress = _sliderProgress > 0 &&
            playerState.status != PlaybackStatus.playing
        ? _sliderProgress
        : playerState.progress;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      onPressed: () async {
                        await notifier.pause();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.document.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.speed_rounded, size: 20),
                      label: Text('${playerState.speed.toStringAsFixed(1)}x',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      onPressed: () =>
                          _showSpeedPicker(context, playerState.speed, notifier),
                      style: TextButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                        foregroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: theme.brightness == Brightness.light ? 0.05 : 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: TextDisplay(text: playerState.currentParagraphText),
                        ),
                      ),
              ),
              if (!isLoading)
                Container(
                  padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: Column(
                    children: [
                      ProgressSlider(
                        progress: displayProgress,
                        elapsedLabel: TextUtils.formatDuration(playerState.elapsedMs),
                        remainingLabel: TextUtils.formatDuration(playerState.remainingMs),
                        onChanged: (value) {
                          setState(() => _sliderProgress = value);
                        },
                        onChangeEnd: (value) {
                          setState(() => _sliderProgress = 0);
                          notifier.seekToProgress(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      PlaybackControls(
                        isPlaying: isPlaying,
                        onPrevious: notifier.skipPrevious,
                        onPlayPause: () {
                          if (isPlaying) {
                            notifier.pause();
                          } else {
                            notifier.play();
                          }
                        },
                        onNext: notifier.skipNext,
                        onStop: notifier.stop,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSpeedPicker(
    BuildContext context,
    double currentSpeed,
    PlayerNotifier notifier,
  ) async {
    final theme = Theme.of(context);
    final speeds = <double>[];
    for (var s = AppConstants.minSpeed;
        s <= AppConstants.maxSpeed + 0.001;
        s += AppConstants.speedStep) {
      speeds.add(double.parse(s.toStringAsFixed(2)));
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Vitesse de lecture',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: speeds.length,
                    itemBuilder: (context, index) {
                      final speed = speeds[index];
                      final isSelected = speed == currentSpeed;
                      return ListTile(
                        title: Text('${speed.toStringAsFixed(2)}x',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : null,
                            )),
                        trailing: isSelected
                            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                            : null,
                        onTap: () {
                          notifier.setSpeed(speed);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
