import 'dart:async';
import 'package:flutter/material.dart';

import '../models/app_state.dart';
import '../services/dead_reckoning_service.dart';
import '../widgets/path_canvas.dart';

/// Shows the checkpoint history connected by a line, with a live-updating
/// dead-reckoning estimate if a speed has been set.
class PathScreen extends StatefulWidget {
  final AppState appState;

  const PathScreen({super.key, required this.appState});

  @override
  State<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends State<PathScreen> {
  static const _calculator = DeadReckoningService();

  late Timer _ticker;
  ({double latitude, double longitude})? _liveEstimate;

  @override
  void initState() {
    super.initState();
    _recalculate();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(_recalculate);
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  void _recalculate() {
    final state = widget.appState;
    if (state.speedKmh <= 0) {
      _liveEstimate = null;
      return;
    }
    final origin = state.checkpoints.last;
    _liveEstimate = _calculator.estimatePosition(
      originLat: origin.latitude,
      originLng: origin.longitude,
      headingDeg: origin.heading,
      speedKmh: state.speedKmh,
      elapsed: DateTime.now().difference(origin.timestamp),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PATH')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: PathCanvas(
            checkpoints: widget.appState.checkpoints,
            liveEstimate: _liveEstimate,
          ),
        ),
      ),
    );
  }
}
