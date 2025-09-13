import 'package:flutter/material.dart';
import '../../../../domain/entities/road.dart';

class RoadInfoPanelWidget extends StatelessWidget {
  final Road road;
  final bool isExpanded;
  final VoidCallback? onAddRide;
  final ValueChanged<DateTime>? onDeleteRide;
  final VoidCallback? onDeselect;

  const RoadInfoPanelWidget({
    Key? key,
    required this.road,
    required this.isExpanded,
    this.onAddRide,
    this.onDeleteRide,
    this.onDeselect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) return const SizedBox.shrink();

    return Positioned(
      left: 20,
      right: 80,
      bottom: 80,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Road name
            Text(
              road.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Add ride button
            ElevatedButton(
              onPressed: onAddRide,
              child: const Text('Ajouter une date de passage'),
            ),
            const SizedBox(height: 8),

            // Rides list
            if (road.hasRides) _buildRidesList(context),

            // Deselect button
            ElevatedButton(
              onPressed: onDeselect,
              child: const Text('Désélectionner'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRidesList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dates de passage :',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 110),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: road.sortedRides.length,
              itemBuilder: (context, index) {
                final ride = road.sortedRides[index];
                final formattedDate = _formatDate(ride.date);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 14),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, ride.date),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toString().split(' ')[0];
  }

  void _confirmDelete(BuildContext context, DateTime date) async {
    final formattedDate = _formatDate(date);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la date'),
        content: Text('Voulez-vous supprimer la date de passage $formattedDate ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      onDeleteRide?.call(date);
    }
  }
}
