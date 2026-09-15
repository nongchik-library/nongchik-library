import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data_detail_page.dart';
import 'data_list_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final client = Supabase.instance.client;
  final mapController = MapController();
  final searchController = TextEditingController();

  List<MapPoint> allPoints = [];
  List<MapPoint> filteredPoints = [];
  bool loading = true;
  String selectedCategory = 'ทั้งหมด';
  String selectedSubdistrict = 'ทั้งหมด';
  String search = '';
  String? error;

  final categories = const <String>[
    'ทั้งหมด',
    'แหล่งเรียนรู้',
    'ภูมิปัญญาท้องถิ่น',
    'ปราชญ์ชาวบ้าน',
    'บ้านหนังสือชุมชน',
    'ศกร.ระดับตำบล',
    'แหล่งท่องเที่ยวในตำบล',
    'อาหาร/ขนมโบราณในชุมชน',
  ];

  final categoryType = const <String, DataType>{
    'แหล่งเรียนรู้': DataType.learningResource,
    'ภูมิปัญญาท้องถิ่น': DataType.localWisdom,
    'ปราชญ์ชาวบ้าน': DataType.localScholar,
    'บ้านหนังสือชุมชน': DataType.communityBookHouse,
    'ศกร.ระดับตำบล': DataType.subdistrictLearningCenter,
    'แหล่งท่องเที่ยวในตำบล': DataType.touristAttraction,
    'อาหาร/ขนมโบราณในชุมชน': DataType.traditionalFood,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final points = <MapPoint>[];
      for (final type in DataType.values) {
        final data = await client
            .from(type.table)
            .select()
            .eq('status', 'approved')
            .order('created_at', ascending: false);
        for (final raw in List<Map<String, dynamic>>.from(data)) {
          final lat = _number(raw['latitude']);
          final lng = _number(raw['longitude']);
          if (lat == null || lng == null) continue;
          final name = (raw['name'] ?? 'ไม่ระบุชื่อ').toString();
          points.add(MapPoint(
            id: raw['id']?.toString() ?? '',
            name: name,
            subdistrict: (raw['subdistrict'] ?? '').toString(),
            description: (raw['description'] ?? '').toString(),
            latitude: lat,
            longitude: lng,
            category: type.title,
            type: type,
            row: raw,
          ));
        }
      }
      if (!mounted) return;
      setState(() {
        allPoints = points;
        _applyFilters();
        loading = false;
      });
      if (points.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) mapController.move(LatLng(points.first.latitude, points.first.longitude), 11);
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  double? _number(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  void _applyFilters() {
    final q = search.trim().toLowerCase();
    final result = allPoints.where((p) {
      final categoryOk = selectedCategory == 'ทั้งหมด' || p.category == selectedCategory;
      final subOk = selectedSubdistrict == 'ทั้งหมด' || p.subdistrict == selectedSubdistrict;
      final text = '${p.name} ${p.subdistrict} ${p.description} ${p.category}'.toLowerCase();
      return categoryOk && subOk && (q.isEmpty || text.contains(q));
    }).toList();
    if (mounted) setState(() => filteredPoints = result);
  }

  List<String> get subdistricts {
    final values = allPoints.map((e) => e.subdistrict.trim()).where((e) => e.isNotEmpty).toSet().toList();
    values.sort();
    return ['ทั้งหมด', ...values];
  }

  void _openPoint(MapPoint p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DataDetailPage(type: p.type, row: p.row),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'แหล่งเรียนรู้': return Colors.green;
      case 'ภูมิปัญญาท้องถิ่น': return Colors.teal;
      case 'ปราชญ์ชาวบ้าน': return Colors.deepPurple;
      case 'บ้านหนังสือชุมชน': return Colors.blue;
      case 'ศกร.ระดับตำบล': return Colors.indigo;
      case 'แหล่งท่องเที่ยวในตำบล': return Colors.pink;
      case 'อาหาร/ขนมโบราณในชุมชน': return Colors.orange;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แผนที่แหล่งเรียนรู้', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('ไม่สามารถโหลดแผนที่ได้\n$error', textAlign: TextAlign.center)))
              : Column(
                  children: [
                    _filters(),
                    Expanded(
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: mapController,
                            options: MapOptions(
                              initialCenter: const LatLng(6.74, 101.18),
                              initialZoom: 10.5,
                              minZoom: 8,
                              maxZoom: 18,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.nongchik.library',
                              ),
                              MarkerLayer(
                                markers: filteredPoints.map((p) => Marker(
                                  point: LatLng(p.latitude, p.longitude),
                                  width: 44,
                                  height: 54,
                                  child: GestureDetector(
                                    onTap: () => _showPoint(p),
                                    child: Icon(Icons.location_on, size: 44, color: _categoryColor(p.category)),
                                  ),
                                )).toList(),
                              ),
                              RichAttributionWidget(
                                attributions: [
                                  TextSourceAttribution('OpenStreetMap contributors'),
                                ],
                              ),
                            ],
                          ),
                          Positioned(
                            left: 14,
                            top: 14,
                            child: Card(
                              margin: EdgeInsets.zero,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                child: Text('พบ ${filteredPoints.length} จุด', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                          if (filteredPoints.isNotEmpty)
                            Positioned(
                              right: 14,
                              bottom: 14,
                              child: FloatingActionButton.extended(
                                onPressed: () {
                                  final p = filteredPoints.first;
                                  mapController.move(LatLng(p.latitude, p.longitude), 13);
                                },
                                icon: const Icon(Icons.my_location),
                                label: const Text('ไปจุดแรก'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _filters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            onChanged: (v) { search = v; _applyFilters(); },
            decoration: InputDecoration(
              labelText: 'ค้นหาบนแผนที่',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isEmpty ? null : IconButton(onPressed: () { searchController.clear(); search = ''; _applyFilters(); setState(() {}); }, icon: const Icon(Icons.clear)),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'หมวดข้อมูล', border: OutlineInputBorder()),
                items: categories.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { if (v == null) return; setState(() => selectedCategory = v); _applyFilters(); },
              )),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(
                value: selectedSubdistrict,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'ตำบล', border: OutlineInputBorder()),
                items: subdistricts.map((v) => DropdownMenuItem(value: v, child: Text(v, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) { if (v == null) return; setState(() => selectedSubdistrict = v); _applyFilters(); },
              )),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'หัวข้อข้อมูลทั้งหมด',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.where((v) => v != 'ทั้งหมด').map((category) {
              final selected = selectedCategory == category;
              final count = allPoints.where((p) => p.category == category).length;
              final type = categoryType[category];
              final color = _categoryColor(category);
              return FilterChip(
                selected: selected,
                avatar: Icon(type?.icon ?? Icons.place, size: 18, color: selected ? Colors.white : color),
                label: Text('$category ($count)'),
                selectedColor: color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : null,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (_) {
                  setState(() => selectedCategory = selected ? 'ทั้งหมด' : category);
                  _applyFilters();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showPoint(MapPoint p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(backgroundColor: _categoryColor(p.category).withValues(alpha: 0.15), foregroundColor: _categoryColor(p.category), child: const Icon(Icons.location_on)),
                const SizedBox(width: 12),
                Expanded(child: Text(p.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 10),
              Text(p.category, style: TextStyle(color: _categoryColor(p.category), fontWeight: FontWeight.bold)),
              if (p.subdistrict.isNotEmpty) Text('ตำบล ${p.subdistrict}'),
              const SizedBox(height: 6),
              Text('พิกัด: ${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: FilledButton.icon(
                onPressed: () { Navigator.pop(sheetContext); _openPoint(p); },
                icon: const Icon(Icons.info_outline), label: const Text('ดูรายละเอียด'),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class MapPoint {
  final String id;
  final String name;
  final String subdistrict;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final DataType type;
  final Map<String, dynamic> row;

  const MapPoint({
    required this.id,
    required this.name,
    required this.subdistrict,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.type,
    required this.row,
  });
}
