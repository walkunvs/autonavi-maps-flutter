import 'package:flutter/material.dart';
import 'package:autonavi_search_flutter/autonavi_search_flutter.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _keywordCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: '上海');
  final _addressCtrl = TextEditingController();

  bool _loading = false;
  String? _error;
  List<PoiItem>? _poiResults;
  RegeocodeResult? _regeocodeResult;
  List<GeocodeResult>? _geocodeResults;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _keywordCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _searchPoi() async {
    if (_keywordCtrl.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _poiResults = null;
    });
    try {
      final result = await AutonaviSearch.searchKeyword(
        keyword: _keywordCtrl.text,
        city: _cityCtrl.text,
      );
      setState(() => _poiResults = result.pois);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _regeocode() async {
    setState(() {
      _loading = true;
      _error = null;
      _regeocodeResult = null;
    });
    try {
      // Example: Shanghai People's Square
      final result = await AutonaviSearch.regeocode(
        const LatLng(31.229936, 121.474000),
      );
      setState(() => _regeocodeResult = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _geocode() async {
    if (_addressCtrl.text.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _geocodeResults = null;
    });
    try {
      final results = await AutonaviSearch.geocode(
        address: _addressCtrl.text,
        city: _cityCtrl.text,
      );
      setState(() => _geocodeResults = results);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高德搜索'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'POI搜索'),
            Tab(text: '逆地理'),
            Tab(text: '地理编码'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PoiSearchTab(
            keywordCtrl: _keywordCtrl,
            cityCtrl: _cityCtrl,
            onSearch: _searchPoi,
            loading: _loading,
            error: _error,
            results: _poiResults,
          ),
          _RegeocodeTab(
            onSearch: _regeocode,
            loading: _loading,
            error: _error,
            result: _regeocodeResult,
          ),
          _GeocodeTab(
            addressCtrl: _addressCtrl,
            cityCtrl: _cityCtrl,
            onSearch: _geocode,
            loading: _loading,
            error: _error,
            results: _geocodeResults,
          ),
        ],
      ),
    );
  }
}

class _PoiSearchTab extends StatelessWidget {
  const _PoiSearchTab({
    required this.keywordCtrl,
    required this.cityCtrl,
    required this.onSearch,
    required this.loading,
    this.error,
    this.results,
  });

  final TextEditingController keywordCtrl;
  final TextEditingController cityCtrl;
  final VoidCallback onSearch;
  final bool loading;
  final String? error;
  final List<PoiItem>? results;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: keywordCtrl,
                  decoration: const InputDecoration(
                    labelText: '关键词',
                    hintText: '如: 咖啡',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: cityCtrl,
                  decoration: const InputDecoration(
                    labelText: '城市',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: loading ? null : onSearch,
                child: const Text('搜索'),
              ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('错误: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (results != null)
          Expanded(
            child: ListView.builder(
              itemCount: results!.length,
              itemBuilder: (ctx, i) {
                final poi = results![i];
                return ListTile(
                  title: Text(poi.title),
                  subtitle: Text(poi.address ?? poi.typeDes ?? ''),
                  trailing: poi.distance != null
                      ? Text('${poi.distance!.toStringAsFixed(0)}m')
                      : null,
                  leading: const Icon(Icons.place),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RegeocodeTab extends StatelessWidget {
  const _RegeocodeTab({
    required this.onSearch,
    required this.loading,
    this.error,
    this.result,
  });

  final VoidCallback onSearch;
  final bool loading;
  final String? error;
  final RegeocodeResult? result;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('将坐标 (31.229936, 121.474000) 转为地址'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loading ? null : onSearch,
            icon: const Icon(Icons.location_on),
            label: const Text('执行逆地理编码'),
          ),
          if (loading) const LinearProgressIndicator(),
          if (error != null) ...[
            const SizedBox(height: 16),
            Text('错误: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (result != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '结果',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Divider(),
                    _Row('地址', result!.formattedAddress),
                    _Row('省份', result!.province),
                    _Row('城市', result!.city),
                    _Row('区县', result!.district),
                    _Row('街道', result!.street),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    )),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

class _GeocodeTab extends StatelessWidget {
  const _GeocodeTab({
    required this.addressCtrl,
    required this.cityCtrl,
    required this.onSearch,
    required this.loading,
    this.error,
    this.results,
  });

  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final VoidCallback onSearch;
  final bool loading;
  final String? error;
  final List<GeocodeResult>? results;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(
                  labelText: '地址',
                  hintText: '如: 上海市人民广场',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onSearch(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: '城市 (可选)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: loading ? null : onSearch,
                    child: const Text('编码'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('错误: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (results != null)
          Expanded(
            child: ListView.builder(
              itemCount: results!.length,
              itemBuilder: (ctx, i) {
                final r = results![i];
                return ListTile(
                  title: Text(r.formattedAddress ?? ''),
                  subtitle: r.latitude != null
                      ? Text(
                          '${r.latitude?.toStringAsFixed(6)}, '
                          '${r.longitude?.toStringAsFixed(6)}',
                        )
                      : null,
                  leading: const Icon(Icons.map_outlined),
                );
              },
            ),
          ),
      ],
    );
  }
}
