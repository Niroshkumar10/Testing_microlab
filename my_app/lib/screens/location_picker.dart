import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

class LocationPicker extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final Function(double latitude, double longitude, String address)
      onLocationSelected;

  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  // ── Map ──────────────────────────────────────────────────────────────────
  final Completer<GoogleMapController> _mapCompleter = Completer();
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  Set<Marker> _markers = {};

  // ── Search ───────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;
  bool _isSearching = false;

  // ── Loading ───────────────────────────────────────────────────────────────
  bool _isLoadingAddress = false;
  bool _isLoadingGPS = false;

  // 🔴 Replace with your Google Maps API key
  static const String _apiKey = 'AIzaSyBIGPfna9mxSXpAJOhp0xigKhyZeeU0L0I';

  static const LatLng _defaultCenter = LatLng(13.0827, 80.2707); // Chennai

  // ── Theme ─────────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1A3A6B);
  static const Color _accent = Color(0xFF4A90D9);

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
      _selectedAddress = widget.initialAddress ?? '';
      _updateMarker(_selectedLocation!);
    }

    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showSuggestions = false);
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ── Update marker ─────────────────────────────────────────────────────────
  void _updateMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          draggable: true,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: _selectedAddress.isNotEmpty ? _selectedAddress : null,
          ),
          onDragEnd: (newPos) {
            _selectedLocation = newPos;
            _getAddressFromLatLng(newPos);
          },
        ),
      };
    });
  }

  // ── Reverse geocode ───────────────────────────────────────────────────────
  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoadingAddress = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.postalCode,
          p.country,
        ].where((x) => x != null && x.isNotEmpty).toList();
        setState(() {
          _selectedAddress = parts.join(', ');
          _selectedLocation = position;
        });
      }
    } catch (_) {
      setState(() {
        _selectedAddress =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        _selectedLocation = position;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
        _updateMarker(_selectedLocation!);
      }
    }
  }

  // ── Places Autocomplete ───────────────────────────────────────────────────
  Future<void> _onSearchChanged(String query) async {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=${Uri.encodeComponent(query)}'
          '&key=$_apiKey'
          '&language=en',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            final predictions = data['predictions'] as List<dynamic>;
            if (mounted) {
              setState(() {
                _suggestions = predictions
                    .map((p) => {
                          'place_id': p['place_id'] as String,
                          'description': p['description'] as String,
                          'main_text': p['structured_formatting']
                              ['main_text'] as String,
                          'secondary_text':
                              (p['structured_formatting']['secondary_text'] ??
                                  '') as String,
                        })
                    .toList();
                _showSuggestions = _suggestions.isNotEmpty;
                _isSearching = false;
              });
            }
          } else {
            if (mounted)
              setState(() {
                _suggestions = [];
                _showSuggestions = false;
                _isSearching = false;
              });
          }
        }
      } catch (_) {
        if (mounted)
          setState(() {
            _isSearching = false;
            _showSuggestions = false;
          });
      }
    });
  }

  // ── Select suggestion → move map ──────────────────────────────────────────
  Future<void> _selectSuggestion(Map<String, dynamic> suggestion) async {
    _searchFocus.unfocus();
    setState(() {
      _showSuggestions = false;
      _isSearching = true;
      _searchController.text = suggestion['description'];
    });
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${suggestion['place_id']}'
        '&fields=geometry,formatted_address'
        '&key=$_apiKey',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          final address = data['result']['formatted_address'] as String;
          final latLng = LatLng(lat, lng);

          final controller = await _mapCompleter.future;
          await controller.animateCamera(
            CameraUpdate.newCameraPosition(
                CameraPosition(target: latLng, zoom: 16.0)),
          );
          setState(() {
            _selectedLocation = latLng;
            _selectedAddress = address;
            _isSearching = false;
          });
          _updateMarker(latLng);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not find location: $e')),
        );
      }
    }
  }

  // ── GPS current location ──────────────────────────────────────────────────
  Future<void> _goToMyLocation() async {
    setState(() => _isLoadingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permission permanently denied. Enable from settings.')),
          );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final loc = LatLng(position.latitude, position.longitude);
      final controller = await _mapCompleter.future;
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
            CameraPosition(target: loc, zoom: 16.0)),
      );
      await _getAddressFromLatLng(loc);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get location: $e')),
        );
    } finally {
      if (mounted) setState(() => _isLoadingGPS = false);
    }
  }

  // ── Confirm ───────────────────────────────────────────────────────────────
  void _confirmLocation() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location on the map')),
      );
      return;
    }
    widget.onLocationSelected(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
      _selectedAddress,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pick Location',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          if (_selectedLocation != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _isLoadingAddress ? null : _confirmLocation,
                child: const Text('Confirm',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // ── Google Map ────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation ?? _defaultCenter,
              zoom: _selectedLocation != null ? 15.0 : 10.0,
            ),
            onMapCreated: (controller) {
              if (!_mapCompleter.isCompleted) _mapCompleter.complete(controller);
            },
            onTap: (latLng) {
              _searchFocus.unfocus();
              setState(() => _showSuggestions = false);
              _selectedLocation = latLng;
              _getAddressFromLatLng(latLng);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          // ── Search bar + suggestions ──────────────────────────────────────
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(children: [
              // Search input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search for a place or address...',
                    hintStyle:
                        const TextStyle(color: Colors.black38, fontSize: 14),
                    prefixIcon: _isSearching
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _accent),
                            ),
                          )
                        : const Icon(Icons.search, color: _accent, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.black38, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _suggestions = [];
                                _showSuggestions = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 4),
                  ),
                  onChanged: _onSearchChanged,
                  textInputAction: TextInputAction.search,
                ),
              ),

              // Suggestions dropdown
              if (_showSuggestions && _suggestions.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          _suggestions.length > 5 ? 5 : _suggestions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (context, index) {
                        final s = _suggestions[index];
                        return InkWell(
                          onTap: () => _selectSuggestion(s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            child: Row(children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _accent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.location_on,
                                    color: _accent, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(
                                    s['main_text'],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if ((s['secondary_text'] as String)
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      s['secondary_text'],
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.black45),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ]),
                              ),
                              const Icon(Icons.north_west,
                                  size: 14, color: Colors.black26),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ]),
          ),

          // ── Tap hint when nothing selected ────────────────────────────────
          if (_selectedLocation == null && !_showSuggestions)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6)
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: const [
                    Icon(Icons.touch_app, size: 15, color: _accent),
                    SizedBox(width: 6),
                    Text('Search above or tap map to set location',
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ),
              ),
            ),

          // ── Address loading indicator ─────────────────────────────────────
          if (_isLoadingAddress)
            Positioned(
              bottom: _selectedLocation != null ? 172 : 40,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4)
                  ],
                ),
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _accent),
                ),
              ),
            ),

          // ── GPS FAB ───────────────────────────────────────────────────────
          Positioned(
            bottom: _selectedLocation != null ? 172 : 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'gps_btn',
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _isLoadingGPS ? null : _goToMyLocation,
              tooltip: 'My location',
              child: _isLoadingGPS
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accent),
                    )
                  : const Icon(Icons.my_location, color: _accent, size: 20),
            ),
          ),

          // ── Bottom confirm bar ────────────────────────────────────────────
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, -3))
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on,
                            color: _accent, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          const Text('Selected Location',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: _accent)),
                          const SizedBox(height: 2),
                          _isLoadingAddress
                              ? const Text('Getting address...',
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.black45))
                              : Text(
                                  _selectedAddress.isNotEmpty
                                      ? _selectedAddress
                                      : '${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                                          '${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                      height: 1.4),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ]),
                      ),
                    ]),

                    const SizedBox(height: 14),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isLoadingAddress ? null : _confirmLocation,
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(
                          _isLoadingAddress
                              ? 'Getting address...'
                              : 'Confirm Location',
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _primary.withOpacity(0.5),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}