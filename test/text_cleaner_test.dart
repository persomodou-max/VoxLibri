import 'package:flutter_test/flutter_test.dart';
import 'package:voxlibri/domain/services/text_cleaner.dart';

void main() {
  group('TextCleaner Tests', () {
    test('Should remove page numbers', () {
      const input = "Paragraphe 1\n  123  \nParagraphe 2";
      const expected = "Paragraphe 1\n\nParagraphe 2";
      expect(TextCleaner.clean(input), expected);
    });

    test('Should remove page labels', () {
      const input = "Paragraphe 1\n-- Page 12 --\nParagraphe 2";
      const expected = "Paragraphe 1\n\nParagraphe 2";
      expect(TextCleaner.clean(input), expected);
    });

    test('Should merge broken lines', () {
      const input = "Ceci est le début d'une\nphrase qui continue sur la ligne\nsuivante.";
      const expected = "Ceci est le début d'une phrase qui continue sur la ligne suivante.";
      expect(TextCleaner.clean(input), expected);
    });

    test('Should preserve bullet lists (unmerged)', () {
      const input = "Liste de courses:\n* Pain\n- Lait\n• Oeufs\n1. Sel\n2. Poivre";
      final result = TextCleaner.clean(input);
      expect(result.contains("Liste de courses:"), true);
      expect(result.contains("* Pain"), true);
      expect(result.contains("- Lait"), true);
      expect(result.contains("• Oeufs"), true);
      expect(result.contains("1. Sel"), true);
      expect(result.contains("2. Poivre"), true);
    });

    test('Should normalize multiple spaces', () {
      const input = "Ceci   contient   beaucoup    d'espaces.";
      const expected = "Ceci contient beaucoup d'espaces.";
      expect(TextCleaner.clean(input), expected);
    });
  });
}
