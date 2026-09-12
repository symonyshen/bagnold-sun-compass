import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../models/sun_position.dart';
import '../services/sun_calculator.dart';
import '../widgets/dial_widget.dart';
import '../widgets/shadow_indicator.dart';
import 'location_screen.dart';

class CompassScreen extends StatefulWidget {
  final AppState appState;

  const CompassScreen({super.key, required this.appState});

  @override
  State<CompassScreen> createState() => _CompassScreenState();
}

class _CompassScreenState extends State<CompassScreen> {
  static const _calculator = SunCalculator();

  late AppState _state;
  late SunPosition _sunPosition;
  late Timer _ticker;
  DateTime _now = DateTime.now();

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _state = widget.appState;
    _sunPosition = _recalculate(_state);

    // Tick every second to update elapsed timer and recalculate sun position.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
        _sunPosition = _recalculate(_state);
      });
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  SunPosition _recalculate(AppState state) {
    return _calculator.calculate(
      state.latitude,
      state.longitude,
      DateTime.now(),
    );
  }

  double get _shadowAngle {
    return (_state.desiredHeading - _sunPosition.azimuth + 360) % 360;
  }

  String _formatElapsed(Duration d) {
    final totalSeconds = d.inSeconds.abs();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;

    if (h > 0) return '${h}h ${m}m ${s}s ago';
    if (m > 0) return '${m}m ${s}s ago';
    return '${s}s ago';
  }

  String _fmtDeg(double v) => v.toStringAsFixed(1);
  String _fmtCoord(double v) => v.toStringAsFixed(5);

  void _onHeadingChanged(double heading) {
    setState(() {
      _state = _state.copyWith(desiredHeading: heading);
    });
  }

  void _goToLocationScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LocationScreen()),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final elapsed = _now.difference(_state.coordsUpdatedAt);
    final elapsedText = _formatElapsed(elapsed);
    final heading = _state.desiredHeading;
    final shadowAngle = _shadowAngle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SUN COMPASS'),
        leading: IconButton(
          icon: const Icon(Icons.edit_location_alt_outlined),
          tooltip: 'Update Location',
          onPressed: _goToLocationScreen,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Dial + Shadow overlay ────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: _buildDialArea(heading, shadowAngle),
              ),
            ),

            // ── Heading readout ───────────────────────────────────────────────
            _buildHeadingReadout(heading),

            // ── Info panel ───────────────────────────────────────────────────
            _buildInfoPanel(elapsedText),

            const SizedBox(height: 16),

            // ── Update location button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                onPressed: _goToLocationScreen,
                icon: const Icon(Icons.my_location),
                label: const Text('UPDATE LOCATION'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDialArea(double heading, double shadowAngle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size =
            constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth
                : constraints.maxHeight;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Rotatable compass dial (background)
                DialWidget(
                  heading: heading,
                  onHeadingChanged: _onHeadingChanged,
                ),

                // Shadow indicator overlay (non-interactive)
                IgnorePointer(
                  child: ShadowIndicator(
                    shadowAngle: shadowAngle,
                    sunAltitude: _sunPosition.altitude,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeadingReadout(double heading) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            heading.toStringAsFixed(0).padLeft(3, '0'),
            style: const TextStyle(
              color: Color(0xFFD4A017),
              fontSize: 52,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            '°',
            style: TextStyle(
              color: Color(0xFFD4A017),
              fontSize: 28,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(String elapsedText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1F0E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF5C4520)),
      ),
      child: Column(
        children: [
          // Row 1 — coordinates
          _infoRow(
            icon: Icons.location_on_outlined,
            label: 'POSITION',
            value:
                '${_fmtCoord(_state.latitude)}°,  ${_fmtCoord(_state.longitude)}°',
          ),
          const Divider(color: Color(0xFF3A2A0A), height: 16),

          // Row 2 — sun azimuth
          _infoRow(
            icon: Icons.explore_outlined,
            label: 'SUN AZIMUTH',
            value: '${_fmtDeg(_sunPosition.azimuth)}°',
          ),

          // Row 3 — sun altitude
          _infoRow(
            icon: Icons.wb_sunny_outlined,
            label: 'SUN ALTITUDE',
            value: '${_fmtDeg(_sunPosition.altitude)}°',
            valueColor: _sunPosition.isAboveHorizon
                ? const Color(0xFFD4A017)
                : const Color(0xFF888888),
          ),
          const Divider(color: Color(0xFF3A2A0A), height: 16),

          // Row 4 — elapsed time
          _infoRow(
            icon: Icons.timer_outlined,
            label: 'COORDS AGE',
            value: elapsedText,
            valueColor: _coordsAgeColor(_state.coordsUpdatedAt),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF9E7E3A)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9E7E3A),
              fontSize: 11,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? const Color(0xFFE8D5A3),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _coordsAgeColor(DateTime updatedAt) {
    final age = DateTime.now().difference(updatedAt);
    if (age.inMinutes < 5) return const Color(0xFF4CAF50);
    if (age.inMinutes < 15) return const Color(0xFFD4A017);
    return const Color(0xFFFF6B35);
  }
}
