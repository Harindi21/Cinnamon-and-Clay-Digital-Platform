import 'package:cinnamon_clay_admin/src/media/media_models.dart';
import 'package:flutter/material.dart';

class MediaMetadataDialog extends StatefulWidget {
  const MediaMetadataDialog({
    required this.initialPurpose,
    this.asset,
    this.initialAltText,
    super.key,
  });

  final MediaPurpose initialPurpose;
  final AdminMediaAsset? asset;
  final String? initialAltText;

  @override
  State<MediaMetadataDialog> createState() => _MediaMetadataDialogState();
}

class _MediaMetadataDialogState extends State<MediaMetadataDialog> {
  late MediaPurpose _purpose;
  late final TextEditingController _altController;
  late final TextEditingController _sortOrderController;
  late bool _active;
  String? _error;

  @override
  void initState() {
    super.initState();
    final asset = widget.asset;
    _purpose = asset?.purpose ?? widget.initialPurpose;
    _altController = TextEditingController(
      text: asset?.altText ?? widget.initialAltText ?? '',
    );
    _sortOrderController = TextEditingController(
      text: (asset?.sortOrder ?? 0).toString(),
    );
    _active = asset?.active ?? true;
  }

  @override
  void dispose() {
    _altController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.asset == null ? 'Upload image' : 'Edit image metadata'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<MediaPurpose>(
                initialValue: _purpose,
                decoration: const InputDecoration(
                  labelText: 'Placement',
                  border: OutlineInputBorder(),
                ),
                items: MediaPurpose.values
                    .map(
                      (purpose) => DropdownMenuItem<MediaPurpose>(
                        value: purpose,
                        child: Text(purpose.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _purpose = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _altController,
                maxLength: 300,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Alternative text',
                  helperText:
                      'Describe meaningful image content for screen-reader users.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sort order',
                  helperText: 'Lower values appear first in the gallery.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active on public website'),
                subtitle: Text(
                  _purpose == MediaPurpose.gallery
                      ? 'Active gallery images are displayed in sort order.'
                      : 'Activating this image automatically replaces the current active ${_purpose.label.toLowerCase()} image.',
                ),
                value: _active,
                onChanged: (value) => setState(() => _active = value),
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.asset == null ? 'Continue' : 'Save'),
        ),
      ],
    );
  }

  void _submit() {
    final altText = _altController.text.trim();
    final sortOrder = int.tryParse(_sortOrderController.text.trim());
    if (sortOrder == null || sortOrder < 0 || sortOrder > 100000) {
      setState(() => _error = 'Sort order must be between 0 and 100000.');
      return;
    }
    setState(() => _error = null);
    Navigator.of(context).pop(
      MediaDraft(
        purpose: _purpose,
        altText: altText,
        sortOrder: sortOrder,
        active: _active,
      ),
    );
  }
}
