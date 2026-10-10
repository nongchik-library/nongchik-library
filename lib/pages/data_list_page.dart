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
  villageBookCorner,
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
      case DataType.villageBookCorner:
        return 'village_book_corners';
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
      case DataType.villageBookCorner:
        return 'มุมหนังสือหมู่บ้าน';
    }
  }

  String get displayTitle => this == DataType.subdistrictLearningCenter ? ' ศกร.ระดับตำบล' : title;

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
      case DataType.villageBookCorner:
        return Icons.local_library;
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

  List<Color> get _gradientColors {
    switch (widget.type) {
      case DataType.learningResource:
        return const [Color(0xFF00796B), Color(0xFF26A69A), Color(0xFF80CBC4)];
      case DataType.localWisdom:
        return const [Color(0xFF2E7D32), Color(0xFF66BB6A), Color(0xFFA5D6A7)];
      case DataType.localScholar:
        return const [Color(0xFF6A1B9A), Color(0xFFAB47BC), Color(0xFFE1BEE7)];
      case DataType.communityBookHouse:
        return const [Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFBBDEFB)];
      case DataType.subdistrictLearningCenter:
        return const [Color(0xFF3949AB), Color(0xFF5C6BC0), Color(0xFFC5CAE9)];
      case DataType.touristAttraction:
        return const [Color(0xFFE65100), Color(0xFFFF8A65), Color(0xFFFFCC80)];
      case DataType.traditionalFood:
        return const [Color(0xFFF57C00), Color(0xFFFFB300), Color(0xFFFFE082)];
      case DataType.villageBookCorner:
        return const [Color(0xFF00838F), Color(0xFF26C6DA), Color(0xFFB2EBF2)];
    }
  }

  Color get _accent => _gradientColors.first;

  BoxDecoration get _pageDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        _gradientColors[2].withOpacity(.16),
        const Color(0xFFF8FBFC),
        _gradientColors[1].withOpacity(.08),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  Widget _sectionHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 2),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: _accent.withOpacity(.20), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.20),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(.35)),
            ),
            child: Icon(widget.type.icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.type.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('คลังข้อมูล • ${filteredRows.length} รายการ', style: TextStyle(color: Colors.white.withOpacity(.88), fontSize: 12.5)),
              ],
            ),
          ),
          if (rows.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(14)),
              child: Text('${rows.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ),
        ],
      ),
    );
  }

  Widget _filterArea() {
    final hasFilter = searchController.text.trim().isNotEmpty ||
        selectedSubdistrict != 'ทั้งหมด' ||
        selectedStatus != 'ทั้งหมด';

    InputDecoration fieldDecoration(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _accent),
      filled: true,
      fillColor: Colors.white.withOpacity(.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: _accent.withOpacity(.16))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: _accent.withOpacity(.18))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: _accent, width: 2)),
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withOpacity(.13)),
        boxShadow: [BoxShadow(color: _accent.withOpacity(.08), blurRadius: 18, offset: const Offset(0, 7))],
      ),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: fieldDecoration('ค้นหาข้อมูล', Icons.search).copyWith(hintText: 'ชื่อ แหล่งเรียนรู้ ตำบล ที่อยู่ หรือรายละเอียด',
              prefixIcon: Icon(Icons.search, color: _accent),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(onPressed: searchController.clear, icon: const Icon(Icons.clear))
                  : null,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedSubdistrict,
                  decoration: fieldDecoration('ตำบล', Icons.location_on_outlined),
                  items: [
                    const DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทุกตำบล')),
                    ...subdistricts.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                  ],
                  onChanged: (value) { if (value == null) return; setState(() => selectedSubdistrict = value); _applyFilters(); },
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  decoration: fieldDecoration('สถานะ', Icons.verified_outlined),
                  items: const [
                    DropdownMenuItem(value: 'ทั้งหมด', child: Text('ทุกสถานะ')),
                    DropdownMenuItem(value: 'approved', child: Text('อนุมัติแล้ว')),
                    DropdownMenuItem(value: 'pending', child: Text('รอตรวจสอบ')),
                    DropdownMenuItem(value: 'rejected', child: Text('ไม่อนุมัติ')),
                  ],
                  onChanged: (value) { if (value == null) return; setState(() => selectedStatus = value); _applyFilters(); },
                ),
              ),
            ],
          ),
          if (hasFilter) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: _accent),
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('ล้างตัวกรอง'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (loading) return Center(child: CircularProgressIndicator(color: _accent));

    if (error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('เกิดข้อผิดพลาด\n$error', textAlign: TextAlign.center)));
    }

    if (rows.isEmpty) {
      // Empty state must remain scrollable on smaller browser windows.
      // This prevents the bottom action from causing RenderFlex overflow.
      return Column(
        children: [
          _filterArea(),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 120),
              children: [
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.88),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _accent.withOpacity(.10)),
                    boxShadow: [
                      BoxShadow(color: _accent.withOpacity(.10), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: _gradientColors),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.type.icon, size: 38, color: Colors.white),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        'ยังไม่มีข้อมูล${widget.type.displayTitle}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'เริ่มต้นจัดเก็บข้อมูลในหมวดนี้ได้ทันที',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 48,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: _gradientColors),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(color: _accent.withOpacity(.20), blurRadius: 12, offset: const Offset(0, 6)),
                            ],
                          ),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 22),
                            ),
                            onPressed: () => _openForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('เพิ่มข้อมูลแรก', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _filterArea(),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 6),
          child: Row(children: [
            Icon(widget.type.icon, size: 20, color: _accent), const SizedBox(width: 8),
            Text('พบ ${filteredRows.length} รายการ', style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            if (filteredRows.length != rows.length) Text('จากทั้งหมด ${rows.length} รายการ', style: TextStyle(color: Colors.grey.shade600)),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: _accent,
            onRefresh: _load,
            child: filteredRows.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    const SizedBox(height: 100), Icon(Icons.search_off, size: 58, color: Colors.grey), const SizedBox(height: 12), Center(child: Text('ไม่พบข้อมูลที่ค้นหา')),
                  ])
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 100),
                    itemCount: filteredRows.length,
                    itemBuilder: (context, index) {
                      final row = filteredRows[index];
                      final status = row['status']?.toString() ?? 'pending';
                      final photoPaths = row['photo_paths'];
                      final photoCount = photoPaths is List ? photoPaths.length : 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(.92), borderRadius: BorderRadius.circular(20), border: Border.all(color: _accent.withOpacity(.10)), boxShadow: [BoxShadow(color: _accent.withOpacity(.07), blurRadius: 14, offset: const Offset(0, 6))]),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                          leading: Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: _gradientColors), borderRadius: BorderRadius.circular(15)), child: Icon(widget.type.icon, color: Colors.white)),
                          title: Text(row['name']?.toString() ?? '-', style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 7, runSpacing: 5, children: [
                            _chip(Icons.location_on_outlined, row['subdistrict']?.toString() ?? '-', _accent),
                            _chip(Icons.verified_outlined, _statusText(status), _statusColor(status)),
                            if (photoCount > 0) _chip(Icons.photo_library_outlined, '$photoCount รูป', Colors.blueGrey),
                          ])),
                          onTap: () async { final changed = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => DataDetailPage(type: widget.type, row: row))); if (changed == true) await _load(); },
                          trailing: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: _accent),
                            onSelected: (value) { if (value == 'edit') _openForm(row); if (value == 'delete') _delete(row); },
                            itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('แก้ไขข้อมูล')), if (admin) const PopupMenuItem(value: 'delete', child: Text('ลบข้อมูล'))],
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

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(.14))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(text, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w700))]),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: _gradientColors, begin: Alignment.centerLeft, end: Alignment.centerRight))),
        titleSpacing: 0,
        title: Row(children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(11)), child: Icon(widget.type.icon, size: 21, color: Colors.white)),
          const SizedBox(width: 10),
          Text(widget.type.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          Container(margin: const EdgeInsets.only(right: 10, top: 8, bottom: 8), decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(13)), child: IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: 'รีเฟรช')),
        ],
      ),
      floatingActionButton: DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(colors: _gradientColors), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: _accent.withOpacity(.25), blurRadius: 15, offset: const Offset(0, 7))]),
        child: FloatingActionButton.extended(backgroundColor: Colors.transparent, elevation: 0, onPressed: () => _openForm(), icon: const Icon(Icons.add), label: const Text('เพิ่มข้อมูล', style: TextStyle(fontWeight: FontWeight.w800))),
      ),
      body: Container(decoration: _pageDecoration, child: Column(children: [_sectionHeader(), Expanded(child: _buildBody(context))])),
    );
  }

}
