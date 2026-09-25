import 'package:flutter/material.dart';

/// Contrôles de lecture (précédent, play/pause, suivant).
class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
    required this.isPlaying,
    required this.onPrevious,
    required this.onPlayPause,
    required this.onNext,
    required this.onStop,
  });

  final bool isPlaying;
  final VoidCallback onPrevious;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_previous),
          tooltip: 'Précédent',
          onPressed: onPrevious,
        ),
        IconButton(
          iconSize: 48,
          icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          tooltip: isPlaying ? 'Pause' : 'Lecture',
          onPressed: onPlayPause,
        ),
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.skip_next),
          tooltip: 'Suivant',
          onPressed: onNext,
        ),
        IconButton(
          iconSize: 28,
          icon: const Icon(Icons.stop_circle_outlined),
          tooltip: 'Arrêter',
          onPressed: onStop,
        ),
      ],
    );
  }
}
