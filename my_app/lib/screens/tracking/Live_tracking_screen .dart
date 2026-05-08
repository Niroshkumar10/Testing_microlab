import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LiveTrackingScreen extends StatefulWidget {
  final String trackingId;
  final String personName;

  const LiveTrackingScreen({
    super.key,
    required this.trackingId,
    required this.personName,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const Color _primary = Color(0xFF1A3A6B);
  static const Color _accent = Color(0xFF4A90D9);

  IO.Socket? _socket;
  final Completer<GoogleMapController> _mapCompleter = Completer();

  LatLng? _personLocation;
  bool _isConnected = false;
  bool _isTracking = false;
  bool _followMode = true; // camera follows marker
  String _lastSeen = 'Waiting...';
  double? _speed;
  int _updateCount = 0;

  // String get _serverUrl =>
  //     kIsWeb ? 'http://localhost:5000' : 'http://172.16.0.105:5000';

  String get _serverUrl => 'https://testing-microlab.onrender.com';


  @override
  void initState() {
    super.initState();
    _connectAndWatch();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    super.dispose();
  }

  void _connectAndWatch() {
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      setState(() => _isConnected = true);
      // Join the tracking room
      _socket!.emit('join_tracking', widget.trackingId);
      debugPrint('👁 Joined tracking: ${widget.trackingId}');
    });

    _socket!.onDisconnect((_) {
      setState(() => _isConnected = false);
    });

    // Receive live location updates
    _socket!.on('location_update', (data) {
      final lat = (data['latitude'] as num).toDouble();
      final lng = (data['longitude'] as num).toDouble();
      final latLng = LatLng(lat, lng);
      final now = TimeOfDay.now();

      setState(() {
        _personLocation = latLng;
        _isTracking = true;
        _updateCount++;
        _speed = data['speed'] != null
            ? (data['speed'] as num).toDouble() * 3.6 // m/s → km/h
            : null;
        _lastSeen =
            'Updated ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      });

      // Move camera if follow mode on
      if (_followMode) {
        _mapCompleter.future.then((controller) {
          controller.animateCamera(CameraUpdate.newLatLng(latLng));
        });
      }
    });

    _socket!.connect();
  }

  Future<void> _openNavigation() async {
    if (_personLocation == null) return;
    final lat = _personLocation!.latitude;
    final lng = _personLocation!.longitude;
    final googleNav =
        Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final browserNav = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
    if (await canLaunchUrl(googleNav)) {
      await launchUrl(googleNav);
    } else {
      await launchUrl(browserNav, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.personName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('ID: ${widget.trackingId}',
              style:
                  const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
        actions: [
          // Connection dot
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(_isConnected ? 'Live' : 'Offline',
                  style: const TextStyle(fontSize: 12)),
            ]),
          ),
        ],
      ),
      body: Stack(children: [
        // ── Google Map ──────────────────────────────────────────────────
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _personLocation ?? const LatLng(13.0827, 80.2707),
            zoom: 15,
          ),
          onMapCreated: (c) {
            if (!_mapCompleter.isCompleted) _mapCompleter.complete(c);
          },
          onCameraMoveStarted: () {
            // Disable follow mode when user manually moves map
            setState(() => _followMode = false);
          },
          markers: _personLocation != null
              ? {
                  Marker(
                    markerId: const MarkerId('person_location'),
                    position: _personLocation!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed),
                    infoWindow: InfoWindow(
                      title: widget.personName,
                      snippet: _lastSeen,
                    ),
                  ),
                }
              : {},
          zoomControlsEnabled: false,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
        ),

        // ── Top status bar ──────────────────────────────────────────────
        Positioned(
          top: 10,
          left: 12,
          right: 12,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1), blurRadius: 8)
              ],
            ),
            child: Row(children: [
              // Pulse indicator
              _isTracking
                  ? _PulsingDot()
                  : const Icon(Icons.hourglass_empty,
                      size: 14, color: Colors.black38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    _isTracking ? 'Live Tracking' : 'Waiting for location...',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _isTracking ? Colors.green : Colors.black45),
                  ),
                  Text(_lastSeen,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black38)),
                ]),
              ),
              if (_speed != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_speed!.toStringAsFixed(0)} km/h',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _accent),
                  ),
                ),
            ]),
          ),
        ),

        // ── Follow / Re-center button ───────────────────────────────────
        Positioned(
          bottom: 140,
          right: 16,
          child: Column(children: [
            // Re-center / follow toggle
            FloatingActionButton.small(
              heroTag: 'recenter',
              backgroundColor: _followMode ? _primary : Colors.white,
              elevation: 4,
              onPressed: () {
                setState(() => _followMode = true);
                if (_personLocation != null) {
                  _mapCompleter.future.then((c) =>
                      c.animateCamera(CameraUpdate.newLatLng(_personLocation!)));
                }
              },
              child: Icon(
                Icons.my_location,
                color: _followMode ? Colors.white : _primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 8),
            // Navigate to person
            FloatingActionButton.small(
              heroTag: 'navigate',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _personLocation != null ? _openNavigation : null,
              child: const Icon(Icons.navigation_rounded,
                  color: Color(0xFF2E9E6E), size: 20),
            ),
          ]),
        ),

        // ── Bottom info + Navigate bar ──────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, -3))
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Row(children: [
                // Person avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: _primary,
                  child: Text(
                    widget.personName.isNotEmpty
                        ? widget.personName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(widget.personName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    Text(
                      _personLocation != null
                          ? '${_personLocation!.latitude.toStringAsFixed(5)}, '
                              '${_personLocation!.longitude.toStringAsFixed(5)}'
                          : 'Location not yet received',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45),
                    ),
                    if (_updateCount > 0)
                      Text('$_updateCount location updates received',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38)),
                  ]),
                ),
              ]),

              const SizedBox(height: 14),

              // Navigate button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _personLocation != null ? _openNavigation : null,
                  icon: const Icon(Icons.navigation_rounded, size: 18),
                  label: const Text('Navigate to Person',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade200,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Animated pulsing green dot ────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}