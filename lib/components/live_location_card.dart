import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LiveLocationCard extends StatelessWidget {
  final Position? position;
  final String status;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const LiveLocationCard({
    super.key,
    required this.position,
    required this.status,
    required this.onStart,
    required this.onStop,
  });

  String _positionText() {
    if (position == null) return status;
    final ts = position!.timestamp;
    return 'Lat: ${position!.latitude.toStringAsFixed(6)}, Lon: ${position!.longitude.toStringAsFixed(6)}\nTS: ${DateTime.fromMillisecondsSinceEpoch(ts.millisecondsSinceEpoch)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text('Live Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(_positionText()),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onStop,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
