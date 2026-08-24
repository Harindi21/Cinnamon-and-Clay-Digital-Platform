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
  late final TextEditingController _captionController;
  late final TextEditingController _sortOrderController;
  late double _focalX;
  late double _focalY;
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
    _captionController = TextEditingController(text: asset?.caption ?? '');
    _sortOrderController = TextEditingController(
      text: (asset?.sortOrder ?? 0).toString(),
    );
    _focalX = (asset?.focalXPercent ?? 50).toDouble();
    _focalY = (asset?.focalYPercent ?? 50).toDouble();
    _active = asset?.active ?? true;
  }

  @override
  void dispose() {
    _altController.dispose();
    _captionController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.asset == null ? 'Upload image' : 'Edit image metadata',
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
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
              const SizedBox(height: 12),
              TextField(
                controller: _captionController,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Public caption (optional)',
                  helperText:
                      'Shown below gallery images and in the fullscreen viewer.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Crop focal point',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose the subject position so responsive crops keep the important part visible.',
              ),
              _FocalSlider(
                label: 'Horizontal',
                leadingLabel: 'Left',
                trailingLabel: 'Right',
                value: _focalX,
                onChanged: (value) => setState(() => _focalX = value),
              ),
              _FocalSlider(
                label: 'Vertical',
                leadingLabel: 'Top',
                trailingLabel: 'Bottom',
                value: _focalY,
                onChanged: (value) => setState(() => _focalY = value),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sortOrderController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Sort order',
                  helperText: _purpose == MediaPurpose.gallery
                      ? 'Gallery drag-and-drop ordering will normalize this value automatically.'
                      : 'Lower values win when selecting the active placement.',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active on public website'),
                subtitle: Text(
                  _purpose == MediaPurpose.gallery
                      ? 'Active gallery images are displayed in managed order.'
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
    final caption = _captionController.text.trim();
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
        caption: caption,
        focalXPercent: _focalX.round(),
        focalYPercent: _focalY.round(),
        sortOrder: sortOrder,
        active: _active,
      ),
    );
  }
}

class _FocalSlider extends StatelessWidget {
  const _FocalSlider({
    required this.label,
    required this.leadingLabel,
    required this.trailingLabel,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String leadingLabel;
  final String trailingLabel;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text('${value.round()}%'),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          label: '${value.round()}%',
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(leadingLabel, style: Theme.of(context).textTheme.bodySmall),
            Text(trailingLabel, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
