import 'package:flutter/material.dart';
import 'dart:math';
import './Live_tracking_screen .dart';
import './Driver_tracking_screen.dart';

class TrackingEntryScreen extends StatelessWidget {
  final String? prefilledName; // pass student name if coming from student card

  const TrackingEntryScreen({super.key, this.prefilledName});

  static const Color _primary = Color(0xFF1A3A6B);
  static const Color _accent = Color(0xFF4A90D9);

  // Generate a short random tracking ID like "TRK-4829"
  static String generateTrackingId() {
    final rand = Random();
    final num = 1000 + rand.nextInt(8999);
    return 'TRK-$num';
  }

  @override
  Widget build(BuildContext context) {
    final trackIdController = TextEditingController();
    final nameController =
        TextEditingController(text: prefilledName ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Live Tracking',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          const SizedBox(height: 10),

          // ── Header illustration ─────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A6B), Color(0xFF4A90D9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              const Icon(Icons.location_on, color: Colors.white, size: 48),
              const SizedBox(height: 10),
              const Text('Real-Time Location Tracking',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(
                'Track anyone live on the map\nor share your location',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 13),
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── CARD 1: Watch someone ───────────────────────────────────
          _Card(
            icon: Icons.remove_red_eye_rounded,
            iconColor: _accent,
            title: 'Track Someone',
            subtitle: 'Enter the tracking ID shared by the person',
            child: Column(children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Person Name',
                  prefixIcon:
                      const Icon(Icons.person_outline, color: _accent),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trackIdController,
                decoration: InputDecoration(
                  labelText: 'Tracking ID (e.g. TRK-4829)',
                  prefixIcon: const Icon(Icons.pin_drop_outlined,
                      color: _accent),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _accent, width: 2),
                  ),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Start Watching',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final id = trackIdController.text.trim().toUpperCase();
                    final name = nameController.text.trim();
                    if (id.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please enter a Tracking ID')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingScreen(
                          trackingId: id,
                          personName:
                              name.isNotEmpty ? name : 'Unknown',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // ── CARD 2: Share your location ─────────────────────────────
          _Card(
            icon: Icons.navigation_rounded,
            iconColor: const Color(0xFF2E9E6E),
            title: 'Share My Location',
            subtitle:
                'Generate a tracking ID and share it so others can track you',
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share_location_rounded),
                label: const Text('Generate ID & Share',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E9E6E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final newId = generateTrackingId();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverTrackingScreen(
                        trackingId: newId,
                        driverName: 'Me',
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _Card({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black45)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }
}