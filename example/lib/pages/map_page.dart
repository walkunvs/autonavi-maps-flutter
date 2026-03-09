import 'package:flutter/material.dart';
import 'package:autonavi_maps_flutter/autonavi_maps_flutter.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  AutonaviController? _controller;
  MapType _mapType = MapType.normal;
  bool _trafficEnabled = false;
  bool _myLocationEnabled = false;

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('tiananmen'),
          position: const LatLng(39.909187, 116.397451),
          infoWindow: const InfoWindow(
            title: '天安门',
            snippet: '北京市东城区天安门广场',
          ),
        ),
        Marker(
          markerId: const MarkerId('forbidden_city'),
          position: const LatLng(39.916345, 116.397155),
          infoWindow: const InfoWindow(title: '故宫博物院'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptorHue.azure,
          ),
        ),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高德地图'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _showMapTypeDialog,
          ),
          IconButton(
            icon: Icon(
              _trafficEnabled ? Icons.traffic : Icons.traffic_outlined,
            ),
            onPressed: () => setState(() => _trafficEnabled = !_trafficEnabled),
          ),
          IconButton(
            icon: Icon(
              _myLocationEnabled
                  ? Icons.my_location
                  : Icons.location_searching,
            ),
            onPressed: () =>
                setState(() => _myLocationEnabled = !_myLocationEnabled),
          ),
        ],
      ),
      body: AutonaviWidget(
        initialCameraPosition: const CameraPosition(
          target: LatLng(39.909187, 116.397451),
          zoom: 13,
        ),
        onMapCreated: (controller) {
          setState(() => _controller = controller);
        },
        markers: _markers,
        mapType: _mapType,
        trafficEnabled: _trafficEnabled,
        myLocationEnabled: _myLocationEnabled,
        onTap: (latLng) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '点击位置: ${latLng.latitude.toStringAsFixed(6)}, '
                '${latLng.longitude.toStringAsFixed(6)}',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'beijing',
            onPressed: () => _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(
                const LatLng(39.909187, 116.397451),
                13,
              ),
            ),
            child: const Text('京'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'shanghai',
            onPressed: () => _controller?.animateCamera(
              CameraUpdate.newLatLngZoom(
                const LatLng(31.224, 121.469),
                13,
              ),
            ),
            child: const Text('沪'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.small(
            heroTag: 'snapshot',
            onPressed: _takeSnapshot,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }

  void _showMapTypeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('地图类型'),
        children: [
          for (final type in MapType.values)
            SimpleDialogOption(
              onPressed: () {
                setState(() => _mapType = type);
                Navigator.pop(ctx);
              },
              child: Text(type.name),
            ),
        ],
      ),
    );
  }

  Future<void> _takeSnapshot() async {
    final bytes = await _controller?.takeSnapshot();
    if (bytes == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('截图完成，大小: ${bytes.length} bytes')),
    );
  }
}
