import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart' show kIsWeb;

class DriverTrackingScreen extends StatefulWidget {
  final String trackingId; // unique ID shared with viewer
  final String driverName;

  const DriverTrackingScreen({
    super.key,
    required this.trackingId,
    required this.driverName,
  });

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  static const Color _primary = Color(0xFF1A3A6B);
  static const Color _green = Color(0xFF2E9E6E);

  IO.Socket? _socket;
  StreamSubscription<Position>? _positionStream;
  final Completer<GoogleMapController> _mapCompleter = Completer();

  LatLng? _currentLocation;
  bool _isTracking = false;
  bool _isConnected = false;
  int _updateCount = 0;
  String _statusText = 'Not started';

  // String get _serverUrl =>
  //     kIsWeb ? 'http://localhost:5000' : 'http://172.16.0.105:5000';

  String get _serverUrl => 'https://testing-microlab.onrender.com';


  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  @override
  void dispose() {
    _stopTracking();
    _socket?.disconnect();
    super.dispose();
  }

  void _connectSocket() {
    _socket = IO.io(_serverUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      setState(() => _isConnected = true);
      debugPrint('🟢 Socket connected');
    });

    _socket!.onDisconnect((_) {
      setState(() => _isConnected = false);
      debugPrint('🔴 Socket disconnected');
    });

    _socket!.connect();
  }

  Future<void> _startTracking() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showSnack('Please enable location services');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack('Location permission permanently denied');
      return;
    }

    setState(() {
      _isTracking = true;
      _statusText = 'Sharing location...';
      _updateCount = 0;
    });

    // Stream location every 3 seconds
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // update every 5 meters moved
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);

      // Send to socket
      _socket?.emit('send_location', {
        'trackingId': widget.trackingId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'name': widget.driverName,
        'speed': position.speed,
        'timestamp': DateTime.now().toIso8601String(),
      });

      setState(() {
        _currentLocation = latLng;
        _updateCount++;
        _statusText =
            'Live • ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      });

      // Move camera to follow
      _mapCompleter.future.then((controller) {
        controller.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
      });
    });
  }

  void _stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _socket?.emit('stop_tracking', {'trackingId': widget.trackingId});
    setState(() {
      _isTracking = false;
      _statusText = 'Stopped';
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Share My Location',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Connection indicator
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
              Text(
                _isConnected ? 'Connected' : 'Offline',
                style: const TextStyle(fontSize: 12),
              ),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // ── Tracking ID card ──────────────────────────────────────────
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAEEF8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            const Text('Share this Tracking ID',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                widget.trackingId,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A6B),
                    letterSpacing: 3),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Color(0xFF4A90D9)),
                onPressed: () {
                  // Copy to clipboard
                  _showSnack('Tracking ID copied!');
                },
              ),
            ]),
            Text('Ask the person to enter this ID to track you',
                style: TextStyle(fontSize: 11, color: Colors.black38)),
          ]),
        ),

        // ── Map ───────────────────────────────────────────────────────
        Expanded(
          child: Stack(children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(13.0827, 80.2707),
                zoom: 15,
              ),
              onMapCreated: (c) {
                if (!_mapCompleter.isCompleted) _mapCompleter.complete(c);
              },
              markers: _currentLocation != null
                  ? {
                      Marker(
                        markerId: const MarkerId('my_location'),
                        position: _currentLocation!,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueGreen),
                        infoWindow:
                            InfoWindow(title: widget.driverName, snippet: 'Me'),
                      ),
                    }
                  : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),

            // Status bar
            if (_isTracking)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8)
                    ],
                  ),
                  child: Row(children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_statusText,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54)),
                    ),
                    Text('$_updateCount updates',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black38)),
                  ]),
                ),
              ),
          ]),
        ),

        // ── Start/Stop button ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              icon: Icon(_isTracking ? Icons.stop_circle : Icons.navigation),
              label: Text(
                _isTracking ? 'Stop Sharing' : 'Start Sharing Location',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.red : _green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}