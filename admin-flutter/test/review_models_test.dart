import 'package:cinnamon_clay_admin/src/reviews/review_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses administrator review status and version', () {
    final review = AdminReview.fromJson(<String, dynamic>{
      'id': 'review-1',
      'authorName': 'Guest',
      'body': 'Great coffee.',
      'rating': 5,
      'status': 'PUBLISHED',
      'sortOrder': 10,
      'publishedAt': '2026-08-23T10:00:00Z',
      'version': 4,
    });

    expect(review.status, ReviewStatus.published);
    expect(review.rating, 5);
    expect(review.version, 4);
    expect(review.publishedAt, isNotNull);
  });

  test('review statuses preserve api values', () {
    expect(ReviewStatus.draft.apiValue, 'DRAFT');
    expect(ReviewStatus.published.apiValue, 'PUBLISHED');
    expect(ReviewStatus.hidden.apiValue, 'HIDDEN');
  });
}
