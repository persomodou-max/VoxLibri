import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../core/utils/file_utils.dart';

/// Paramètres persistants de l'application.
class AppSettings {
  final double defaultSpeed;
  final SkipUnit skipUnit;
  final AppThemeMode themeMode;

  const AppSettings({
    this.defaultSpeed = AppConstants.defaultSpeed,
    this.skipUnit = SkipUnit.paragraph,
    this.themeMode = AppThemeMode.system,
  });

  AppSettings copyWith({
    double? defaultSpeed,
    SkipUnit? skipUnit,
    AppThemeMode? themeMode,
  }) {
    return AppSettings(
      defaultSpeed: defaultSpeed ?? this.defaultSpeed,
      skipUnit: skipUnit ?? this.skipUnit,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'defaultSpeed': defaultSpeed,
      'skipUnit': skipUnit.name,
      'themeMode': themeMode.name,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      defaultSpeed: (map['defaultSpeed'] as num?)?.toDouble() ??
          AppConstants.defaultSpeed,
      skipUnit: SkipUnit.values.byName(
        map['skipUnit'] as String? ?? SkipUnit.paragraph.name,
      ),
      themeMode: AppThemeMode.values.byName(
        map['themeMode'] as String? ?? AppThemeMode.system.name,
      ),
    );
  }
}

/// Persistance locale des paramètres (fichier JSON, sans réseau).
class SettingsRepository {
  Future<File> _settingsFile() async {
    final dir = await FileUtils.getAppDirectoryPath();
    return File(p.join(dir, AppConstants.settingsFileName));
  }

  Future<AppSettings> loadSettings() async {
    try {
      final file = await _settingsFile();
      if (!await file.exists()) {
        return const AppSettings();
      }
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      return AppSettings.fromMap(map);
    } catch (e) {
      throw SettingsException('Impossible de charger les paramètres', e);
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final file = await _settingsFile();
      await file.writeAsString(jsonEncode(settings.toMap()));
    } catch (e) {
      throw SettingsException('Impossible de sauvegarder les paramètres', e);
    }
  }
}
