import 'package:flutter/material.dart';
import '../../../../domain/entities/road.dart';

class FloatingControlsWidget extends StatelessWidget {
  final Road? selectedRoad;
  final bool isPanelExpanded;
  final bool showColoredSegments;
  final VoidCallback? onTogglePanel;
  final VoidCallback? onCenterLocation;
  final VoidCallback? onToggleSegments;

  const FloatingControlsWidget({
    Key? key,
    this.selectedRoad,
    required this.isPanelExpanded,
    required this.showColoredSegments,
    this.onTogglePanel,
    this.onCenterLocation,
    this.onToggleSegments,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Info button (when road is selected)
        if (selectedRoad != null)
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              heroTag: 'info_button',
              onPressed: onTogglePanel,
              child: Icon(isPanelExpanded ? Icons.close : Icons.info_outline),
            ),
          ),

        // Center location button
        Positioned(
          bottom: 24,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'center_location',
            mini: true,
            onPressed: onCenterLocation,
            child: const Icon(Icons.my_location),
          ),
        ),

        // Toggle segments switch
        Positioned(
          bottom: 24,
          left: 16,
          child: Switch(
            value: showColoredSegments,
            onChanged: (_) => onToggleSegments?.call(),
          ),
        ),

        // Selected road name bubble
        if (selectedRoad != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 240),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                selectedRoad!.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }
}
