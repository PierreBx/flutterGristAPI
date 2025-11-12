import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

/// A rating field widget for star ratings.
///
/// Features:
/// - Star rating (1-5 or custom range)
/// - Half-star support
/// - Custom icons (star, heart, thumb, etc.)
/// - Custom colors
/// - Read-only mode for display
/// - Size customization
/// - Rating labels
class RatingFieldWidget extends StatefulWidget {
  /// Field label
  final String label;

  /// Initial rating value (0.0 - maxRating)
  final double? value;

  /// Callback when rating changes
  final ValueChanged<double>? onChanged;

  /// Whether the field is read-only
  final bool readOnly;

  /// Maximum rating value
  final double maxRating;

  /// Minimum rating value
  final double minRating;

  /// Whether to allow half ratings
  final bool allowHalfRating;

  /// Icon to use for rating
  final RatingIcon icon;

  /// Size of the rating icons
  final double iconSize;

  /// Color for filled icons
  final Color? ratedColor;

  /// Color for unfilled icons
  final Color? unratedColor;

  /// Whether to show the rating value as text
  final bool showRatingValue;

  /// Custom rating labels (optional)
  final Map<int, String>? ratingLabels;

  /// Glow effect when hovering
  final bool glowEffect;

  const RatingFieldWidget({
    Key? key,
    required this.label,
    this.value,
    this.onChanged,
    this.readOnly = false,
    this.maxRating = 5.0,
    this.minRating = 0.0,
    this.allowHalfRating = true,
    this.icon = RatingIcon.star,
    this.iconSize = 40,
    this.ratedColor,
    this.unratedColor,
    this.showRatingValue = true,
    this.ratingLabels,
    this.glowEffect = true,
  }) : super(key: key);

  @override
  State<RatingFieldWidget> createState() => _RatingFieldWidgetState();
}

class _RatingFieldWidgetState extends State<RatingFieldWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.value ?? 0.0;
  }

  @override
  void didUpdateWidget(RatingFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      setState(() {
        _currentRating = widget.value ?? 0.0;
      });
    }
  }

  IconData _getIconData() {
    switch (widget.icon) {
      case RatingIcon.star:
        return Icons.star;
      case RatingIcon.heart:
        return Icons.favorite;
      case RatingIcon.thumb:
        return Icons.thumb_up;
      case RatingIcon.circle:
        return Icons.circle;
      case RatingIcon.square:
        return Icons.square;
    }
  }

  IconData _getBorderIconData() {
    switch (widget.icon) {
      case RatingIcon.star:
        return Icons.star_border;
      case RatingIcon.heart:
        return Icons.favorite_border;
      case RatingIcon.thumb:
        return Icons.thumb_up_outlined;
      case RatingIcon.circle:
        return Icons.circle_outlined;
      case RatingIcon.square:
        return Icons.square_outlined;
    }
  }

  String? _getRatingLabel(double rating) {
    if (widget.ratingLabels == null) return null;
    final roundedRating = rating.round();
    return widget.ratingLabels![roundedRating];
  }

  @override
  Widget build(BuildContext context) {
    final ratedColor = widget.ratedColor ?? Theme.of(context).colorScheme.primary;
    final unratedColor = widget.unratedColor ?? Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty) ...[
          Text(
            widget.label,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          SizedBox(height: 8),
        ],

        // Rating bar
        Row(
          children: [
            RatingBar(
              initialRating: _currentRating,
              minRating: widget.minRating,
              maxRating: widget.maxRating,
              allowHalfRating: widget.allowHalfRating,
              ignoreGestures: widget.readOnly,
              glow: widget.glowEffect,
              glowColor: ratedColor,
              itemSize: widget.iconSize,
              ratingWidget: RatingWidget(
                full: Icon(_getIconData(), color: ratedColor),
                half: Icon(
                  _getIconData(),
                  color: ratedColor.withOpacity(0.5),
                ),
                empty: Icon(_getBorderIconData(), color: unratedColor),
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _currentRating = rating;
                });

                if (widget.onChanged != null && !widget.readOnly) {
                  widget.onChanged!(rating);
                }
              },
            ),

            // Rating value
            if (widget.showRatingValue) ...[
              SizedBox(width: 12),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _currentRating.toStringAsFixed(widget.allowHalfRating ? 1 : 0),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ],
        ),

        // Rating label
        if (_getRatingLabel(_currentRating) != null) ...[
          SizedBox(height: 8),
          Text(
            _getRatingLabel(_currentRating)!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ratedColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }
}

/// Rating icon types
enum RatingIcon {
  star,
  heart,
  thumb,
  circle,
  square,
}

/// Compact rating widget for display only
class CompactRatingWidget extends StatelessWidget {
  final String label;
  final double? value;
  final double maxRating;
  final RatingIcon icon;
  final double iconSize;
  final Color? color;

  const CompactRatingWidget({
    Key? key,
    required this.label,
    this.value,
    this.maxRating = 5.0,
    this.icon = RatingIcon.star,
    this.iconSize = 20,
    this.color,
  }) : super(key: key);

  IconData _getIconData() {
    switch (icon) {
      case RatingIcon.star:
        return Icons.star;
      case RatingIcon.heart:
        return Icons.favorite;
      case RatingIcon.thumb:
        return Icons.thumb_up;
      case RatingIcon.circle:
        return Icons.circle;
      case RatingIcon.square:
        return Icons.square;
    }
  }

  IconData _getBorderIconData() {
    switch (icon) {
      case RatingIcon.star:
        return Icons.star_border;
      case RatingIcon.heart:
        return Icons.favorite_border;
      case RatingIcon.thumb:
        return Icons.thumb_up_outlined;
      case RatingIcon.circle:
        return Icons.circle_outlined;
      case RatingIcon.square:
        return Icons.square_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = value ?? 0.0;
    final ratedColor = color ?? Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(width: 8),
        ],
        RatingBarIndicator(
          rating: rating,
          itemSize: iconSize,
          itemBuilder: (context, index) {
            return Icon(
              index < rating ? _getIconData() : _getBorderIconData(),
              color: index < rating ? ratedColor : Colors.grey.shade300,
            );
          },
        ),
        SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Rating labels presets
class RatingLabels {
  static const Map<int, String> satisfaction = {
    0: 'Not rated',
    1: 'Very Dissatisfied',
    2: 'Dissatisfied',
    3: 'Neutral',
    4: 'Satisfied',
    5: 'Very Satisfied',
  };

  static const Map<int, String> quality = {
    0: 'Not rated',
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Very Good',
    5: 'Excellent',
  };

  static const Map<int, String> agreement = {
    0: 'Not rated',
    1: 'Strongly Disagree',
    2: 'Disagree',
    3: 'Neutral',
    4: 'Agree',
    5: 'Strongly Agree',
  };

  static const Map<int, String> likelihood = {
    0: 'Not rated',
    1: 'Very Unlikely',
    2: 'Unlikely',
    3: 'Neutral',
    4: 'Likely',
    5: 'Very Likely',
  };

  static const Map<int, String> difficulty = {
    0: 'Not rated',
    1: 'Very Easy',
    2: 'Easy',
    3: 'Moderate',
    4: 'Hard',
    5: 'Very Hard',
  };
}

/// Rating with percentage bar
class RatingWithBarWidget extends StatelessWidget {
  final String label;
  final double? value;
  final double maxRating;
  final ValueChanged<double>? onChanged;
  final bool readOnly;

  const RatingWithBarWidget({
    Key? key,
    required this.label,
    this.value,
    this.maxRating = 5.0,
    this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rating = value ?? 0.0;
    final percentage = (rating / maxRating * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RatingFieldWidget(
          label: label,
          value: value,
          onChanged: onChanged,
          readOnly: readOnly,
          maxRating: maxRating,
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: rating / maxRating,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            SizedBox(width: 12),
            Text(
              '$percentage%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
