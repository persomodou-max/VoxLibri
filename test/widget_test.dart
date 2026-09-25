import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:voxlibri/app.dart';
import 'package:voxlibri/core/constants.dart';
import 'package:voxlibri/domain/models/document.dart';
import 'package:voxlibri/providers/documents_provider.dart';
import 'package:voxlibri/providers/settings_provider.dart';
import 'package:voxlibri/data/repositories/settings_repository.dart';

void main() {
  testWidgets('Affiche l\'écran bibliothèque vide', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsStreamProvider.overrideWith(
            (ref) => Stream.value(<Document>[]),
          ),
          settingsProvider.overrideWith(() => _FixedSettingsNotifier()),
        ],
        child: const VoxLibriApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Aucun document.'), findsOneWidget);
  });
}

class _FixedSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async => const AppSettings();
}
