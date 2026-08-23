import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/site_settings/site_settings_editors.dart';
import 'package:cinnamon_clay_admin/src/site_settings/site_settings_models.dart';
import 'package:cinnamon_clay_admin/src/site_settings/site_settings_repository.dart';
import 'package:cinnamon_clay_admin/src/site_settings/site_settings_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SiteSettingsPage extends ConsumerStatefulWidget {
  const SiteSettingsPage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  ConsumerState<SiteSettingsPage> createState() => _SiteSettingsPageState();
}

class _SiteSettingsPageState extends ConsumerState<SiteSettingsPage> {
  bool _mutating = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(siteSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Site settings'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh site settings',
            onPressed: _mutating
                ? null
                : () => ref.invalidate(siteSettingsProvider),
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
            ? const PreferredSize(
                preferredSize: Size.fromHeight(3),
                child: LinearProgressIndicator(minHeight: 3),
              )
            : null,
      ),
      body: settings.when(
        data: (snapshot) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(siteSettingsProvider);
            await ref.read(siteSettingsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            children: <Widget>[
              SiteSettingsSectionHeader(
                title: 'Brand & public copy',
                subtitle:
                    'Business-managed copy. Theme and layout remain in Next.js.',
                actionLabel: 'Edit',
                actionIcon: Icons.edit_outlined,
                onAction: _mutating
                    ? null
                    : () => _editSite(context, snapshot.site),
              ),
              SiteProfileCard(site: snapshot.site),
              const SizedBox(height: 28),
              SiteSettingsSectionHeader(
                title: 'About paragraphs',
                subtitle: 'Ordered copy displayed in the public About section.',
                actionLabel: 'Add',
                actionIcon: Icons.add,
                onAction: _mutating
                    ? null
                    : () => _createParagraph(context),
              ),
              ...snapshot.paragraphs.map(
                (paragraph) => ManagedSettingsCard(
                  title: 'Paragraph · order ${paragraph.sortOrder}',
                  body: paragraph.body,
                  active: paragraph.active,
                  version: paragraph.version,
                  onEdit: _mutating
                      ? null
                      : () => _editParagraph(context, paragraph),
                  onDeactivate: !_mutating && paragraph.active
                      ? () => _deactivateParagraph(context, paragraph)
                      : null,
                ),
              ),
              const SizedBox(height: 28),
              SiteSettingsSectionHeader(
                title: 'Feature highlights',
                subtitle: 'Small benefit cards shown below the About copy.',
                actionLabel: 'Add',
                actionIcon: Icons.add,
                onAction: _mutating ? null : () => _createFeature(context),
              ),
              ...snapshot.features.map(
                (feature) => ManagedSettingsCard(
                  title:
                      '${feature.icon.isEmpty ? '•' : feature.icon} ${feature.title} · order ${feature.sortOrder}',
                  body: feature.text,
                  active: feature.active,
                  version: feature.version,
                  onEdit: _mutating
                      ? null
                      : () => _editFeature(context, feature),
                  onDeactivate: !_mutating && feature.active
                      ? () => _deactivateFeature(context, feature)
                      : null,
                ),
              ),
              const SizedBox(height: 28),
              SiteSettingsSectionHeader(
                title: 'Contact & WhatsApp',
                subtitle:
                    'Public address, contact channels, map embed and ordering CTA.',
                actionLabel: 'Edit',
                actionIcon: Icons.edit_outlined,
                onAction: _mutating
                    ? null
                    : () => _editContact(context, snapshot.contact),
              ),
              ContactProfileCard(contact: snapshot.contact),
              const SizedBox(height: 28),
              SiteSettingsSectionHeader(
                title: 'Opening hours',
                subtitle: 'Ordered labels displayed on the public website.',
                actionLabel: 'Add',
                actionIcon: Icons.add,
                onAction: _mutating ? null : () => _createHour(context),
              ),
              ...snapshot.hours.map(
                (hour) => ManagedSettingsCard(
                  title: '${hour.dayLabel} · order ${hour.sortOrder}',
                  body: hour.timeLabel,
                  active: hour.active,
                  version: hour.version,
                  onEdit: _mutating ? null : () => _editHour(context, hour),
                  onDeactivate: !_mutating && hour.active
                      ? () => _deactivateHour(context, hour)
                      : null,
                ),
              ),
              const SizedBox(height: 28),
              SiteSettingsSectionHeader(
                title: 'Social links',
                subtitle: 'HTTPS links exposed in the public Visit section.',
                actionLabel: 'Add',
                actionIcon: Icons.add,
                onAction: _mutating
                    ? null
                    : () => _createSocialLink(context),
              ),
              ...snapshot.socialLinks.map(
                (link) => ManagedSettingsCard(
                  title: '${link.platform} · order ${link.sortOrder}',
                  body: link.url,
                  active: link.active,
                  version: link.version,
                  onEdit: _mutating
                      ? null
                      : () => _editSocialLink(context, link),
                  onDeactivate: !_mutating && link.active
                      ? () => _deactivateSocialLink(context, link)
                      : null,
                ),
              ),
            ],
          ),
        ),
        error: (error, stackTrace) => SiteSettingsError(
          error: error,
          onRetry: () => ref.invalidate(siteSettingsProvider),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _editSite(BuildContext context, AdminSiteProfile site) async {
    final draft = await showDialog<SiteDraft>(
      context: context,
      builder: (context) => SiteEditorDialog(site: site),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Brand and public copy updated.',
      operation: () => ref.read(siteSettingsRepositoryProvider).updateSite(
        current: site,
        brandName: draft.brandName,
        tagline: draft.tagline,
        heroNote: draft.heroNote,
        menuNote: draft.menuNote,
        aboutTitle: draft.aboutTitle,
      ),
    );
  }

  Future<void> _createParagraph(BuildContext context) async {
    final draft = await showDialog<ParagraphDraft>(
      context: context,
      builder: (context) => const ParagraphEditorDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'About paragraph created.',
      operation: () => ref.read(siteSettingsRepositoryProvider).createParagraph(
        body: draft.body,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _editParagraph(
    BuildContext context,
    AdminAboutParagraph paragraph,
  ) async {
    final draft = await showDialog<ParagraphDraft>(
      context: context,
      builder: (context) => ParagraphEditorDialog(paragraph: paragraph),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'About paragraph updated.',
      operation: () => ref.read(siteSettingsRepositoryProvider).updateParagraph(
        current: paragraph,
        body: draft.body,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _deactivateParagraph(
    BuildContext context,
    AdminAboutParagraph paragraph,
  ) async {
    if (!await _confirmHide(
      context,
      title: 'Hide this paragraph?',
      message: 'It will stop appearing on the public website but can be '
          'reactivated by editing it later.',
    )) {
      return;
    }
    await _runMutation(
      successMessage: 'About paragraph hidden.',
      operation: () => ref
          .read(siteSettingsRepositoryProvider)
          .deactivateParagraph(paragraph),
    );
  }

  Future<void> _createFeature(BuildContext context) async {
    final draft = await showDialog<FeatureDraft>(
      context: context,
      builder: (context) => const FeatureEditorDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Feature created.',
      operation: () => ref.read(siteSettingsRepositoryProvider).createFeature(
        icon: draft.icon,
        title: draft.title,
        text: draft.text,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _editFeature(
    BuildContext context,
    AdminSiteFeature feature,
  ) async {
    final draft = await showDialog<FeatureDraft>(
      context: context,
      builder: (context) => FeatureEditorDialog(feature: feature),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Feature updated.',
      operation: () => ref.read(siteSettingsRepositoryProvider).updateFeature(
        current: feature,
        icon: draft.icon,
        title: draft.title,
        text: draft.text,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _deactivateFeature(
    BuildContext context,
    AdminSiteFeature feature,
  ) async {
    if (!await _confirmHide(
      context,
      title: 'Hide ${feature.title}?',
      message: 'The feature will stop appearing on the public website.',
    )) {
      return;
    }
    await _runMutation(
      successMessage: 'Feature hidden.',
      operation: () => ref
          .read(siteSettingsRepositoryProvider)
          .deactivateFeature(feature),
    );
  }

  Future<void> _editContact(
    BuildContext context,
    AdminContactProfile contact,
  ) async {
    final draft = await showDialog<ContactDraft>(
      context: context,
      builder: (context) => ContactEditorDialog(contact: contact),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Contact settings updated.',
      operation: () => ref.read(siteSettingsRepositoryProvider).updateContact(
        current: contact,
        address: draft.address,
        phone: draft.phone,
        email: draft.email,
        mapEmbedUrl: draft.mapEmbedUrl,
        whatsappEnabled: draft.whatsappEnabled,
        whatsappNumber: draft.whatsappNumber,
        whatsappPrefill: draft.whatsappPrefill,
      ),
    );
  }

  Future<void> _createHour(BuildContext context) async {
    final draft = await showDialog<OpeningHourDraft>(
      context: context,
      builder: (context) => const OpeningHourEditorDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Opening hour created.',
      operation: () => ref.read(siteSettingsRepositoryProvider).createHour(
        dayLabel: draft.dayLabel,
        timeLabel: draft.timeLabel,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _editHour(
    BuildContext context,
    AdminOpeningHour hour,
  ) async {
    final draft = await showDialog<OpeningHourDraft>(
      context: context,
      builder: (context) => OpeningHourEditorDialog(hour: hour),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Opening hour updated.',
      operation: () => ref.read(siteSettingsRepositoryProvider).updateHour(
        current: hour,
        dayLabel: draft.dayLabel,
        timeLabel: draft.timeLabel,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _deactivateHour(
    BuildContext context,
    AdminOpeningHour hour,
  ) async {
    if (!await _confirmHide(
      context,
      title: 'Hide ${hour.dayLabel}?',
      message: 'This row will stop appearing in public opening hours.',
    )) {
      return;
    }
    await _runMutation(
      successMessage: 'Opening hour hidden.',
      operation: () => ref
          .read(siteSettingsRepositoryProvider)
          .deactivateHour(hour),
    );
  }

  Future<void> _createSocialLink(BuildContext context) async {
    final draft = await showDialog<SocialLinkDraft>(
      context: context,
      builder: (context) => const SocialLinkEditorDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Social link created.',
      operation: () => ref.read(siteSettingsRepositoryProvider).createSocialLink(
        platform: draft.platform,
        url: draft.url,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _editSocialLink(
    BuildContext context,
    AdminSocialLink link,
  ) async {
    final draft = await showDialog<SocialLinkDraft>(
      context: context,
      builder: (context) => SocialLinkEditorDialog(link: link),
    );
    if (draft == null || !mounted) {
      return;
    }
    await _runMutation(
      successMessage: 'Social link updated.',
      operation: () => ref.read(siteSettingsRepositoryProvider).updateSocialLink(
        current: link,
        platform: draft.platform,
        url: draft.url,
        sortOrder: draft.sortOrder,
        active: draft.active,
      ),
    );
  }

  Future<void> _deactivateSocialLink(
    BuildContext context,
    AdminSocialLink link,
  ) async {
    if (!await _confirmHide(
      context,
      title: 'Hide ${link.platform}?',
      message: 'The link will stop appearing on the public website.',
    )) {
      return;
    }
    await _runMutation(
      successMessage: 'Social link hidden.',
      operation: () => ref
          .read(siteSettingsRepositoryProvider)
          .deactivateSocialLink(link),
    );
  }

  Future<bool> _confirmHide(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
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
        ) ??
        false;
  }

  Future<void> _runMutation({
    required String successMessage,
    required Future<Object?> Function() operation,
  }) async {
    setState(() => _mutating = true);
    try {
      await operation();
      ref.invalidate(siteSettingsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } on SiteSettingsMutationException catch (error) {
      ref.invalidate(siteSettingsProvider);
      if (!mounted) {
        return;
      }
      final message = error.isConflict
          ? '${error.message} Site settings have been refreshed.'
          : error.message;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _mutating = false);
      }
    }
  }
}
