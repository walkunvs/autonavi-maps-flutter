import 'dart:async';

import 'package:flutter/material.dart';
import 'package:autonavi_location_flutter/autonavi_location_flutter.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  StreamSubscription<LocationResult>? _subscription;
  LocationResult? _lastResult;
  bool _isListening = false;
  String? _error;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _subscription?.cancel();
      setState(() {
        _isListening = false;
        _subscription = null;
      });
    } else {
      setState(() {
        _isListening = true;
        _error = null;
      });
      _subscription = AutonaviLocation.onLocationChanged.listen(
        (result) => setState(() => _lastResult = result),
        onError: (e) => setState(() {
          _error = e.toString();
          _isListening = false;
        }),
      );
    }
  }

  Future<void> _getOnce() async {
    setState(() => _error = null);
    try {
      final result = await AutonaviLocation.getLocation();
      setState(() => _lastResult = result);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高德定位'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getOnce,
            tooltip: '单次定位',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _isListening ? '持续定位中...' : '定位已停止',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Switch(
                        value: _isListening,
                        onChanged: (_) => _toggleListening(),
                      ),
                    ],
                  ),
                  if (_isListening)
                    const LinearProgressIndicator(minHeight: 2),
                ],
              ),
            ),
          ),
          if (_error != null)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '错误: $_error',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ),
          if (_lastResult != null) ..._buildResultCards(_lastResult!),
        ],
      ),
    );
  }

  List<Widget> _buildResultCards(LocationResult r) => [
        const SizedBox(height: 8),
        _InfoCard(title: '坐标', items: {
          '纬度': r.latitude.toStringAsFixed(6),
          '经度': r.longitude.toStringAsFixed(6),
          '精度': '${r.accuracy.toStringAsFixed(1)} m',
          if (r.altitude != null)
            '海拔': '${r.altitude!.toStringAsFixed(1)} m',
          if (r.speed != null) '速度': '${r.speed!.toStringAsFixed(1)} m/s',
          if (r.heading != null) '方向': '${r.heading!.toStringAsFixed(1)}°',
        }),
        if (r.address != null) ...[
          const SizedBox(height: 8),
          _InfoCard(title: '地址', items: {
            '完整地址': r.address!,
            if (r.province != null) '省份': r.province!,
            if (r.city != null) '城市': r.city!,
            if (r.district != null) '区县': r.district!,
            if (r.street != null) '街道': r.street!,
            if (r.streetNum != null) '门牌号': r.streetNum!,
            if (r.poiName != null) 'POI': r.poiName!,
            if (r.aoiName != null) 'AOI': r.aoiName!,
          }),
        ],
      ];
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.items});

  final String title;
  final Map<String, String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            for (final entry in items.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                    ),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
