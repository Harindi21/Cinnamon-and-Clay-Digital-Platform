import 'package:cinnamon_clay_admin/src/auth/auth_controller.dart';
import 'package:cinnamon_clay_admin/src/auth/auth_models.dart';
import 'package:cinnamon_clay_admin/src/reviews/review_models.dart';
import 'package:cinnamon_clay_admin/src/reviews/review_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewsPage extends ConsumerStatefulWidget {
  const ReviewsPage({required this.identity, super.key});

  final AdminIdentity identity;

  @override
  ConsumerState<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends ConsumerState<ReviewsPage> {
  bool _mutating = false;

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(reviewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh reviews',
            onPressed: _mutating ? null : () => ref.invalidate(reviewsProvider),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mutating ? null : () => _createReview(context),
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Review'),
      ),
      body: reviews.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(reviewsProvider);
            await ref.read(reviewsProvider.future);
          },
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(32),
                  children: const <Widget>[
                    SizedBox(height: 120),
                    Icon(Icons.rate_review_outlined, size: 52),
                    SizedBox(height: 16),
                    Text('No reviews yet.', textAlign: TextAlign.center),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final review = items[index];
                    return _ReviewCard(
                      review: review,
                      disabled: _mutating,
                      onEdit: () => _editReview(context, review),
                      onHide: () => _hideReview(context, review),
                    );
                  },
                ),
        ),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.cloud_off_outlined, size: 42),
                const SizedBox(height: 12),
                Text(
                  error is ReviewMutationException
                      ? error.message
                      : 'Could not load reviews.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(reviewsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _createReview(BuildContext context) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (context) => const _ReviewEditorDialog(),
    );
    if (draft == null || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Review created.',
      operation: () => ref
          .read(reviewRepositoryProvider)
          .create(
            authorName: draft.authorName,
            body: draft.body,
            rating: draft.rating,
            status: draft.status,
            sortOrder: draft.sortOrder,
          ),
    );
  }

  Future<void> _editReview(BuildContext context, AdminReview review) async {
    final draft = await showDialog<_ReviewDraft>(
      context: context,
      builder: (context) => _ReviewEditorDialog(review: review),
    );
    if (draft == null || !mounted) {
      return;
    }

    final updated = AdminReview(
      id: review.id,
      authorName: draft.authorName,
      body: draft.body,
      rating: draft.rating,
      status: draft.status,
      sortOrder: draft.sortOrder,
      version: review.version,
      publishedAt: review.publishedAt,
    );

    await _runMutation(
      successMessage: draft.status == ReviewStatus.published
          ? 'Review published.'
          : 'Review updated.',
      operation: () => ref.read(reviewRepositoryProvider).update(updated),
    );
  }

  Future<void> _hideReview(BuildContext context, AdminReview review) async {
    if (review.status == ReviewStatus.hidden) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Hide review by ${review.authorName}?'),
            content: const Text(
              'The review will stop appearing on the public website. '
              'It remains available here and can be published again later.',
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
        ) ??
        false;

    if (!confirmed || !mounted) {
      return;
    }

    await _runMutation(
      successMessage: 'Review hidden.',
      operation: () => ref.read(reviewRepositoryProvider).hide(review),
    );
  }

  Future<void> _runMutation({
    required String successMessage,
    required Future<Object?> Function() operation,
  }) async {
    setState(() => _mutating = true);
    try {
      await operation();
      ref.invalidate(reviewsProvider);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
    } on ReviewMutationException catch (error) {
      ref.invalidate(reviewsProvider);
      if (!mounted) {
        return;
      }
      final message = error.isConflict
          ? '${error.message} Reviews have been refreshed.'
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.disabled,
    required this.onEdit,
    required this.onHide,
  });

  final AdminReview review;
  final bool disabled;
  final VoidCallback onEdit;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    review.authorName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(label: Text(review.status.label)),
              ],
            ),
            Text(
              _stars(review.rating),
              semanticsLabel: '${review.rating} out of 5 stars',
            ),
            const SizedBox(height: 10),
            Text(review.body),
            const SizedBox(height: 10),
            Text(
              'order ${review.sortOrder} • v${review.version}'
              '${review.publishedAt == null ? '' : ' • published ${_date(review.publishedAt!)}'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: <Widget>[
                TextButton.icon(
                  onPressed: disabled ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                if (review.status != ReviewStatus.hidden)
                  TextButton.icon(
                    onPressed: disabled ? null : onHide,
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

class _ReviewEditorDialog extends StatefulWidget {
  const _ReviewEditorDialog({this.review});

  final AdminReview? review;

  @override
  State<_ReviewEditorDialog> createState() => _ReviewEditorDialogState();
}

class _ReviewEditorDialogState extends State<_ReviewEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _authorController;
  late final TextEditingController _bodyController;
  late final TextEditingController _sortController;
  late int _rating;
  late ReviewStatus _status;

  @override
  void initState() {
    super.initState();
    final review = widget.review;
    _authorController = TextEditingController(text: review?.authorName ?? '');
    _bodyController = TextEditingController(text: review?.body ?? '');
    _sortController = TextEditingController(
      text: (review?.sortOrder ?? 10).toString(),
    );
    _rating = review?.rating ?? 5;
    _status = review?.status ?? ReviewStatus.draft;
  }

  @override
  void dispose() {
    _authorController.dispose();
    _bodyController.dispose();
    _sortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.review == null ? 'New review' : 'Edit review'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _authorController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Author name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter an author name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyController,
                  decoration: const InputDecoration(labelText: 'Review'),
                  minLines: 3,
                  maxLines: 6,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter review text.'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _rating,
                        decoration: const InputDecoration(labelText: 'Rating'),
                        items: List<DropdownMenuItem<int>>.generate(
                          5,
                          (index) => DropdownMenuItem<int>(
                            value: index + 1,
                            child: Text('${index + 1} stars'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _rating = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ReviewStatus>(
                        initialValue: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ReviewStatus.values
                            .map(
                              (status) => DropdownMenuItem<ReviewStatus>(
                                value: status,
                                child: Text(status.label),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sortController,
                  decoration: const InputDecoration(labelText: 'Display order'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final parsed = int.tryParse(value?.trim() ?? '');
                    return parsed == null || parsed < 0
                        ? 'Enter 0 or a positive whole number.'
                        : null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _ReviewDraft(
        authorName: _authorController.text.trim(),
        body: _bodyController.text.trim(),
        rating: _rating,
        status: _status,
        sortOrder: int.parse(_sortController.text.trim()),
      ),
    );
  }
}

class _ReviewDraft {
  const _ReviewDraft({
    required this.authorName,
    required this.body,
    required this.rating,
    required this.status,
    required this.sortOrder,
  });

  final String authorName;
  final String body;
  final int rating;
  final ReviewStatus status;
  final int sortOrder;
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

String _stars(int rating) {
  return '${List<String>.filled(rating, '★').join()}${List<String>.filled(5 - rating, '☆').join()}';
}
