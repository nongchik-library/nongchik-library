import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/public_export_service.dart';

const _publicSupabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');
const _publicSupabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://ddldegnsupfeqfzbjjcr.supabase.co');

class PublicPortalPage extends StatefulWidget {
  const PublicPortalPage({super.key});

  @override
  State<PublicPortalPage> createState() => _PublicPortalPageState();
}

class _PublicPortalPageState extends State<PublicPortalPage> {
  int? visitCount;
  bool visitCountLoading = true;

  @override
  void initState() {
    super.initState();
    _recordVisitAndLoadCount();
  }

  Future<void> _recordVisitAndLoadCount() async {
    try {
      final result = await Supabase.instance.client.rpc('record_public_portal_visit');
      if (!mounted) return;
      setState(() {
        visitCount = (result as num).toInt();
        visitCountLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => visitCountLoading = false);
    }
  }

  static const items = <(String, String, IconData, Color)>[
    ('learning_resources', 'แหล่งเรียนรู้', Icons.menu_book_rounded, Color(0xFF16A765)),
    ('local_wisdom', 'ภูมิปัญญาท้องถิ่น', Icons.eco_rounded, Color(0xFF00A6A0)),
    ('local_scholars', 'ปราชญ์ชาวบ้าน', Icons.person_rounded, Color(0xFF7652C8)),
    ('community_book_houses', 'บ้านหนังสือชุมชน', Icons.home_work_rounded, Color(0xFF2789D8)),
    ('subdistrict_learning_centers', 'ศกร.ระดับตำบล', Icons.location_city_rounded, Color(0xFF5365C9)),
    ('tourist_attractions', 'แหล่งท่องเที่ยวในตำบล', Icons.photo_camera_rounded, Color(0xFFE94D83)),
    ('traditional_foods', 'อาหาร/ขนมโบราณในชุมชน', Icons.restaurant_rounded, Color(0xFFE99A27)),
    ('village_book_corners', 'มุมหนังสือหมู่บ้าน', Icons.local_library_rounded, Color(0xFF8752C7)),
    ('community_career_projects', 'โครงการพัฒนาอาชีพชุมชน', Icons.handyman_rounded, Color(0xFF008F87)),
    ('activity_reports', 'รายงานผลกิจกรรม', Icons.assessment_rounded, Color(0xFFB34CC4)),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FC),
    appBar: AppBar(
      title: const Text('คลังความรู้สำหรับประชาชนและผู้เรียน', style: TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: const Color(0xFF087F78), foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
    ),
    body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1240), child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(26, 25, 26, 24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF087F78), Color(0xFF159F9A), Color(0xFF536BCB)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFF087F78).withOpacity(.20), blurRadius: 22, offset: const Offset(0, 10))],
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(.18), borderRadius: BorderRadius.circular(30)), child: const Text('NONGCHIK LEARNING HUB', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.1))),
              const SizedBox(height: 13),
              const Text('เปิดโลกการเรียนรู้\nค้นพบความรู้ใกล้ตัวคุณ', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.25, fontWeight: FontWeight.w900)),
              const SizedBox(height: 9),
              Text('รวบรวมแหล่งเรียนรู้ ภูมิปัญญา และเรื่องราวดี ๆ จากชุมชน\nเลือกชมและค้นคว้าได้ทุกที่ ทุกเวลา', style: TextStyle(color: Colors.white.withOpacity(.92), height: 1.5, fontSize: 13)),
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _heroPill(Icons.auto_stories_rounded, 'เรียนรู้ได้ทุกวัย'),
                _heroPill(Icons.public_rounded, 'ความรู้จากชุมชน'),
                _heroPill(Icons.download_rounded, 'ดาวน์โหลดเอกสาร'),
              ]),
            ])),
            const SizedBox(width: 12),
            Container(width: 118, height: 118, decoration: BoxDecoration(color: Colors.white.withOpacity(.15), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(.25), width: 1.5)), child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 66)),
          ]),
        ),
        const SizedBox(height: 26),
        Row(children: [
          Container(width: 5, height: 28, decoration: BoxDecoration(color: const Color(0xFF0B9287), borderRadius: BorderRadius.circular(8))),
          const SizedBox(width: 10),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('เลือกหมวดหมู่ที่สนใจ', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF183B50))),
            Text('คลิกเพื่อสำรวจข้อมูลและองค์ความรู้ที่เผยแพร่', style: TextStyle(fontSize: 12, color: Color(0xFF718096))),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE1E8F0))), child: Text('${items.length} หมวดหมู่', style: const TextStyle(color: Color(0xFF087F78), fontWeight: FontWeight.w800, fontSize: 12))),
        ]),
        const SizedBox(height: 15),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 570 ? 2 : 1);
          return GridView.count(
            crossAxisCount: columns, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 15, crossAxisSpacing: 15,
            childAspectRatio: columns == 1 ? 4.0 : (columns == 2 ? 2.5 : 2.45),
            children: items.map((item) => _PublicMenuCard(item: item)).toList(),
          );
        }),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6ECF3))), child: const Row(children: [
          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE6A12A), size: 25), SizedBox(width: 11),
          Expanded(child: Text('เรียนรู้ แบ่งปัน และต่อยอดองค์ความรู้ เพื่อพัฒนาชุมชนสู่สังคมแห่งการเรียนรู้ตลอดชีวิต', style: TextStyle(color: Color(0xFF526477), fontSize: 12, height: 1.45, fontWeight: FontWeight.w600))),
        ])),
        const SizedBox(height: 18),
        _buildPortalFooter(),
      ],
    ))),
  );

  Widget _buildPortalFooter() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF075E68), Color(0xFF087F78), Color(0xFF4059A8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: const Color(0xFF087F78).withOpacity(.16), blurRadius: 20, offset: const Offset(0, 8))],
    ),
    child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.groups_rounded, color: Colors.white, size: 27),
        const SizedBox(width: 10),
        const Text('สถิติการเข้าชมคลังความรู้', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.14), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(.22))),
        child: Column(children: [
          Text(visitCountLoading ? 'กำลังโหลด' : (visitCount == null ? '—' : visitCount!.toString()), style: const TextStyle(color: Colors.white, fontSize: 34, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 3),
          Text('จำนวนครั้งที่เข้าชมเว็บไซต์', style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
      const SizedBox(height: 18),
      Container(height: 1, color: Colors.white.withOpacity(.22)),
      const SizedBox(height: 14),
      const Text('จัดทำโดย', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('อาจารย์หับดี ยูโซะ', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900)),
      const SizedBox(height: 3),
      Text('งานการศึกษาตลอดชีวิต', style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text('คลังความรู้เพื่อการเรียนรู้ตลอดชีวิตของชุมชน', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(.72), fontSize: 11)),
    ]),
  );

  static Widget _heroPill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: Colors.white.withOpacity(.16), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(.22))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 14), const SizedBox(width: 5), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))]),
  );
}

class _PublicMenuCard extends StatelessWidget {
  final (String, String, IconData, Color) item;
  const _PublicMenuCard({required this.item});
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    elevation: 0,
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PublicRecordsPage(table: item.$1, title: item.$2, accent: item.$4, icon: item.$3))),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: item.$4.withOpacity(.22), width: 1.2), boxShadow: [BoxShadow(color: item.$4.withOpacity(.055), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(children: [
          Container(width: 58, height: 58, decoration: BoxDecoration(gradient: LinearGradient(colors: [item.$4.withOpacity(.17), item.$4.withOpacity(.07)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(18)), child: Icon(item.$3, color: item.$4, size: 31)),
          const SizedBox(width: 14),
          Expanded(child: Text(item.$2, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF25394B)))),
          Container(width: 30, height: 30, decoration: BoxDecoration(color: item.$4.withOpacity(.09), shape: BoxShape.circle), child: Icon(Icons.arrow_forward_rounded, color: item.$4, size: 17)),
        ]),
      ),
    ),
  );
}

class PublicRecordsPage extends StatefulWidget {
  final String table;
  final String title;
  final Color accent;
  final IconData icon;
  const PublicRecordsPage({super.key, required this.table, required this.title, required this.accent, required this.icon});
  @override
  State<PublicRecordsPage> createState() => _PublicRecordsPageState();
}

class _PublicRecordsPageState extends State<PublicRecordsPage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController search = TextEditingController();
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() { super.initState(); load(); }
  @override
  void dispose() { search.dispose(); super.dispose(); }

  Future<void> load() async {
    try {
      // Public views expose only records explicitly published by Admin.
      final data = await client.from('public_${widget.table}').select('id,data');
      if (!mounted) return;
      setState(() { rows = List<Map<String, dynamic>>.from(data).map((r) => Map<String, dynamic>.from(r['data'] as Map)).toList(); loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { error = e.toString(); loading = false; });
    }
  }

  String titleOf(Map<String, dynamic> row) {
    for (final key in ['name', 'title', 'project_title', 'activity_name', 'course_name']) {
      final value = row[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return 'รายการข้อมูล';
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filtered = rows.where((row) => query.isEmpty || row.values.any((v) => v?.toString().toLowerCase().contains(query) ?? false)).toList();
    Widget content;
    if (loading) { content = const Center(child: CircularProgressIndicator()); }
    else if (error != null) { content = Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('ไม่สามารถโหลดข้อมูลได้\n$error', textAlign: TextAlign.center))); }
    else if (filtered.isEmpty) { content = const Center(child: Text('ยังไม่มีข้อมูลที่ผู้ดูแลระบบอนุญาตให้เผยแพร่')) ; }
    else {
      content = ListView.separated(padding: const EdgeInsets.fromLTRB(16, 0, 16, 20), itemCount: filtered.length, separatorBuilder: (_, __) => const SizedBox(height: 10), itemBuilder: (context, index) {
        final row = filtered[index];
        final subtitle = [row['subdistrict'], row['address'], row['venue'], row['activity_date']].where((v) => v != null && v.toString().isNotEmpty).join(' • ');
        return Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: widget.accent.withOpacity(.20))), child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9), leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: widget.accent.withOpacity(.11), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.article_outlined, color: widget.accent)), title: Text(titleOf(row), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: subtitle.isEmpty ? null : Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis)), trailing: Icon(Icons.chevron_right, color: widget.accent), onTap: () => showDialog<void>(context: context, builder: (_) => _PublicRecordDialog(title: titleOf(row), menuTitle: widget.title, row: row, accent: widget.accent))));
      });
    }
    return Scaffold(backgroundColor: widget.accent.withOpacity(.055), appBar: AppBar(elevation: 0, foregroundColor: Colors.white, title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w800)), flexibleSpace: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.accent, Color.lerp(widget.accent, const Color(0xFF172B70), .30)!], begin: Alignment.centerLeft, end: Alignment.centerRight))), leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)), actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh_rounded), tooltip: 'รีเฟรช')]), body: Column(children: [
      Container(margin: const EdgeInsets.fromLTRB(16, 16, 16, 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.accent.withOpacity(.12), Colors.white], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(18), border: Border.all(color: widget.accent.withOpacity(.20))), child: Row(children: [Container(width: 46, height: 46, decoration: BoxDecoration(color: widget.accent.withOpacity(.14), borderRadius: BorderRadius.circular(14)), child: Icon(widget.icon, color: widget.accent, size: 26)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.title, style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900, fontSize: 16)), Text('คลังข้อมูลที่เผยแพร่สำหรับประชาชน', style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12))]))])),
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: TextField(controller: search, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: Icon(Icons.search, color: widget.accent), hintText: 'ค้นหาข้อมูล', filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 15), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: widget.accent.withOpacity(.22))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: widget.accent, width: 1.6))))),
      Expanded(child: content),
    ]));
  }
}

class _PublicRecordDialog extends StatefulWidget {
  final String title;
  final String menuTitle;
  final Map<String, dynamic> row;
  final Color accent;
  const _PublicRecordDialog({required this.title, required this.menuTitle, required this.row, required this.accent});

  @override
  State<_PublicRecordDialog> createState() => _PublicRecordDialogState();
}

class _PublicRecordDialogState extends State<_PublicRecordDialog> {
  bool exporting = false;

  static const _thaiFieldLabels = <String, String>{
    'name':'ชื่อข้อมูล','title':'ชื่อเรื่อง','project_title':'ชื่อโครงการ','activity_name':'ชื่อกิจกรรม',
    'description':'รายละเอียด','subdistrict':'ตำบล','address':'ที่อยู่','contact':'ช่องทางติดต่อ',
    'extra_info':'ข้อมูลเพิ่มเติม','latitude':'ละติจูด','longitude':'ลองจิจูด','status':'สถานะ',
    'first_name':'ชื่อ','last_name':'นามสกุล','position':'ตำแหน่ง','contact_phone':'หมายเลขโทรศัพท์',
    'contact_line':'ไลน์','contact_facebook':'เฟซบุ๊ก','contact_tiktok':'ติ๊กต็อก','gender':'เพศ',
    'birth_date':'วันเดือนปีเกิด','education_level':'ระดับการศึกษา','current_occupation':'อาชีพปัจจุบัน',
    'responsible_teacher':'ครูผู้รับผิดชอบ','learning_process':'กระบวนการจัดการเรียนรู้',
    'background_history':'ประวัติความเป็นมา','resource_history':'ประวัติแหล่งเรียนรู้','awards':'รางวัลและผลงาน',
    'building_use':'ลักษณะการใช้ประโยชน์อาคาร','permission_case':'การได้รับอนุญาต','independence':'ความเป็นอิสระ',
    'weekday_hours':'เวลาเปิดให้บริการวันธรรมดา','weekend_hours':'เวลาเปิดให้บริการวันหยุด',
    'opening_days':'วันเปิดให้บริการ','learner_capacity':'รองรับผู้เรียน','parking_capacity':'รองรับที่จอดรถ',
    'internet':'อินเทอร์เน็ต','water_supply':'น้ำประปา','electricity':'ไฟฟ้า','toilet':'ห้องน้ำ',
    'notebook':'คอมพิวเตอร์โน้ตบุ๊ก','desktop':'คอมพิวเตอร์ตั้งโต๊ะ','tv':'โทรทัศน์','tablet':'แท็บเล็ต',
    'projector':'เครื่องฉายภาพ','tables':'โต๊ะ','chairs':'เก้าอี้','course_name':'หลักสูตร',
    'activity_duration':'ระยะเวลา','target_group':'กลุ่มเป้าหมาย','male_count':'ผู้เข้าร่วมชาย (คน)',
    'female_count':'ผู้เข้าร่วมหญิง (คน)','participants_count':'จำนวนผู้เข้าร่วมทั้งหมด (คน)',
    'venue':'สถานที่จัดกิจกรรม','details':'รายละเอียดโครงการ','objectives':'วัตถุประสงค์',
    'outcomes':'ผลการดำเนินงาน','problems':'ปัญหาและอุปสรรค','suggestions':'ข้อเสนอแนะ',
    'activity_date':'วันที่จัดกิจกรรม','activity_type':'ประเภทกิจกรรม','activity_details':'รายละเอียดกิจกรรม',
    'age_min':'อายุต่ำสุด','age_max':'อายุสูงสุด','age_under_15':'อายุต่ำกว่า 15 ปี (คน)',
    'age_15_25':'อายุ 15–25 ปี (คน)','age_26_40':'อายุ 26–40 ปี (คน)',
    'age_41_59':'อายุ 41–59 ปี (คน)','age_60_plus':'อายุ 60 ปีขึ้นไป (คน)',
    'learning_area':'พื้นที่เรียนรู้','food_name':'ชื่ออาหาร/ขนม','ingredients':'วัตถุดิบ',
    'how_to_make':'วิธีทำ','history':'ประวัติ','tourism_type':'ประเภทแหล่งท่องเที่ยว',
    'location':'ที่ตั้ง','phone':'โทรศัพท์','email':'อีเมล','website':'เว็บไซต์',
    'village':'หมู่บ้าน','moo':'หมู่ที่','community':'ชุมชน','category':'ประเภท','type':'ประเภท',
    'organization':'หน่วยงาน','school':'สถานศึกษา','teacher':'ครูผู้รับผิดชอบ',
    'project_name':'ชื่อโครงการ','budget':'งบประมาณ','start_date':'วันที่เริ่มต้น','end_date':'วันที่สิ้นสุด',
    'quantity':'จำนวน','unit':'หน่วย','price':'ราคา','benefits':'ประโยชน์','materials':'วัสดุอุปกรณ์',
    'procedure':'ขั้นตอนการดำเนินงาน','result':'ผลที่ได้รับ','created_at':'วันที่บันทึกข้อมูล',
    'updated_at':'วันที่ปรับปรุงข้อมูล',
  };

  String _thaiLabel(String key) {
    return _thaiFieldLabels[key] ?? _thaiFieldLabels[key.toLowerCase()] ?? 'รายละเอียดเพิ่มเติม';
  }

  String _thaiValue(String key, dynamic value) {
    final text = value is List ? value.join(', ') : value.toString();
    if (key == 'status') {
      return {'approved':'อนุมัติแล้ว','pending':'รอตรวจสอบ','rejected':'ไม่อนุมัติ'}[text] ?? text;
    }
    if (key == 'gender') {
      return {'male':'ชาย','female':'หญิง'}[text] ?? text;
    }
    return text;
  }

  List<String> _photoIds() {
    final value = widget.row['photo_drive_ids'];
    if (value is List) return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    return [];
  }

  Future<void> _export(String type) async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      if (type == 'pdf') {
        await PublicExportService.exportPdf(widget.menuTitle, widget.title, widget.row);
      } else if (type == 'word') {
        await PublicExportService.exportWord(widget.menuTitle, widget.title, widget.row);
      } else {
        await PublicExportService.exportExcel(widget.menuTitle, widget.title, widget.row);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('จัดทำไฟล์ ${type.toUpperCase()} เรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งออกไฟล์ไม่สำเร็จ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const excluded = {'id', 'created_by', 'updated_at', 'created_at', 'is_public', 'rejection_reason'};
    final photos = _photoIds();
    final entries = widget.row.entries.where((e) => !excluded.contains(e.key) && !{'photo_drive_ids','photo_paths','certificate_paths','certificate_drive_ids'}.contains(e.key) && e.value != null && e.value.toString().trim().isNotEmpty).toList();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(children: [Container(width: 8, height: 28, decoration: BoxDecoration(color: widget.accent, borderRadius: BorderRadius.circular(8))), const SizedBox(width: 10), Expanded(child: Text(widget.title, style: TextStyle(color: widget.accent, fontWeight: FontWeight.w900)))]),
      content: SizedBox(width: 620, child: SingleChildScrollView(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          if (photos.isNotEmpty) ...[
            Text('ภาพประกอบ', style: TextStyle(fontWeight: FontWeight.w800, color: widget.accent)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: photos.map((id) {
              final imageUrl = '$_publicSupabaseUrl/functions/v1/drive-image?file_id=${Uri.encodeQueryComponent(id)}&thumb=1&size=480';
              return ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(
                imageUrl, width: 112, height: 90, fit: BoxFit.cover,
                headers: {'apikey': _publicSupabaseKey, 'Authorization': 'Bearer $_publicSupabaseKey'},
                errorBuilder: (_, __, ___) => Container(width: 112, height: 90, color: Colors.black12, child: const Icon(Icons.broken_image_outlined)),
              ));
            }).toList()),
            const SizedBox(height: 16),
          ],
          ...entries.map((entry) {
            final value = entry.value is List ? (entry.value as List).join(', ') : entry.value.toString();
            return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_thaiLabel(entry.key), style: TextStyle(fontWeight: FontWeight.w800, color: widget.accent)),
                const SizedBox(height: 3), SelectableText(_thaiValue(entry.key, entry.value)),
              ],
            ));
          }),
        ],
      ))),
      actions: [
        if (exporting) const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        TextButton.icon(style: TextButton.styleFrom(foregroundColor: widget.accent), onPressed: exporting ? null : () => _export('pdf'), icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
        TextButton.icon(style: TextButton.styleFrom(foregroundColor: widget.accent), onPressed: exporting ? null : () => _export('word'), icon: const Icon(Icons.description), label: const Text('Word')),
        TextButton.icon(style: TextButton.styleFrom(foregroundColor: widget.accent), onPressed: exporting ? null : () => _export('excel'), icon: const Icon(Icons.table_chart), label: const Text('Excel')),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
      ],
    );
  }
}
