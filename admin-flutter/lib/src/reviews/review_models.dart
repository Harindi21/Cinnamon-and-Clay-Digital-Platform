enum ReviewStatus {
  draft,
  published,
  hidden;

  String get apiValue => name.toUpperCase();

  String get label => switch (this) {
    ReviewStatus.draft => 'Draft',
    ReviewStatus.published => 'Published',
    ReviewStatus.hidden => 'Hidden',
  };

  static ReviewStatus fromApi(String value) {
    return ReviewStatus.values.firstWhere(
      (status) => status.apiValue == value.toUpperCase(),
    );
  }
}

class AdminReview {
  const AdminReview({
    required this.id,
    required this.authorName,
    required this.body,
    required this.rating,
    required this.status,
    required this.sortOrder,
    required this.version,
    this.publishedAt,
  });

  final String id;
  final String authorName;
  final String body;
  final int rating;
  final ReviewStatus status;
  final int sortOrder;
  final DateTime? publishedAt;
  final int version;

  factory AdminReview.fromJson(Map<String, dynamic> json) => AdminReview(
    id: json['id'] as String,
    authorName: json['authorName'] as String,
    body: json['body'] as String,
    rating: json['rating'] as int,
    status: ReviewStatus.fromApi(json['status'] as String),
    sortOrder: json['sortOrder'] as int,
    publishedAt: json['publishedAt'] == null
        ? null
        : DateTime.parse(json['publishedAt'] as String).toLocal(),
    version: json['version'] as int,
  );
}

class ReviewMutationException implements Exception {
  const ReviewMutationException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  bool get isConflict => statusCode == 409;

  @override
  String toString() => message;
}
