import 'dart:math' as math;

import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/media/media_editors.dart';
import 'package:cinnamon_clay_admin/src/media/media_models.dart';
import 'package:cinnamon_clay_admin/src/media/media_repository.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaPage extends ConsumerStatefulWidget {
  const MediaPage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  ConsumerState<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends ConsumerState<MediaPage> {
  static const XTypeGroup _imageTypes = XTypeGroup(
    label: 'JPEG and PNG images',
    extensions: <String>['jpg', 'jpeg', 'png'],
    mimeTypes: <String>['image/jpeg', 'image/png'],
  );

  bool _mutating = false;
  double? _progress;

  @override
  Widget build(BuildContext context) {
    final media = ref.watch(mediaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        actions: <Widget>[
          if (widget.identity.hasRole('admin'))
            IconButton(
              tooltip: 'Object-storage maintenance',
              onPressed: _mutating ? null : () => _showOrphans(context),
              icon: const Icon(Icons.cleaning_services_outlined),
            ),
          IconButton(
            tooltip: 'Refresh media',
            onPressed: _mutating ? null : () => ref.invalidate(mediaProvider),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out ${widget.identity.username}',
            onPressed: _mutating
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: _mutating
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4, value: _progress),
              )
            : null,
      ),
      body: media.when(
        data: (snapshot) => RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            children: <Widget>[
              _MediaIntro(onUpload: _mutating ? null : () => _upload(context)),
              const SizedBox(height: 28),
              for (final purpose in MediaPurpose.values) ...<Widget>[
                _PurposeHeader(
                  purpose: purpose,
                  count: snapshot.forPurpose(purpose).length,
                  onUpload: _mutating
                      ? null
                      : () => _upload(context, purpose: purpose),
                  onBatchUpload: purpose == MediaPurpose.gallery && !_mutating
                      ? () => _uploadGalleryBatch(context)
                      : null,
                ),
                const SizedBox(height: 8),
                if (purpose == MediaPurpose.gallery)
                  _GalleryManager(
                    assets: snapshot.forPurpose(purpose),
                    disabled: _mutating,
                    onReorder: _reorderGallery,
                    onEdit: (asset) => _editMetadata(context, asset),
                    onReplace: (asset) => _replace(context, asset),
                    onToggleActive: (asset) => _toggleActive(context, asset),
                  )
                else if (snapshot.forPurpose(purpose).isEmpty)
                  _EmptyPurpose(purpose: purpose)
                else
                  ...snapshot
                      .forPurpose(purpose)
                      .map(
                        (asset) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MediaAssetCard(
                            asset: asset,
                            onEdit: _mutating
                                ? null
                                : () => _editMetadata(context, asset),
                            onReplace: _mutating
                                ? null
                                : () => _replace(context, asset),
                            onToggleActive: _mutating
                                ? null
                                : () => _toggleActive(context, asset),
                          ),
                        ),
                      ),
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
        error: (error, stackTrace) => _MediaError(
          error: error,
          onRetry: () => ref.invalidate(mediaProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _refresh() async {
    ref.invalidate(mediaProvider);
    await ref.read(mediaProvider.future);
  }

  Future<void> _upload(
    BuildContext context, {
    MediaPurpose purpose = MediaPurpose.gallery,
  }) async {
    final file = await _pickImage();
    if (file == null || !context.mounted) {
      return;
    }

    final draft = await showDialog<MediaDraft>(
      context: context,
      builder: (context) => MediaMetadataDialog(
        initialPurpose: purpose,
        initialAltText: _suggestAltText(file.name),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Image uploaded.',
      uploadProgress: true,
      operation: () => ref
          .read(mediaRepositoryProvider)
          .upload(file: file, draft: draft, onSendProgress: _onSendProgress),
    );
  }

  Future<void> _uploadGalleryBatch(BuildContext context) async {
    final files = await _pickImages();
    if (files.isEmpty || !context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upload ${files.length} gallery images?'),
        content: const Text(
          'Images will be uploaded as active gallery assets using filename-based alternative text and centered crop focus. You can refine captions and focal points after upload.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Upload batch'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final snapshot = await ref.read(mediaProvider.future);
    final startingOrder = snapshot.activeGallery.fold<int>(
      0,
      (highest, asset) => math.max(highest, asset.sortOrder),
    );

    await _runMutation(
      successMessage: '${files.length} gallery image(s) uploaded.',
      uploadProgress: true,
      operation: () async {
        for (var index = 0; index < files.length; index++) {
          final file = files[index];
          try {
            await ref
                .read(mediaRepositoryProvider)
                .upload(
                  file: file,
                  draft: MediaDraft(
                    purpose: MediaPurpose.gallery,
                    altText: _suggestAltText(file.name),
                    caption: '',
                    focalXPercent: 50,
                    focalYPercent: 50,
                    sortOrder: startingOrder + ((index + 1) * 10),
                    active: true,
                  ),
                  onSendProgress: (sent, total) {
                    if (!mounted || total <= 0) {
                      return;
                    }
                    setState(() {
                      _progress = (index + (sent / total)) / files.length;
                    });
                  },
                );
          } on MediaMutationException catch (error) {
            throw MediaMutationException(
              message:
                  'Batch stopped after $index of ${files.length} uploads. ${error.message}',
              statusCode: error.statusCode,
              isConflict: error.isConflict,
            );
          }
        }
      },
    );
  }

  Future<void> _editMetadata(
    BuildContext context,
    AdminMediaAsset asset,
  ) async {
    final draft = await showDialog<MediaDraft>(
      context: context,
      builder: (context) =>
          MediaMetadataDialog(initialPurpose: asset.purpose, asset: asset),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Image metadata updated.',
      operation: () => ref
          .read(mediaRepositoryProvider)
          .updateMetadata(current: asset, draft: draft),
    );
  }

  Future<void> _replace(BuildContext context, AdminMediaAsset asset) async {
    final file = await _pickImage();
    if (file == null || !context.mounted) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace image file?'),
        content: Text(
          'Replace ${asset.originalFilename} with ${file.name}? '
          'The existing metadata and placement will be kept.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Image file replaced.',
      uploadProgress: true,
      operation: () => ref
          .read(mediaRepositoryProvider)
          .replaceContent(
            current: asset,
            file: file,
            onSendProgress: _onSendProgress,
          ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    AdminMediaAsset asset,
  ) async {
    if (asset.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hide image?'),
          content: Text(
            '${asset.originalFilename} will stop appearing on the public website. '
            'The binary remains in object storage so the asset can be reactivated.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hide'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        return;
      }
      await _runMutation(
        successMessage: 'Image hidden.',
        operation: () => ref.read(mediaRepositoryProvider).deactivate(asset),
      );
      return;
    }

    await _runMutation(
      successMessage: 'Image activated.',
      operation: () => ref
          .read(mediaRepositoryProvider)
          .updateMetadata(
            current: asset,
            draft: MediaDraft(
              purpose: asset.purpose,
              altText: asset.altText,
              caption: asset.caption,
              focalXPercent: asset.focalXPercent,
              focalYPercent: asset.focalYPercent,
              sortOrder: asset.sortOrder,
              active: true,
            ),
          ),
    );
  }

  Future<void> _reorderGallery(List<AdminMediaAsset> orderedAssets) async {
    await _runMutation(
      successMessage: 'Gallery order updated.',
      operation: () =>
          ref.read(mediaRepositoryProvider).reorderGallery(orderedAssets),
    );
  }

  Future<void> _showOrphans(BuildContext context) async {
    setState(() {
      _mutating = true;
      _progress = null;
    });
    try {
      final report = await ref.read(mediaRepositoryProvider).findOrphans();
      if (!context.mounted) {
        return;
      }

      final shouldClean = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Object-storage maintenance'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  report.count == 0
                      ? 'No orphaned managed media objects were found.'
                      : '${report.count} orphaned object(s) are older than the safety grace period (${report.gracePeriod}).',
                ),
                if (report.objectKeys.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(report.objectKeys.join('\n')),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
            if (report.count > 0)
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete orphans'),
              ),
          ],
        ),
      );

      if (shouldClean == true && mounted) {
        final result = await ref.read(mediaRepositoryProvider).cleanupOrphans();
        if (!mounted) {
          return;
        }
        _showMessage(
          'Orphan cleanup: ${result.deleted} deleted, ${result.failed} failed.',
        );
      }
    } on MediaMutationException catch (error) {
      if (mounted) {
        _showMessage(error.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _mutating = false;
          _progress = null;
        });
      }
    }
  }

  Future<List<XFile>> _pickImages() async {
    try {
      return await openFiles(
        acceptedTypeGroups: const <XTypeGroup>[_imageTypes],
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to open the image picker: $error', error: true);
      }
      return const <XFile>[];
    }
  }

  Future<XFile?> _pickImage() async {
    try {
      return await openFile(
        acceptedTypeGroups: const <XTypeGroup>[_imageTypes],
      );
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to open the image picker: $error', error: true);
      }
      return null;
    }
  }

  Future<void> _runMutation<T>({
    required String successMessage,
    required Future<T> Function() operation,
    bool uploadProgress = false,
  }) async {
    if (_mutating) {
      return;
    }
    setState(() {
      _mutating = true;
      _progress = uploadProgress ? 0 : null;
    });
    try {
      await operation();
      if (!mounted) {
        return;
      }
      ref.invalidate(mediaProvider);
      await ref.read(mediaProvider.future);
      if (mounted) {
        _showMessage(successMessage);
      }
    } on MediaMutationException catch (error) {
      if (!mounted) {
        return;
      }
      ref.invalidate(mediaProvider);
      try {
        await ref.read(mediaProvider.future);
      } catch (_) {
        // The mutation error is more useful than a refresh failure here.
      }
      if (!mounted) {
        return;
      }
      if (error.isConflict) {
        _showMessage('${error.message} Media has been refreshed.', error: true);
      } else {
        _showMessage(error.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _mutating = false;
          _progress = null;
        });
      }
    }
  }

  void _onSendProgress(int sent, int total) {
    if (!mounted || total <= 0) {
      return;
    }
    setState(() => _progress = sent / total);
  }

  void _showMessage(String message, {bool error = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: error ? TextStyle(color: colorScheme.onError) : null,
        ),
        backgroundColor: error ? colorScheme.error : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _suggestAltText(String filename) {
    final dot = filename.lastIndexOf('.');
    final base = dot > 0 ? filename.substring(0, dot) : filename;
    return base.replaceAll(RegExp(r'[-_]+'), ' ').trim();
  }
}

class _MediaIntro extends StatelessWidget {
  const _MediaIntro({required this.onUpload});

  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Managed website media',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload JPEG or PNG images to object storage. Binary content is validated by the backend; placement metadata is versioned in PostgreSQL.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_outlined),
              label: const Text('Upload image'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurposeHeader extends StatelessWidget {
  const _PurposeHeader({
    required this.purpose,
    required this.count,
    required this.onUpload,
    required this.onBatchUpload,
  });

  final MediaPurpose purpose;
  final int count;
  final VoidCallback? onUpload;
  final VoidCallback? onBatchUpload;

  @override
  Widget build(BuildContext context) {
    final description = switch (purpose) {
      MediaPurpose.hero =>
        'Single active hero image. Activating another hero automatically supersedes the current one.',
      MediaPurpose.about =>
        'Single active image used beside the About content.',
      MediaPurpose.gallery =>
        'Multiple active images displayed in ascending sort order.',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${purpose.label} · $count',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(description),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            if (onBatchUpload != null)
              OutlinedButton.icon(
                onPressed: onBatchUpload,
                icon: const Icon(Icons.library_add_outlined),
                label: const Text('Upload batch'),
              ),
            OutlinedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Upload'),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaAssetCard extends ConsumerWidget {
  const _MediaAssetCard({
    required this.asset,
    required this.onEdit,
    required this.onReplace,
    required this.onToggleActive,
  });

  final AdminMediaAsset asset;
  final VoidCallback? onEdit;
  final VoidCallback? onReplace;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final image = ref.watch(
      mediaContentProvider((id: asset.id, version: asset.version)),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 620;
          final preview = SizedBox(
            width: compact ? double.infinity : 190,
            height: compact ? 180 : 150,
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: image.when(
                data: (bytes) {
                  final imageWidget = Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    alignment: Alignment(
                      (asset.focalXPercent - 50) / 50,
                      (asset.focalYPercent - 50) / 50,
                    ),
                  );
                  if (asset.active) {
                    return imageWidget;
                  }
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Opacity(opacity: 0.45, child: imageWidget),
                      const Center(child: Icon(Icons.visibility_off_outlined)),
                    ],
                  );
                },
                error: (error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image_outlined, size: 42),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          );

          final details = Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      Text(
                        asset.originalFilename,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(asset.active ? 'Active' : 'Hidden'),
                      ),
                      Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text('v${asset.version}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    asset.altText.isEmpty
                        ? 'No alternative text set.'
                        : asset.altText,
                  ),
                  if (asset.caption.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      asset.caption,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${asset.dimensionsLabel} · ${asset.sizeLabel} · ${asset.contentType} · focal ${asset.focalPointLabel} · order ${asset.sortOrder}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Metadata'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onReplace,
                        icon: const Icon(Icons.swap_horiz_outlined),
                        label: const Text('Replace file'),
                      ),
                      TextButton.icon(
                        onPressed: onToggleActive,
                        icon: Icon(
                          asset.active
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        label: Text(asset.active ? 'Hide' : 'Activate'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                preview,
                Row(children: <Widget>[details]),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[preview, details],
          );
        },
      ),
    );
  }
}

class _GalleryManager extends StatefulWidget {
  const _GalleryManager({
    required this.assets,
    required this.disabled,
    required this.onReorder,
    required this.onEdit,
    required this.onReplace,
    required this.onToggleActive,
  });

  final List<AdminMediaAsset> assets;
  final bool disabled;
  final Future<void> Function(List<AdminMediaAsset>) onReorder;
  final ValueChanged<AdminMediaAsset> onEdit;
  final ValueChanged<AdminMediaAsset> onReplace;
  final ValueChanged<AdminMediaAsset> onToggleActive;

  @override
  State<_GalleryManager> createState() => _GalleryManagerState();
}

class _GalleryManagerState extends State<_GalleryManager> {
  late List<AdminMediaAsset> _active;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(covariant _GalleryManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSignature = _signature(oldWidget.assets);
    final newSignature = _signature(widget.assets);
    if (oldSignature != newSignature) {
      _sync();
    }
  }

  void _sync() {
    _active = widget.assets
        .where((asset) => asset.active)
        .toList(growable: true);
  }

  String _signature(List<AdminMediaAsset> assets) => assets
      .map(
        (asset) =>
            '${asset.id}:${asset.version}:${asset.active}:${asset.sortOrder}',
      )
      .join('|');

  @override
  Widget build(BuildContext context) {
    final hidden = widget.assets
        .where((asset) => !asset.active)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_active.isEmpty)
          const _EmptyPurpose(purpose: MediaPurpose.gallery)
        else ...<Widget>[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.drag_indicator),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Drag active images to set the public gallery order. The backend saves the complete order atomically.',
                  ),
                ),
              ],
            ),
          ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _active.length,
            onReorderItem: widget.disabled ? (_, _) {} : _onReorder,
            itemBuilder: (context, index) {
              final asset = _active[index];
              return Padding(
                key: ValueKey<String>('gallery-${asset.id}'),
                padding: const EdgeInsets.only(bottom: 12),
                child: _MediaAssetCard(
                  asset: asset,
                  onEdit: widget.disabled ? null : () => widget.onEdit(asset),
                  onReplace: widget.disabled
                      ? null
                      : () => widget.onReplace(asset),
                  onToggleActive: widget.disabled
                      ? null
                      : () => widget.onToggleActive(asset),
                ),
              );
            },
          ),
        ],
        if (hidden.isNotEmpty) ...<Widget>[
          const SizedBox(height: 18),
          Text(
            'Hidden gallery assets',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final asset in hidden)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MediaAssetCard(
                asset: asset,
                onEdit: widget.disabled ? null : () => widget.onEdit(asset),
                onReplace: widget.disabled
                    ? null
                    : () => widget.onReplace(asset),
                onToggleActive: widget.disabled
                    ? null
                    : () => widget.onToggleActive(asset),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    setState(() {
      final item = _active.removeAt(oldIndex);
      _active.insert(newIndex, item);
    });
    await widget.onReorder(List<AdminMediaAsset>.unmodifiable(_active));
    if (mounted) {
      setState(_sync);
    }
  }
}

class _EmptyPurpose extends StatelessWidget {
  const _EmptyPurpose({required this.purpose});

  final MediaPurpose purpose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No ${purpose.label.toLowerCase()} images have been uploaded.',
      ),
    );
  }
}

class _MediaError extends StatelessWidget {
  const _MediaError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is MediaMutationException
        ? (error as MediaMutationException).message
        : 'Unable to load media.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.image_not_supported_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
