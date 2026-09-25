import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../providers/settings_provider.dart';

/// Écran des paramètres de l'application.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          children: [
            _buildSectionTitle(theme, 'Lecture'),
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.speed_rounded, color: theme.colorScheme.primary),
                    ),
                    title: const Text('Vitesse par défaut', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${settings.defaultSpeed.toStringAsFixed(2)}x'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                        Expanded(
                          child: Slider(
                            value: settings.defaultSpeed,
                            min: AppConstants.minSpeed,
                            max: AppConstants.maxSpeed,
                            divisions: ((AppConstants.maxSpeed - AppConstants.minSpeed) /
                                    AppConstants.speedStep)
                                .round(),
                            label: '${settings.defaultSpeed.toStringAsFixed(2)}x',
                            onChanged: (value) {
                              ref.read(settingsProvider.notifier).updateDefaultSpeed(value);
                            },
                          ),
                        ),
                        Icon(Icons.directions_run_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.skip_next_rounded, color: theme.colorScheme.primary),
                    ),
                    title: const Text('Unité de saut', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<SkipUnit>(
                        value: settings.skipUnit,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(
                            value: SkipUnit.paragraph,
                            child: Text('Paragraphe'),
                          ),
                          DropdownMenuItem(
                            value: SkipUnit.phrase,
                            child: Text('Phrase'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(settingsProvider.notifier).updateSkipUnit(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            _buildSectionTitle(theme, 'Apparence'),
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 24),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.dark_mode_rounded, color: theme.colorScheme.secondary),
                ),
                title: const Text('Thème', style: TextStyle(fontWeight: FontWeight.w600)),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<AppThemeMode>(
                    value: settings.themeMode,
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(
                        value: AppThemeMode.system,
                        child: Text('Système'),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.light,
                        child: Text('Clair'),
                      ),
                      DropdownMenuItem(
                        value: AppThemeMode.dark,
                        child: Text('Sombre'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(settingsProvider.notifier).updateThemeMode(value);
                      }
                    },
                  ),
                ),
              ),
            ),

            _buildSectionTitle(theme, 'Données'),
            Card(
              clipBehavior: Clip.antiAlias,
              margin: const EdgeInsets.only(bottom: 24),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delete_forever_rounded, color: theme.colorScheme.error),
                ),
                title: Text(
                  'Supprimer tous les documents',
                  style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
                ),
                onTap: () => _confirmDeleteAll(context, ref, theme),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context, WidgetRef ref, ThemeData theme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tout supprimer ?'),
        content: const Text(
          'Tous les documents importés seront définitivement supprimés. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer tout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(settingsProvider.notifier).deleteAllDocuments();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Tous les documents ont été supprimés'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      }
    }
  }
}
