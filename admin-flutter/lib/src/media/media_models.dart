enum MediaPurpose {
  hero('HERO', 'Hero'),
  about('ABOUT', 'About'),
  gallery('GALLERY', 'Gallery');

  const MediaPurpose(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static MediaPurpose fromApi(String value) {
    return switch (value) {
      'HERO' => MediaPurpose.hero,
      'ABOUT' => MediaPurpose.about,
      'GALLERY' => MediaPurpose.gallery,
      _ => throw FormatException('Unsupported media purpose: $value'),
    };
  }
}

class AdminMediaAsset {
  const AdminMediaAsset({
    required this.id,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
    required this.purpose,
    required this.altText,
    required this.sortOrder,
    required this.active,
    required this.widthPixels,
    required this.heightPixels,
    required this.checksumSha256,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
    required this.contentUrl,
  });

  factory AdminMediaAsset.fromJson(Map<String, dynamic> json) {
    return AdminMediaAsset(
      id: json['id'] as String? ?? '',
      originalFilename: json['originalFilename'] as String? ?? '',
      contentType: json['contentType'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      purpose: MediaPurpose.fromApi(json['purpose'] as String? ?? 'GALLERY'),
      altText: json['altText'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] as bool? ?? false,
      widthPixels: (json['widthPixels'] as num?)?.toInt(),
      heightPixels: (json['heightPixels'] as num?)?.toInt(),
      checksumSha256: json['checksumSha256'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      contentUrl: json['contentUrl'] as String? ?? '',
    );
  }

  final String id;
  final String originalFilename;
  final String contentType;
  final int sizeBytes;
  final MediaPurpose purpose;
  final String altText;
  final int sortOrder;
  final bool active;
  final int? widthPixels;
  final int? heightPixels;
  final String? checksumSha256;
  final int version;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String contentUrl;

  String get dimensionsLabel {
    final width = widthPixels;
    final height = heightPixels;
    if (width == null || height == null) {
      return 'Dimensions unavailable';
    }
    return '$width x $height px';
  }

  String get sizeLabel {
    if (sizeBytes >= 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '$sizeBytes B';
  }
}

class MediaSnapshot {
  const MediaSnapshot(this.assets);

  final List<AdminMediaAsset> assets;

  List<AdminMediaAsset> forPurpose(MediaPurpose purpose) {
    return assets
        .where((asset) => asset.purpose == purpose)
        .toList(growable: false);
  }
}

class MediaMutationException implements Exception {
  const MediaMutationException({
    required this.message,
    this.statusCode,
    this.isConflict = false,
  });

  final String message;
  final int? statusCode;
  final bool isConflict;

  @override
  String toString() => message;
}

class MediaDraft {
  const MediaDraft({
    required this.purpose,
    required this.altText,
    required this.sortOrder,
    required this.active,
  });

  final MediaPurpose purpose;
  final String altText;
  final int sortOrder;
  final bool active;
}

class OrphanReport {
  const OrphanReport({
    required this.count,
    required this.gracePeriod,
    required this.objectKeys,
  });

  factory OrphanReport.fromJson(Map<String, dynamic> json) {
    return OrphanReport(
      count: (json['count'] as num?)?.toInt() ?? 0,
      gracePeriod: json['gracePeriod'] as String? ?? '',
      objectKeys: (json['objectKeys'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(growable: false),
    );
  }

  final int count;
  final String gracePeriod;
  final List<String> objectKeys;
}

class OrphanCleanupResult {
  const OrphanCleanupResult({
    required this.discovered,
    required this.deleted,
    required this.failed,
  });

  factory OrphanCleanupResult.fromJson(Map<String, dynamic> json) {
    return OrphanCleanupResult(
      discovered: (json['discovered'] as num?)?.toInt() ?? 0,
      deleted: (json['deleted'] as num?)?.toInt() ?? 0,
      failed: (json['failed'] as num?)?.toInt() ?? 0,
    );
  }

  final int discovered;
  final int deleted;
  final int failed;
}
