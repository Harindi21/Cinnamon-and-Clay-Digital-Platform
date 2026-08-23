import 'package:cinnamon_clay_admin/src/site_settings/site_settings_models.dart';
import 'package:flutter/material.dart';

class SiteEditorDialog extends StatefulWidget {
  const SiteEditorDialog({required this.site});

  final AdminSiteProfile site;

  @override
  State<SiteEditorDialog> createState() => _SiteEditorDialogState();
}

class _SiteEditorDialogState extends State<SiteEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _taglineController;
  late final TextEditingController _heroController;
  late final TextEditingController _menuNoteController;
  late final TextEditingController _aboutTitleController;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.site.brandName);
    _taglineController = TextEditingController(text: widget.site.tagline);
    _heroController = TextEditingController(text: widget.site.heroNote);
    _menuNoteController = TextEditingController(text: widget.site.menuNote);
    _aboutTitleController = TextEditingController(text: widget.site.aboutTitle);
  }

  @override
  void dispose() {
    _brandController.dispose();
    _taglineController.dispose();
    _heroController.dispose();
    _menuNoteController.dispose();
    _aboutTitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit brand & public copy'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _requiredField(_brandController, 'Brand name', maxLength: 120),
                _requiredField(_taglineController, 'Tagline', maxLength: 240),
                _requiredField(_heroController, 'Hero note', maxLength: 300),
                _requiredField(
                  _menuNoteController,
                  'Menu note',
                  maxLength: 300,
                  maxLines: 3,
                ),
                _requiredField(
                  _aboutTitleController,
                  'About title',
                  maxLength: 160,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      SiteDraft(
        brandName: _brandController.text.trim(),
        tagline: _taglineController.text.trim(),
        heroNote: _heroController.text.trim(),
        menuNote: _menuNoteController.text.trim(),
        aboutTitle: _aboutTitleController.text.trim(),
      ),
    );
  }
}

class ParagraphEditorDialog extends StatefulWidget {
  const ParagraphEditorDialog({this.paragraph});

  final AdminAboutParagraph? paragraph;

  @override
  State<ParagraphEditorDialog> createState() => _ParagraphEditorDialogState();
}

class _ParagraphEditorDialogState extends State<ParagraphEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bodyController;
  late final TextEditingController _sortController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _bodyController = TextEditingController(text: widget.paragraph?.body ?? '');
    _sortController = TextEditingController(
      text: (widget.paragraph?.sortOrder ?? 10).toString(),
    );
    _active = widget.paragraph?.active ?? true;
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.paragraph == null ? 'New paragraph' : 'Edit paragraph'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _requiredField(
                _bodyController,
                'Paragraph',
                maxLength: 2000,
                minLines: 4,
                maxLines: 8,
              ),
              _sortField(_sortController),
              _activeSwitch(
                value: _active,
                label: 'Visible on public website',
                onChanged: (value) => setState(() => _active = value),
              ),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      ParagraphDraft(
        body: _bodyController.text.trim(),
        sortOrder: int.parse(_sortController.text.trim()),
        active: _active,
      ),
    );
  }
}

class FeatureEditorDialog extends StatefulWidget {
  const FeatureEditorDialog({this.feature});

  final AdminSiteFeature? feature;

  @override
  State<FeatureEditorDialog> createState() => _FeatureEditorDialogState();
}

class _FeatureEditorDialogState extends State<FeatureEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _iconController;
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  late final TextEditingController _sortController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _iconController = TextEditingController(text: widget.feature?.icon ?? '');
    _titleController = TextEditingController(text: widget.feature?.title ?? '');
    _textController = TextEditingController(text: widget.feature?.text ?? '');
    _sortController = TextEditingController(
      text: (widget.feature?.sortOrder ?? 10).toString(),
    );
    _active = widget.feature?.active ?? true;
  }

  @override
  void dispose() {
    _iconController.dispose();
    _titleController.dispose();
    _textController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.feature == null ? 'New feature' : 'Edit feature'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _iconController,
                  decoration: const InputDecoration(labelText: 'Icon / emoji'),
                  maxLength: 32,
                ),
                _requiredField(_titleController, 'Title', maxLength: 120),
                _requiredField(
                  _textController,
                  'Text',
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 5,
                ),
                _sortField(_sortController),
                _activeSwitch(
                  value: _active,
                  label: 'Visible on public website',
                  onChanged: (value) => setState(() => _active = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      FeatureDraft(
        icon: _iconController.text.trim(),
        title: _titleController.text.trim(),
        text: _textController.text.trim(),
        sortOrder: int.parse(_sortController.text.trim()),
        active: _active,
      ),
    );
  }
}

class ContactEditorDialog extends StatefulWidget {
  const ContactEditorDialog({required this.contact});

  final AdminContactProfile contact;

  @override
  State<ContactEditorDialog> createState() => _ContactEditorDialogState();
}

class _ContactEditorDialogState extends State<ContactEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _mapController;
  late final TextEditingController _whatsappNumberController;
  late final TextEditingController _whatsappPrefillController;
  late bool _whatsappEnabled;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.contact.address);
    _phoneController = TextEditingController(text: widget.contact.phone);
    _emailController = TextEditingController(text: widget.contact.email);
    _mapController = TextEditingController(text: widget.contact.mapEmbedUrl);
    _whatsappNumberController = TextEditingController(
      text: widget.contact.whatsappNumber ?? '',
    );
    _whatsappPrefillController = TextEditingController(
      text: widget.contact.whatsappPrefill,
    );
    _whatsappEnabled = widget.contact.whatsappEnabled;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mapController.dispose();
    _whatsappNumberController.dispose();
    _whatsappPrefillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit contact settings'),
      content: SizedBox(
        width: 600,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _requiredField(
                  _addressController,
                  'Address',
                  maxLength: 500,
                  maxLines: 3,
                ),
                _requiredField(_phoneController, 'Phone', maxLength: 80),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 320,
                  validator: _emailValidator,
                ),
                TextFormField(
                  controller: _mapController,
                  decoration: const InputDecoration(labelText: 'Map embed URL'),
                  keyboardType: TextInputType.url,
                  maxLength: 1000,
                  validator: _httpsUrlValidator,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('WhatsApp ordering enabled'),
                  value: _whatsappEnabled,
                  onChanged: (value) => setState(() => _whatsappEnabled = value),
                ),
                TextFormField(
                  controller: _whatsappNumberController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp E.164 number',
                    hintText: '+94771234567',
                  ),
                  keyboardType: TextInputType.phone,
                  maxLength: 32,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (!_whatsappEnabled && text.isEmpty) {
                      return null;
                    }
                    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(text)) {
                      return 'Use E.164 format, e.g. +94771234567.';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _whatsappPrefillController,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp prefilled message',
                  ),
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final number = _whatsappNumberController.text.trim();
    Navigator.of(context).pop(
      ContactDraft(
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        mapEmbedUrl: _mapController.text.trim(),
        whatsappEnabled: _whatsappEnabled,
        whatsappNumber: number.isEmpty ? null : number,
        whatsappPrefill: _whatsappPrefillController.text.trim(),
      ),
    );
  }
}

class OpeningHourEditorDialog extends StatefulWidget {
  const OpeningHourEditorDialog({this.hour});

  final AdminOpeningHour? hour;

  @override
  State<OpeningHourEditorDialog> createState() =>
      _OpeningHourEditorDialogState();
}

class _OpeningHourEditorDialogState extends State<OpeningHourEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dayController;
  late final TextEditingController _timeController;
  late final TextEditingController _sortController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _dayController = TextEditingController(text: widget.hour?.dayLabel ?? '');
    _timeController = TextEditingController(text: widget.hour?.timeLabel ?? '');
    _sortController = TextEditingController(
      text: (widget.hour?.sortOrder ?? 10).toString(),
    );
    _active = widget.hour?.active ?? true;
  }

  @override
  void dispose() {
    _dayController.dispose();
    _timeController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.hour == null ? 'New opening hour' : 'Edit opening hour'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _requiredField(_dayController, 'Day label', maxLength: 120),
              _requiredField(_timeController, 'Time label', maxLength: 120),
              _sortField(_sortController),
              _activeSwitch(
                value: _active,
                label: 'Visible on public website',
                onChanged: (value) => setState(() => _active = value),
              ),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      OpeningHourDraft(
        dayLabel: _dayController.text.trim(),
        timeLabel: _timeController.text.trim(),
        sortOrder: int.parse(_sortController.text.trim()),
        active: _active,
      ),
    );
  }
}

class SocialLinkEditorDialog extends StatefulWidget {
  const SocialLinkEditorDialog({this.link});

  final AdminSocialLink? link;

  @override
  State<SocialLinkEditorDialog> createState() => _SocialLinkEditorDialogState();
}

class _SocialLinkEditorDialogState extends State<SocialLinkEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _platformController;
  late final TextEditingController _urlController;
  late final TextEditingController _sortController;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _platformController = TextEditingController(text: widget.link?.platform ?? '');
    _urlController = TextEditingController(text: widget.link?.url ?? '');
    _sortController = TextEditingController(
      text: (widget.link?.sortOrder ?? 10).toString(),
    );
    _active = widget.link?.active ?? true;
  }

  @override
  void dispose() {
    _platformController.dispose();
    _urlController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.link == null ? 'New social link' : 'Edit social link'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _platformController,
                decoration: const InputDecoration(
                  labelText: 'Platform key',
                  hintText: 'instagram',
                ),
                maxLength: 40,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9-]{0,39}$').hasMatch(text)) {
                    return 'Use letters, numbers or hyphens.';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'HTTPS URL'),
                keyboardType: TextInputType.url,
                maxLength: 1000,
                validator: _httpsUrlValidator,
              ),
              _sortField(_sortController),
              _activeSwitch(
                value: _active,
                label: 'Visible on public website',
                onChanged: (value) => setState(() => _active = value),
              ),
            ],
          ),
        ),
      ),
      actions: _dialogActions(context, _submit),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      SocialLinkDraft(
        platform: _platformController.text.trim().toLowerCase(),
        url: _urlController.text.trim(),
        sortOrder: int.parse(_sortController.text.trim()),
        active: _active,
      ),
    );
  }
}

TextFormField _requiredField(
  TextEditingController controller,
  String label, {
  required int maxLength,
  int? minLines,
  int? maxLines,
}) {
  return TextFormField(
    controller: controller,
    decoration: InputDecoration(labelText: label),
    maxLength: maxLength,
    minLines: minLines,
    maxLines: maxLines ?? 1,
    validator: (value) => value == null || value.trim().isEmpty
        ? '$label is required.'
        : null,
  );
}

TextFormField _sortField(TextEditingController controller) {
  return TextFormField(
    controller: controller,
    decoration: const InputDecoration(labelText: 'Display order'),
    keyboardType: TextInputType.number,
    validator: (value) {
      final parsed = int.tryParse(value?.trim() ?? '');
      return parsed == null || parsed < 0
          ? 'Enter 0 or a positive whole number.'
          : null;
    },
  );
}

SwitchListTile _activeSwitch({
  required bool value,
  required String label,
  required ValueChanged<bool> onChanged,
}) {
  return SwitchListTile.adaptive(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    value: value,
    onChanged: onChanged,
  );
}

List<Widget> _dialogActions(BuildContext context, VoidCallback submit) {
  return <Widget>[
    TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    ),
    FilledButton(onPressed: submit, child: const Text('Save')),
  ];
}

String? _httpsUrlValidator(String? value) {
  final text = value?.trim() ?? '';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    return 'Enter a valid HTTPS URL.';
  }
  return null;
}

String? _emailValidator(String? value) {
  final text = value?.trim() ?? '';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Enter a valid email address.';
  }
  return null;
}

class SiteDraft {
  const SiteDraft({
    required this.brandName,
    required this.tagline,
    required this.heroNote,
    required this.menuNote,
    required this.aboutTitle,
  });

  final String brandName;
  final String tagline;
  final String heroNote;
  final String menuNote;
  final String aboutTitle;
}

class ParagraphDraft {
  const ParagraphDraft({
    required this.body,
    required this.sortOrder,
    required this.active,
  });

  final String body;
  final int sortOrder;
  final bool active;
}

class FeatureDraft {
  const FeatureDraft({
    required this.icon,
    required this.title,
    required this.text,
    required this.sortOrder,
    required this.active,
  });

  final String icon;
  final String title;
  final String text;
  final int sortOrder;
  final bool active;
}

class ContactDraft {
  const ContactDraft({
    required this.address,
    required this.phone,
    required this.email,
    required this.mapEmbedUrl,
    required this.whatsappEnabled,
    required this.whatsappNumber,
    required this.whatsappPrefill,
  });

  final String address;
  final String phone;
  final String email;
  final String mapEmbedUrl;
  final bool whatsappEnabled;
  final String? whatsappNumber;
  final String whatsappPrefill;
}

class OpeningHourDraft {
  const OpeningHourDraft({
    required this.dayLabel,
    required this.timeLabel,
    required this.sortOrder,
    required this.active,
  });

  final String dayLabel;
  final String timeLabel;
  final int sortOrder;
  final bool active;
}

class SocialLinkDraft {
  const SocialLinkDraft({
    required this.platform,
    required this.url,
    required this.sortOrder,
    required this.active,
  });

  final String platform;
  final String url;
  final int sortOrder;
  final bool active;
}
