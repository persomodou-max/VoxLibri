import 'package:flutter/material.dart';

/// Affichage du paragraphe en cours de lecture.
class TextDisplay extends StatelessWidget {
  const TextDisplay({
    super.key,
    required this.text,
    this.scrollable = true,
  });

  final String text;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        text.isEmpty ? 'Chargement du texte…' : text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
              fontSize: 18,
            ),
      ),
    );

    if (!scrollable) return content;

    return SingleChildScrollView(child: content);
  }
}
