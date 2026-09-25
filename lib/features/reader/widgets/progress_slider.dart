import 'package:flutter/material.dart';

/// Slider de progression dans le document.
class ProgressSlider extends StatelessWidget {
  const ProgressSlider({
    super.key,
    required this.progress,
    required this.elapsedLabel,
    required this.remainingLabel,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double progress;
  final String elapsedLabel;
  final String remainingLabel;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Slider(
          value: progress.clamp(0.0, 1.0),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(elapsedLabel),
              Text('$remainingLabel restant'),
            ],
          ),
        ),
      ],
    );
  }
}
