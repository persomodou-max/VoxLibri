import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants.dart';
import '../data/repositories/settings_repository.dart';
import 'database_provider.dart';
import 'documents_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// État des paramètres utilisateur.
final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.read(settingsRepositoryProvider).loadSettings();
  }

  Future<void> updateDefaultSpeed(double speed) async {
    final current = state.value ?? const AppSettings();
    final updated = current.copyWith(
      defaultSpeed: speed.clamp(AppConstants.minSpeed, AppConstants.maxSpeed),
    );
    await _persist(updated);
  }

  Future<void> updateSkipUnit(SkipUnit unit) async {
    final current = state.value ?? const AppSettings();
    await _persist(current.copyWith(skipUnit: unit));
  }

  Future<void> updateThemeMode(AppThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    await _persist(current.copyWith(themeMode: mode));
  }

  Future<void> deleteAllDocuments() async {
    final docs = await ref.read(documentRepositoryProvider).getAllDocuments();
    final actions = ref.read(documentActionProvider.notifier);
    for (final doc in docs) {
      await actions.deleteDocument(doc);
    }
  }

  Future<void> _persist(AppSettings settings) async {
    state = AsyncValue.data(settings);
    await ref.read(settingsRepositoryProvider).saveSettings(settings);
  }
}

/// Provider du mode de thème pour MaterialApp.
final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider).value;
  switch (settings?.themeMode ?? AppThemeMode.system) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});
