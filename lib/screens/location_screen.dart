import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_state.dart';
import '../services/location_service.dart';
import 'compass_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _locationService = const LocationService();

  bool _isFetchingGps = false;
  String? _gpsError;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isFetchingGps = true;
      _gpsError = null;
    });

    try {
      final result = await _locationService.getCurrentLocation();
      if (result == null) {
        setState(() {
          _gpsError = 'Location permission denied. Enter coordinates manually.';
        });
        return;
      }
      final (lat, lng) = result;
      setState(() {
        _latController.text = lat.toStringAsFixed(6);
        _lngController.text = lng.toStringAsFixed(6);
        _gpsError = null;
      });
    } on LocationServiceException catch (e) {
      setState(() {
        _gpsError = e.message;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _isFetchingGps = false;
      });
    }
  }

  void _startNavigating() {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());

    final appState = AppState.initial(latitude: lat, longitude: lng);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CompassScreen(appState: appState),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Validators
  // -------------------------------------------------------------------------

  String? _validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Latitude is required.';
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid decimal number (e.g. 51.5074).';
    if (v < -90 || v > 90) return 'Latitude must be between -90 and 90.';
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'Longitude is required.';
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid decimal number (e.g. -0.1278).';
    if (v < -180 || v > 180) return 'Longitude must be between -180 and 180.';
    return null;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const SizedBox(height: 16),
                Icon(
                  Icons.wb_sunny_outlined,
                  size: 56,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'BAGNOLD\nSUN COMPASS',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 8),
                Text(
                  'Navigate by the shadow of the sun.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF9E7E3A),
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 48),

                // ── Coordinate fields ────────────────────────────────────────
                Text(
                  'COORDINATES',
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: '51.5074',
                    prefixIcon: Icon(Icons.south, color: Color(0xFF9E7E3A)),
                  ),
                  style: const TextStyle(color: Color(0xFFE8D5A3)),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?\d*\.?\d*'),
                    ),
                  ],
                  validator: _validateLatitude,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _lngController,
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: '-0.1278',
                    prefixIcon: Icon(Icons.east, color: Color(0xFF9E7E3A)),
                  ),
                  style: const TextStyle(color: Color(0xFFE8D5A3)),
                  keyboardType: const TextInputType.numberWithOptions(
                    signed: true,
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^-?\d*\.?\d*'),
                    ),
                  ],
                  validator: _validateLongitude,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _startNavigating(),
                ),

                const SizedBox(height: 20),

                // ── GPS button ───────────────────────────────────────────────
                OutlinedButton.icon(
                  onPressed: _isFetchingGps ? null : _fetchGpsLocation,
                  icon: _isFetchingGps
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD4A017),
                          ),
                        )
                      : const Icon(Icons.gps_fixed),
                  label: Text(
                    _isFetchingGps ? 'Locating…' : 'USE GPS',
                  ),
                ),

                if (_gpsError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _gpsError!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 40),

                // ── Start button ─────────────────────────────────────────────
                ElevatedButton.icon(
                  onPressed: _startNavigating,
                  icon: const Icon(Icons.explore),
                  label: const Text('START NAVIGATING'),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
