import 'package:cinnamon_clay_admin/src/site_settings/site_settings_models.dart';
import 'package:flutter/material.dart';

class SiteSettingsSectionHeader extends StatelessWidget {
  const SiteSettingsSectionHeader({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    super.key,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class SiteProfileCard extends StatelessWidget {
  const SiteProfileCard({required this.site, super.key});

  final AdminSiteProfile site;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              site.brandName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(site.tagline),
            const SizedBox(height: 8),
            Text('Hero: ${site.heroNote}'),
            const SizedBox(height: 8),
            Text('Menu note: ${site.menuNote}'),
            const SizedBox(height: 8),
            Text('About title: ${site.aboutTitle}'),
            const SizedBox(height: 10),
            Text(
              'v${site.version}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class ContactProfileCard extends StatelessWidget {
  const ContactProfileCard({required this.contact, super.key});

  final AdminContactProfile contact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(contact.address),
            const SizedBox(height: 6),
            Text('${contact.phone} · ${contact.email}'),
            const SizedBox(height: 6),
            Text(contact.mapEmbedUrl),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                SettingsStatusChip(active: contact.whatsappEnabled),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    contact.whatsappEnabled
                        ? 'WhatsApp ${contact.whatsappNumber ?? ''}'
                        : 'WhatsApp disabled',
                  ),
                ),
                Text('v${contact.version}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ManagedSettingsCard extends StatelessWidget {
  const ManagedSettingsCard({
    required this.title,
    required this.body,
    required this.active,
    required this.version,
    required this.onEdit,
    required this.onDeactivate,
    super.key,
  });

  final String title;
  final String body;
  final bool active;
  final int version;
  final VoidCallback? onEdit;
  final VoidCallback? onDeactivate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                SettingsStatusChip(active: active),
              ],
            ),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text('v$version', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                if (active)
                  TextButton.icon(
                    onPressed: onDeactivate,
                    icon: const Icon(Icons.visibility_off_outlined),
                    label: const Text('Hide'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsStatusChip extends StatelessWidget {
  const SettingsStatusChip({required this.active, super.key});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(active ? 'Active' : 'Hidden'));
  }
}

class SiteSettingsError extends StatelessWidget {
  const SiteSettingsError({
    required this.error,
    required this.onRetry,
    super.key,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is SiteSettingsMutationException
        ? (error as SiteSettingsMutationException).message
        : 'Could not load site settings.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.cloud_off_outlined, size: 42),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
