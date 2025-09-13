import 'package:flutter/material.dart';
import '../../../../domain/entities/road.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final List<Road> suggestions;
  final bool isVisible;
  final ValueChanged<Road>? onSuggestionTap;

  const SearchSuggestionsWidget({
    Key? key,
    required this.suggestions,
    required this.isVisible,
    this.onSuggestionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible || suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 76, // Below search bar
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            itemBuilder: (context, index) => _buildSuggestionItem(
              context,
              suggestions[index],
              index == suggestions.length - 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(BuildContext context, Road road, bool isLast) {
    return InkWell(
      onTap: () => onSuggestionTap?.call(road),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: !isLast ? Border(bottom: BorderSide(color: Colors.grey[200]!)) : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: _getRoadColor(road),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    road.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    road.city,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    road.lastRideText,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoadColor(Road road) {
    switch (road.color) {
      case RoadColor.green:
        return Colors.green;
      case RoadColor.orange:
        return Colors.orange;
      case RoadColor.red:
        return Colors.red;
    }
  }
}
