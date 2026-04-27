import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_colors.dart';

/// Result returned when the user confirms a location.
class LocationPickerResult {
  const LocationPickerResult({
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String name;
  final double lat;
  final double lng;
}

class _NominatimResult {
  const _NominatimResult({
    required this.name,
    required this.lat,
    required this.lng,
  });

  final String name;
  final double lat;
  final double lng;
}

/// Full-screen map picker. The user moves the map; a fixed crosshair marks the
/// selected point. Returns a [LocationPickerResult] via Navigator.pop.
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initialName,
    this.initialLat,
    this.initialLng,
    this.title = 'Seleccionar ubicación',
  });

  final String? initialName;
  final double? initialLat;
  final double? initialLng;
  final String title;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // Bogotá as default center
  static const _defaultCenter = LatLng(4.6486, -74.0637);
  static const _defaultZoom = 14.0;

  late final MapController _mapController;
  late final TextEditingController _nameCtrl;

  LatLng _center = _defaultCenter;
  bool _loadingGps = false;

  // Reverse geocoding
  bool _geocoding = false;
  Timer? _debounceTimer;

  // Location search
  List<_NominatimResult> _suggestions = [];
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');

    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryGps();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchTimer?.cancel();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryGps() async {
    setState(() => _loadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _center = latLng);
      _mapController.move(latLng, _defaultZoom);
      // Reverse geocode the GPS location
      _reverseGeocode();
    } catch (_) {
      // GPS unavailable — keep Bogotá default
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  Future<void> _reverseGeocode() async {
    if (!mounted) return;
    setState(() => _geocoding = true);
    try {
      final dio = Dio();
      final res = await dio.get<dynamic>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': _center.latitude,
          'lon': _center.longitude,
          'format': 'json',
          'accept-language': 'es',
        },
        options: Options(headers: {'User-Agent': 'UNWheels/1.0'}),
      );
      final data = res.data;
      if (data is Map && data['display_name'] != null && mounted) {
        _nameCtrl.text = data['display_name'].toString();
      }
    } catch (_) {
      // Silently ignore geocoding errors
    } finally {
      if (mounted) setState(() => _geocoding = false);
    }
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        _center = camera.center;
        _suggestions = [];
      });
      _debounceTimer?.cancel();
      _debounceTimer =
          Timer(const Duration(milliseconds: 800), _reverseGeocode);
    }
  }

  void _searchLocations(String query) {
    _searchTimer?.cancel();
    if (query.trim().length < 3) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _searchTimer = Timer(const Duration(milliseconds: 450), () async {
      try {
        final dio = Dio();
        final res = await dio.get<dynamic>(
          'https://nominatim.openstreetmap.org/search',
          queryParameters: {
            'q': query,
            'format': 'json',
            'limit': 5,
            'countrycodes': 'co',
            'accept-language': 'es',
          },
          options: Options(headers: {'User-Agent': 'UNWheels/1.0'}),
        );
        if (!mounted) return;
        final list = res.data as List? ?? [];
        setState(() {
          _suggestions = list
              .whereType<Map>()
              .map((e) => _NominatimResult(
                    name: e['display_name']?.toString() ?? '',
                    lat: double.tryParse(e['lat']?.toString() ?? '') ?? 0,
                    lng: double.tryParse(e['lon']?.toString() ?? '') ?? 0,
                  ))
              .where((r) => r.name.isNotEmpty)
              .toList();
        });
      } catch (_) {}
    });
  }

  void _selectSuggestion(_NominatimResult suggestion) {
    final latLng = LatLng(suggestion.lat, suggestion.lng);
    _nameCtrl.text = suggestion.name;
    setState(() {
      _center = latLng;
      _suggestions = [];
    });
    _mapController.move(latLng, _defaultZoom);
    FocusScope.of(context).unfocus();
  }

  void _confirm() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un nombre para este lugar.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      LocationPickerResult(
        name: name,
        lat: _center.latitude,
        lng: _center.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: const Text(
              'Confirmar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Location name field
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _nameCtrl,
              onChanged: _searchLocations,
              decoration: InputDecoration(
                labelText: 'Nombre del lugar',
                hintText: 'ej: Edificio 453, Campus Bogotá',
                prefixIcon: const Icon(Icons.place_outlined),
                suffixIcon: _geocoding
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),

          // GPS button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadingGps ? null : _tryGps,
                icon: _loadingGps
                    ? const SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 16),
                label: const Text('Usar mi ubicación actual'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size(0, 36),
                ),
              ),
            ),
          ),

          // Search suggestions
          if (_suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Material(
                elevation: 3,
                borderRadius: BorderRadius.circular(10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 1),
                    itemBuilder: (_, i) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.place_outlined,
                          size: 18, color: AppColors.primary),
                      title: Text(
                        _suggestions[i].name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      onTap: () => _selectSuggestion(_suggestions[i]),
                    ),
                  ),
                ),
              ),
            ),

          // Map
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _defaultZoom,
                    onPositionChanged: _onMapPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.unwheels.mobile',
                    ),
                  ],
                ),

                // Fixed crosshair
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(80),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        width: 16,
                        height: 16,
                      ),
                      Container(
                        width: 2,
                        height: 20,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                // Coordinates display
                Positioned(
                  bottom: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_center.latitude.toStringAsFixed(5)}, '
                      '${_center.longitude.toStringAsFixed(5)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
