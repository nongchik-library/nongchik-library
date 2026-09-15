import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data_form_page.dart';
import 'data_detail_page.dart';

enum DataType {
  learningResource,
  localWisdom,
  localScholar,
  communityBookHouse,
  subdistrictLearningCenter,
  touristAttraction,
  traditionalFood,
}

extension DataTypeX on DataType {
  String get table {
    switch (this) {
      case DataType.learningResource:
        return 'learning_resources';
      case DataType.localWisdom:
        return 'local_wisdom';
      case DataType.localScholar:
        return 'local_scholars';
      case DataType.communityBookHouse:
        return 'community_book_houses';
      case DataType.subdistrictLearningCenter:
        return 'subdistrict_learning_centers';
      case DataType.touristAttraction:
        return 'tourist_attractions';
      case DataType.traditionalFood:
        return 'traditional_foods';
    }
  }

  String get title {
    switch (this) {
      case DataType.learningResource:
        return 'แหล่งเรียนรู้';
      case DataType.localWisdom:
        return 'ภูมิปัญญาท้องถิ่น';
      case DataType.localScholar:
        return 'ปราชญ์ชาวบ้าน';
      case DataType.communityBookHouse:
        return 'บ้านหนังสือชุมชน';
      case DataType.subdistrictLearningCenter:
        return 'ศกร.ระดับตำบล';
      case DataType.touristAttraction:
        return 'แหล่งท่องเที่ยวในตำบล';
      case DataType.traditionalFood:
        return 'อาหาร/ขนมโบราณในชุมชน';
    }
  }

  IconData get icon {
    switch (this) {
      case DataType.learningResource:
        return Icons.menu_book;
      case DataType.localWisdom:
        return Icons.eco;
      case DataType.localScholar:
        return Icons.person;
      case DataType.communityBookHouse:
        return Icons.home_work;
      case DataType.subdistrictLearningCenter:
        return Icons.location_city;
      case DataType.touristAttraction:
        return Icons.photo_camera;
      case DataType.traditionalFood:
        return Icons.restaurant;
    }
  }
}

class DataListPage extends StatefulWidget {
  final DataType type;

  const DataListPage({super.key, required this.type});

  @override
  State<DataListPage> createState() => _DataListPageState();
}

class _DataListPageState extends State<DataListPage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> rows = [];
  List<Map<String, dynamic>> filteredRows = [];
  List<String> subdistricts = [];
  bool loading = true;
  String? error;
  String selectedSubdistrict = 'ทั้งหมด';
  String selectedStatus = 'ทั้งหมด';
  bool admin = false;

  @override
  void initState() {
    super.initState();
    searchController.addListener(_applyFilters);
    _loadRole();
    _load();
  }

  @override
  void dispose() {
    searchController.removeListener(_applyFilters);
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRole() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final p = await client.from('profiles').select('role').eq('id', user.id).maybeSingle();
      if (mounted) setState(() => admin = p?['role'] == 'admin');
    } catch (_) {}
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);

    try {
      final data = await client
          .from(widget.type.table)
          .select()
          .order('created_at', ascending: false);

      if (!mounted) return;

      rows = List<Map<String, dynamic>>.from(data);
      final values = rows
          .map((r) => r['subdistrict']?.toString().trim() ?? '')
          .where((v) => v.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));

      setState(() {
        subdistricts = values;
        loading = false;
        error = null;
        if (!subdistricts.contains(selectedSubdistrict) &&
            selectedSubdistrict != 'ทั้งหมด') {
          selectedSubdistrict = 'ทั้งหมด';
        }
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void _applyFilters() {
    final q = searchController.text.trim().toLowerCase();
    final sub = selectedSubdistrict;
    final status = selectedStatus;

    final result = rows.where((row) {
      final rowSub = row['subdistrict']?.toString() ?? '';
      final rowStatus = row['status']?.toString() ?? 'pending';

      final haystack = [
        row['name'],
        row['description'],
        row['subdistrict'],
        row['address'],
        row['contact'],
        row['extra_info'],
      ].map((v) => v?.toString().toLowerCase() ?? '').join(' ');

      final matchesSearch = q.isEmpty || haystack.contains(q);
      final matchesSub = sub == 'ทั้งหมด' || rowSub == sub;
      final matchesStatus = status == 'ทั้งหมด' || rowStatus == status;
      return matchesSearch && matchesSub && matchesStatus;
    }).toList();

    if (mounted) setState(() => filteredRows = result);
  }

  Future<bool> _isAdmin() async {
    final user = client.auth.currentUser;
    if (user == null) return false;

    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    return profile?['role'] == 'admin';
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    if (!await _isAdmin()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เฉพาะแอดมินเท่านั้นที่ลบข้อมูลได้')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบ “${row['name'] ?? '-'}” หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await client.from(widget.type.table).delete().eq('id', row['id']);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }

  Future<void> _openForm([Map<String, dynamic>? row]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DataFormPage(type: widget.type, row: row),
      ),
    );
    if (result == true) await _load();
  }

  String _statusText(String value) {
    switch (value) {
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ไม่อนุมัติ';
      case 'pending':
        return 'รอตรวจสอบ';
      default:
        return value;
    }
  }

  Color _statusColor(String value) {
    switch (value) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _clearFilters() {
    searchController.clear();
    setState(() {
      selectedSubdistrict = 'ทั้งหมด';
      selectedStatus = 'ทั้งหมด';
    });
    _applyFilters();
  }

  Widget _filterArea() {
    final hasFilter = searchController.text.trim().isNotEmpty ||
        selectedSubdistrict != 'ทั้งหมด' ||
        selectedStatus != 'ทั้งหมด';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'ค้นหาข้อมูล',
                hintText: 'ชื่อ แหล่งเรียนรู้ ตำบล ที่อยู่ หรือรายละเอียด',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedSubdistrict,
                    decoration: const InputDecoration(
                      labelText: 'ตำบล',
                      prefixIcon: Icon(Icons.location_on_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'ทั้งหมด',
                        child: Text('ทุกตำบล'),
                      ),
                      ...subdistricts.map(
                        (s) => DropdownMenuItem(value: s, child: Text(s)),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedSubdistrict = value);
                      _applyFilters();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'สถานะ',
                      prefixIcon: Icon(Icons.verified_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทุกสถานะ')),
                      DropdownMenuItem(value: 'approved', child: Text('อนุมัติแล้ว')),
                      DropdownMenuItem(value: 'pending', child: Text('รอตรวจสอบ')),
                      DropdownMenuItem(value: 'rejected', child: Text('ไม่อนุมัติ')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => selectedStatus = value);
                      _applyFilters();
                    },
                  ),
                ),
              ],
            ),
            if (hasFilter) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('ล้างตัวกรอง'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('เกิดข้อผิดพลาด\n$error', textAlign: TextAlign.center),
        ),
      );
    }

    if (rows.isEmpty) {
      return Column(
        children: [
          _filterArea(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.type.icon, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('ยังไม่มีข้อมูล${widget.type.title}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('เพิ่มข้อมูลแรก'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _filterArea(),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Icon(widget.type.icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'พบ ${filteredRows.length} รายการ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (filteredRows.length != rows.length)
                Text('จากทั้งหมด ${rows.length} รายการ', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: filteredRows.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 100),
                      Icon(Icons.search_off, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Center(child: Text('ไม่พบข้อมูลที่ค้นหา')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filteredRows.length,
                    itemBuilder: (context, index) {
                      final row = filteredRows[index];
                      final status = row['status']?.toString() ?? 'pending';
                      final photoPaths = row['photo_paths'];
                      final photoCount = photoPaths is List ? photoPaths.length : 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(child: Icon(widget.type.icon)),
                          title: Text(
                            row['name']?.toString() ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${row['subdistrict'] ?? '-'}\n'
                              '${_statusText(status)}${photoCount > 0 ? ' • $photoCount รูป' : ''}',
                              style: TextStyle(color: _statusColor(status)),
                            ),
                          ),
                          onTap: () async {
                            final changed = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DataDetailPage(type: widget.type, row: row),
                              ),
                            );
                            if (changed == true) await _load();
                          },
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') _openForm(row);
                              if (value == 'delete') _delete(row);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูล')),
                              if (admin) const PopupMenuItem(value: 'delete', child: Text('ลบข้อมูล')),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.title),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มข้อมูล'),
      ),
      body: _buildBody(context),
    );
  }
}
