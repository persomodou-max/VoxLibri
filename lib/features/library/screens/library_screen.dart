import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/exceptions.dart';
import '../../../domain/models/document.dart';
import '../../../providers/documents_provider.dart';
import '../../reader/screens/reader_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../about/screens/about_screen.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_library.dart';

/// Écran principal de la bibliothèque de documents.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentsStreamProvider);
    final importState = ref.watch(documentActionProvider);

    ref.listen(documentActionProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is VoxLibriException
              ? error.message
              : 'Erreur lors de l\'opération : $error';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      );
    });

    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                AppConstants.appName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'À propos',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Paramètres',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverFillRemaining(
            child: Stack(
              children: [
                documentsAsync.when(
                  data: (documents) {
                    if (documents.isEmpty) return const EmptyLibrary();
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return DocumentCard(
                          document: doc,
                          onTap: () => _openReader(context, doc),
                          onDelete: () => _confirmDelete(context, ref, doc),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Erreur de chargement : $error'),
                  ),
                ),
                if (importState.isLoading)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32, horizontal: 48),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 24),
                              Text(
                                'Extraction du texte...',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: importState.isLoading ? null : () => _importPdf(context, ref),
        tooltip: 'Importer un PDF',
        icon: const Icon(Icons.add_rounded),
        label: const Text('Importer', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _importPdf(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result == null || result.files.isEmpty) return;

      final path = result.files.single.path;
      if (path == null) {
        throw FileImportException('Impossible d\'accéder au fichier sélectionné');
      }

      await ref.read(documentActionProvider.notifier).importPdf(path);
    } catch (e) {
      if (!context.mounted) return;
      final message = e is VoxLibriException
          ? e.message
          : 'Erreur lors de la sélection : $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openReader(BuildContext context, Document doc) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(document: doc),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Document doc,
  ) async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Supprimer le document ?'),
        content: Text(
          '« ${doc.title} » sera définitivement supprimé.',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(documentActionProvider.notifier).deleteDocument(doc);
    }
  }
}
