class SiteSettingsSnapshot {
  const SiteSettingsSnapshot({
    required this.site,
    required this.paragraphs,
    required this.features,
    required this.contact,
    required this.hours,
    required this.socialLinks,
  });

  final AdminSiteProfile site;
  final List<AdminAboutParagraph> paragraphs;
  final List<AdminSiteFeature> features;
  final AdminContactProfile contact;
  final List<AdminOpeningHour> hours;
  final List<AdminSocialLink> socialLinks;
}

class AdminSiteProfile {
  const AdminSiteProfile({
    required this.id,
    required this.brandName,
    required this.tagline,
    required this.heroNote,
    required this.menuNote,
    required this.aboutTitle,
    required this.version,
  });

  final String id;
  final String brandName;
  final String tagline;
  final String heroNote;
  final String menuNote;
  final String aboutTitle;
  final int version;

  factory AdminSiteProfile.fromJson(Map<String, dynamic> json) {
    return AdminSiteProfile(
      id: json['id'] as String,
      brandName: json['brandName'] as String,
      tagline: json['tagline'] as String,
      heroNote: json['heroNote'] as String,
      menuNote: json['menuNote'] as String,
      aboutTitle: json['aboutTitle'] as String,
      version: json['version'] as int,
    );
  }
}

class AdminAboutParagraph {
  const AdminAboutParagraph({
    required this.id,
    required this.body,
    required this.sortOrder,
    required this.active,
    required this.version,
  });

  final String id;
  final String body;
  final int sortOrder;
  final bool active;
  final int version;

  factory AdminAboutParagraph.fromJson(Map<String, dynamic> json) {
    return AdminAboutParagraph(
      id: json['id'] as String,
      body: json['body'] as String,
      sortOrder: json['sortOrder'] as int,
      active: json['active'] as bool,
      version: json['version'] as int,
    );
  }
}

class AdminSiteFeature {
  const AdminSiteFeature({
    required this.id,
    required this.icon,
    required this.title,
    required this.text,
    required this.sortOrder,
    required this.active,
    required this.version,
  });

  final String id;
  final String icon;
  final String title;
  final String text;
  final int sortOrder;
  final bool active;
  final int version;

  factory AdminSiteFeature.fromJson(Map<String, dynamic> json) {
    return AdminSiteFeature(
      id: json['id'] as String,
      icon: json['icon'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      sortOrder: json['sortOrder'] as int,
      active: json['active'] as bool,
      version: json['version'] as int,
    );
  }
}

class AdminContactProfile {
  const AdminContactProfile({
    required this.id,
    required this.address,
    required this.phone,
    required this.email,
    required this.mapEmbedUrl,
    required this.whatsappEnabled,
    required this.whatsappPrefill,
    required this.version,
    this.whatsappNumber,
  });

  final String id;
  final String address;
  final String phone;
  final String email;
  final String mapEmbedUrl;
  final bool whatsappEnabled;
  final String? whatsappNumber;
  final String whatsappPrefill;
  final int version;

  factory AdminContactProfile.fromJson(Map<String, dynamic> json) {
    return AdminContactProfile(
      id: json['id'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      mapEmbedUrl: json['mapEmbedUrl'] as String,
      whatsappEnabled: json['whatsappEnabled'] as bool,
      whatsappNumber: json['whatsappNumber'] as String?,
      whatsappPrefill: json['whatsappPrefill'] as String,
      version: json['version'] as int,
    );
  }
}

class AdminOpeningHour {
  const AdminOpeningHour({
    required this.id,
    required this.dayLabel,
    required this.timeLabel,
    required this.sortOrder,
    required this.active,
    required this.version,
  });

  final String id;
  final String dayLabel;
  final String timeLabel;
  final int sortOrder;
  final bool active;
  final int version;

  factory AdminOpeningHour.fromJson(Map<String, dynamic> json) {
    return AdminOpeningHour(
      id: json['id'] as String,
      dayLabel: json['dayLabel'] as String,
      timeLabel: json['timeLabel'] as String,
      sortOrder: json['sortOrder'] as int,
      active: json['active'] as bool,
      version: json['version'] as int,
    );
  }
}

class AdminSocialLink {
  const AdminSocialLink({
    required this.id,
    required this.platform,
    required this.url,
    required this.sortOrder,
    required this.active,
    required this.version,
  });

  final String id;
  final String platform;
  final String url;
  final int sortOrder;
  final bool active;
  final int version;

  factory AdminSocialLink.fromJson(Map<String, dynamic> json) {
    return AdminSocialLink(
      id: json['id'] as String,
      platform: json['platform'] as String,
      url: json['url'] as String,
      sortOrder: json['sortOrder'] as int,
      active: json['active'] as bool,
      version: json['version'] as int,
    );
  }
}

class SiteSettingsMutationException implements Exception {
  const SiteSettingsMutationException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}
