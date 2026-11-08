import 'dart:typed_data';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/google_drive_service.dart';

// Read the same public key passed to Flutter at build/run time.
const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: '',
);

class CommunityCareerProjectsPage extends StatefulWidget {
  const CommunityCareerProjectsPage({super.key});
  @override
  State<CommunityCareerProjectsPage> createState() => _CommunityCareerProjectsPageState();
}

class _CommunityCareerProjectsPageState extends State<CommunityCareerProjectsPage> {
  final db = Supabase.instance.client;
  final drive = GoogleDriveService();
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = [];
  bool loading = true, admin = false;
  String subdistrict = '';
  static const districts = ['เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง','ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี'];

  @override
  void initState() { super.initState(); search.addListener(_refresh); _load(); }
  @override
  void dispose() { search.removeListener(_refresh); search.dispose(); super.dispose(); }
  void _refresh() { if (mounted) setState(() {}); }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final user = db.auth.currentUser;
      if (user == null) throw Exception('กรุณาเข้าสู่ระบบใหม่');
      final profile = await db.from('profiles').select('role,subdistrict').eq('id', user.id).maybeSingle();
      final data = await db.from('community_career_projects').select().order('created_at', ascending: false);
      if (!mounted) return;
      setState(() { admin = profile?['role'] == 'admin'; subdistrict = (profile?['subdistrict'] ?? '').toString(); rows = List<Map<String,dynamic>>.from(data); loading = false; });
    } catch (e) { if (mounted) setState(() => loading = false); }
  }

  List<Map<String,dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();
    return rows.where((r) => [r['project_title'],r['course_name'],r['target_group'],r['subdistrict'],r['venue']].join(' ').toLowerCase().contains(q)).toList();
  }

  Future<void> _form({Map<String, dynamic>? row}) async {
    // Use a dedicated page instead of a Dialog. This avoids the web layout
    // constraint/RenderFlex failures that could leave the screen dimmed.
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => _CareerForm(
          existing: row,
          defaultSubdistrict: subdistrict,
          isAdmin: admin,
          db: db,
          drive: drive,
        ),
      ),
    );
    if (ok == true && mounted) await _load();
  }

  Future<void> _togglePublic(Map<String, dynamic> row) async {
    if (!admin) return;
    final next = row['is_public'] != true;
    try {
      await db.from('community_career_projects').update({'is_public': next}).eq('id', row['id']);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next ? 'เผยแพร่โครงการแล้ว' : 'ยกเลิกเผยแพร่โครงการแล้ว')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เปลี่ยนสถานะเผยแพร่ไม่สำเร็จ: $e')));
    }
  }

  Future<void> _delete(Map<String,dynamic> row) async {
    final yes = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('ยืนยันการลบ'), content: Text('ต้องการลบโครงการ “${row['project_title']}” ใช่หรือไม่?'), actions: [TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('ยกเลิก')), FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('ลบ'))]));
    if (yes != true) return;
    try { await db.from('community_career_projects').delete().eq('id', row['id']); _load(); } catch(e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('ลบไม่สำเร็จ: $e'))); }
  }

  String _driveImageUrl(String fileId, {bool thumbnail = true}) {
    final uri = Uri.parse('https://ddldegnsupfeqfzbjjcr.supabase.co/functions/v1/drive-image').replace(
      queryParameters: {
        'file_id': fileId,
        if (thumbnail) 'thumb': '1',
        if (thumbnail) 'size': '480',
      },
    );
    return uri.toString();
  }

  Map<String, String> _driveImageHeaders() {
    final token = db.auth.currentSession?.accessToken;
    return {
      'apikey': _supabasePublishableKey,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _openDetails(Map<String, dynamic> row) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CareerProjectDetailPage(
          row: row,
          imageUrl: _driveImageUrl,
          imageHeaders: _driveImageHeaders(),
        ),
      ),
    );
  }

  Widget _projectCard(Map<String, dynamic> row) {
    final canEdit = admin || row['created_by'] == db.auth.currentUser?.id;
    final photoIds = List<String>.from(row['photo_drive_ids'] ?? const []);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(row),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE4F4F1),
                  child: Icon(Icons.handyman_outlined, color: Color(0xFF087F78)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${(row['project_title'] ?? '').toString().trim().isEmpty ? '(ยังไม่ได้ระบุชื่อโครงการ)' : row['project_title']}',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                if (canEdit)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _form(row: row);
                      if (value == 'delete') _delete(row);
                      if (value == 'publish') _togglePublic(row);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('แก้ไข')),
                      if (admin) PopupMenuItem(value: 'publish', child: Text(row['is_public'] == true ? 'ยกเลิกเผยแพร่' : 'เผยแพร่ให้ประชาชน')),
                      if (admin) const PopupMenuItem(value: 'delete', child: Text('ลบ')),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text('หลักสูตร: ${row['course_name'] ?? '-'}'),
            Text('ระยะเวลา: ${row['activity_duration'] ?? '-'}'),
            Text('กลุ่มเป้าหมาย: ${row['target_group'] ?? '-'}'),
            Text('ตำบล: ${row['subdistrict'] ?? '-'}  •  สถานที่: ${row['venue'] ?? '-'}'),
            Text('ผู้เข้าร่วม ชาย ${row['male_count'] ?? 0} / หญิง ${row['female_count'] ?? 0} คน (รวม ${row['participants_count'] ?? 0} คน)'),
            if (admin) Text(row['is_public'] == true ? 'สถานะเผยแพร่: เผยแพร่แล้ว' : 'สถานะเผยแพร่: ยังไม่เผยแพร่', style: TextStyle(fontSize: 12, color: row['is_public'] == true ? Colors.teal : Colors.blueGrey, fontWeight: FontWeight.w700)),
            if ((row['details'] ?? '').toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(row['details'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
              ),
            if (photoIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 7,
                  children: photoIds.take(5).map((id) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _driveImageUrl(id),
                        headers: _driveImageHeaders(),
                        width: 70,
                        height: 62,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(
                          width: 70,
                          height: 62,
                          child: Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = rows.fold<int>(
      0,
      (sum, row) => sum + (row['participants_count'] as num? ?? 0).toInt(),
    );
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text('โครงการพัฒนาอาชีพชุมชน'),
        backgroundColor: const Color(0xFF087F78),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        backgroundColor: const Color(0xFF087F78),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มโครงการ'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF087F78), Color(0xFF25A18E)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ฐานข้อมูลโครงการพัฒนาอาชีพชุมชน', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('โครงการ ${rows.length} รายการ  •  ผู้เข้าร่วม $total คน', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อโครงการ / หลักสูตร / ตำบล',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  Icon(Icons.work_outline, size: 42, color: Colors.blueGrey),
                  SizedBox(height: 8),
                  Text('ยังไม่มีข้อมูลโครงการพัฒนาอาชีพชุมชน', textAlign: TextAlign.center),
                ],
              ),
            )
          else
            ...filtered.map(_projectCard),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

}

class _CareerForm extends StatefulWidget {
  final Map<String,dynamic>? existing; final String defaultSubdistrict; final bool isAdmin; final SupabaseClient db; final GoogleDriveService drive;
  const _CareerForm({required this.existing,required this.defaultSubdistrict,required this.isAdmin,required this.db,required this.drive});
  @override State<_CareerForm> createState()=>_CareerFormState();
}
class _CareerFormState extends State<_CareerForm> {
  final form=GlobalKey<FormState>(); final picker=ImagePicker();
  late final TextEditingController title,course,duration,target,male,female,venue,details,objectives,outcomes,problems,suggestions;
  late String district; final List<XFile> photos=[]; late List<String> oldPhotos; bool saving=false;
  @override void initState(){super.initState();final r=widget.existing??{}; title=TextEditingController(text:r['project_title']??'');course=TextEditingController(text:r['course_name']??'');duration=TextEditingController(text:r['activity_duration']??'');target=TextEditingController(text:r['target_group']??'');male=TextEditingController(text:'${r['male_count']??0}');female=TextEditingController(text:'${r['female_count']??0}');venue=TextEditingController(text:r['venue']??'');details=TextEditingController(text:r['details']??'');objectives=TextEditingController(text:r['objectives']??'');outcomes=TextEditingController(text:r['outcomes']??'');problems=TextEditingController(text:r['problems']??'');suggestions=TextEditingController(text:r['suggestions']??'');district=(r['subdistrict']??widget.defaultSubdistrict).toString();if(! _CareerFormState.districts.contains(district))district='ดาโต๊ะ';oldPhotos=List<String>.from(r['photo_drive_ids']??const[]);male.addListener(_refresh);female.addListener(_refresh);}
  static const districts=['เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง','ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี'];
  void _refresh() {
    if (mounted) setState(() {});
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int lines = 1,
    bool required = false,
    bool number = false,
  }) {
    String? validator(String? value) {
      final text = value?.trim() ?? '';
      if (required && text.isEmpty) return 'กรุณากรอก$label';
      if (number) {
        final parsed = int.tryParse(text);
        if (parsed == null || parsed < 0) return 'กรุณากรอกจำนวนตั้งแต่ 0 ขึ้นไป';
      }
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : null,
        validator: (required || number) ? validator : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF6F8FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(11),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _pick()async{final p=await picker.pickMultiImage(imageQuality:82);if(p.isNotEmpty)setState(()=>photos.addAll(p));}
  Future<void> _save()async{if(!form.currentState!.validate())return;setState(()=>saving=true);try{final user=widget.db.auth.currentUser;if(user==null)throw Exception('กรุณาเข้าสู่ระบบใหม่');final ids=[...oldPhotos];for(final p in photos){final Uint8List bytes=await p.readAsBytes();final result=await widget.drive.upload(bytes:bytes,fileName:p.name,mimeType:p.mimeType??'image/jpeg',folderName:'$district/โครงการพัฒนาอาชีพชุมชน',category:'other',subdistrict:district);final id=(result['id']??'').toString();if(id.isNotEmpty)ids.add(id);}final m=int.parse(male.text),f=int.parse(female.text);final payload=<String,dynamic>{'project_title':title.text.trim(),'course_name':course.text.trim(),'activity_duration':duration.text.trim(),'target_group':target.text.trim(),'male_count':m,'female_count':f,'participants_count':m+f,'subdistrict':district,'venue':venue.text.trim(),'details':details.text.trim(),'objectives':objectives.text.trim(),'outcomes':outcomes.text.trim(),'problems':problems.text.trim(),'suggestions':suggestions.text.trim(),'photo_drive_ids':ids};if(widget.existing==null){payload['created_by']=user.id;await widget.db.from('community_career_projects').insert(payload);}else{await widget.db.from('community_career_projects').update(payload).eq('id',widget.existing!['id']);}if(mounted)Navigator.pop(context,true);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('บันทึกไม่สำเร็จ: $e'),backgroundColor:Colors.red));}finally{if(mounted)setState(()=>saving=false);}}
  @override void dispose(){male.removeListener(_refresh);female.removeListener(_refresh);for(final c in [title,course,duration,target,male,female,venue,details,objectives,outcomes,problems,suggestions]){c.dispose();}super.dispose();}
  @override
  Widget build(BuildContext context) {
    final total = (int.tryParse(male.text) ?? 0) +
        (int.tryParse(female.text) ?? 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'เพิ่มโครงการพัฒนาอาชีพชุมชน'
            : 'แก้ไขโครงการพัฒนาอาชีพชุมชน'),
        backgroundColor: const Color(0xFF087F78),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: saving ? null : () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _field('ชื่อโครงการ/กิจกรรม *', title, required: true),
              _field('ชื่อหลักสูตร *', course, required: true),
              _field('ระยะเวลาจัดกิจกรรม', duration),
              _field('กลุ่มเป้าหมาย', target),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('จำนวนผู้เข้าร่วม',
                    style: TextStyle(fontWeight: FontWeight.w900)),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _field('ชาย (คน)', male, number: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _field('หญิง (คน)', female, number: true)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F5F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('รวมผู้เข้าร่วม $total คน',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF087F78))),
              ),
              DropdownButtonFormField<String>(
                value: district,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'ตำบล',
                  border: OutlineInputBorder(),
                ),
                items: districts
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: widget.isAdmin
                    ? (v) => setState(() => district = v ?? district)
                    : null,
              ),
              const SizedBox(height: 12),
              _field('สถานที่จัดกิจกรรม', venue),
              _field('รายละเอียดโครงการ', details, lines: 3),
              _field('วัตถุประสงค์', objectives, lines: 2),
              _field('ผลที่ได้รับ', outcomes, lines: 3),
              _field('ปัญหา/อุปสรรค', problems, lines: 2),
              _field('ข้อเสนอแนะ', suggestions, lines: 2),
              OutlinedButton.icon(
                onPressed: saving ? null : _pick,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text('เพิ่มภาพกิจกรรม (${oldPhotos.length + photos.length} ภาพ)'),
              ),
              if (photos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('เลือกภาพใหม่ ${photos.length} ภาพ'),
                ),
              if (oldPhotos.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('มีภาพเดิม ${oldPhotos.length} ภาพใน Google Drive'),
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087F78),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(saving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล'),
              ),
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(context, false),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

}


class _CareerProjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> row;
  final String Function(String, {bool thumbnail}) imageUrl;
  final Map<String, String> imageHeaders;
  const _CareerProjectDetailPage({required this.row, required this.imageUrl, required this.imageHeaders});
  @override
  State<_CareerProjectDetailPage> createState() => _CareerProjectDetailPageState();
}

class _CareerProjectDetailPageState extends State<_CareerProjectDetailPage> {
  bool exporting = false;
  List<String> get photoIds => List<String>.from(widget.row['photo_drive_ids'] ?? const []);
  String value(String key) => (widget.row[key] ?? '').toString().trim().isEmpty ? '-' : (widget.row[key] ?? '').toString().trim();
  String get title => value('project_title');
  static String xml(String s) => s.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&apos;');

  // The bundled Thai font is a subset and omits some ASCII punctuation/digits.
  // Route Thai Unicode characters to Noto Sans Thai and all other characters
  // (digits, slash, hyphen, spaces, etc.) to the embedded Latin font.
  pw.Widget _pdfText(String text, pw.Font thai, {bool bold = false, double size = 11, PdfColor? color, pw.TextAlign align = pw.TextAlign.left}) {
    final latin = bold ? pw.Font.helveticaBold() : pw.Font.helvetica();
    final spans = <pw.TextSpan>[];
    for (final match in RegExp(r'[\u0E00-\u0E7F]+|[^\u0E00-\u0E7F]+').allMatches(text)) {
      final part = match.group(0)!;
      final isThai = RegExp(r'^[\u0E00-\u0E7F]+$').hasMatch(part);
      spans.add(pw.TextSpan(
        text: part,
        style: pw.TextStyle(font: isThai ? thai : latin, fontSize: size, color: color),
      ));
    }
    return pw.RichText(text: pw.TextSpan(children: spans), textAlign: align);
  }

  List<MapEntry<String,String>> get fields => [
    MapEntry('ชื่อโครงการ/กิจกรรม', value('project_title')),
    MapEntry('ชื่อหลักสูตร', value('course_name')),
    MapEntry('ระยะเวลาจัดกิจกรรม', value('activity_duration')),
    MapEntry('กลุ่มเป้าหมาย', value('target_group')),
    MapEntry('จำนวนผู้เข้าร่วมชาย', '${widget.row['male_count'] ?? 0} คน'),
    MapEntry('จำนวนผู้เข้าร่วมหญิง', '${widget.row['female_count'] ?? 0} คน'),
    MapEntry('รวมผู้เข้าร่วม', '${widget.row['participants_count'] ?? 0} คน'),
    MapEntry('ตำบล', value('subdistrict')),
    MapEntry('สถานที่จัดกิจกรรม', value('venue')),
    MapEntry('รายละเอียดโครงการ', value('details')),
    MapEntry('วัตถุประสงค์', value('objectives')),
    MapEntry('ผลที่ได้รับ', value('outcomes')),
    MapEntry('ปัญหา/อุปสรรค', value('problems')),
    MapEntry('ข้อเสนอแนะ', value('suggestions')),
  ];

  void download(Uint8List bytes, String filename, String mime) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: url)..download = filename..style.display = 'none';
    html.document.body?.children.add(a); a.click(); a.remove(); html.Url.revokeObjectUrl(url);
  }

  Future<List<Uint8List>> loadPhotos() async {
    final result = <Uint8List>[];
    for (final id in photoIds) {
      try {
        final r = await http.get(Uri.parse(widget.imageUrl(id, thumbnail: false)), headers: widget.imageHeaders);
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) result.add(r.bodyBytes);
      } catch (_) {}
    }
    return result;
  }

  Future<Uint8List> makePdf() async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansThai-Bold.ttf'));
    final photos = await loadPhotos();
    final doc = pw.Document();
    final teal = PdfColor.fromInt(0xFF087F78);
    final pale = PdfColor.fromInt(0xFFE8F5F3);
    final dark = PdfColor.fromInt(0xFF263238);
    final rows = <pw.TableRow>[
      pw.TableRow(decoration: pw.BoxDecoration(color: teal), children: [
        for (final label in ['รายการ', 'รายละเอียด'])
          pw.Padding(padding: const pw.EdgeInsets.all(9), child: _pdfText(label, bold, size: 12, color: PdfColors.white)),
      ]),
      ...fields.asMap().entries.map((entry) => pw.TableRow(
        decoration: pw.BoxDecoration(color: entry.key.isEven ? pale : PdfColors.white),
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: _pdfText(entry.value.key, bold, size: 11, color: dark)),
          pw.Padding(padding: const pw.EdgeInsets.all(8), child: _pdfText(entry.value.value, regular, size: 11, color: dark)),
        ],
      )),
    ];
    final photoRows = <pw.TableRow>[];
    for (var i = 0; i < photos.length; i += 2) {
      photoRows.add(pw.TableRow(children: [
        _pdfPhoto(photos[i], i + 1, regular),
        i + 1 < photos.length ? _pdfPhoto(photos[i + 1], i + 2, regular) : pw.SizedBox(),
      ]));
    }
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
      margin: const pw.EdgeInsets.fromLTRB(38, 48, 38, 48),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: teal, width: 1.5))),
        child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          _pdfText('สกร.ระดับอำเภอหนองจิก', bold, size: 10, color: teal),
          _pdfText('รายงานโครงการพัฒนาอาชีพชุมชน', regular, size: 9, color: dark),
        ]),
      ),
      footer: (ctx) => pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.only(top: 8), decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300))), child: _pdfText('หน้า ${ctx.pageNumber} / ${ctx.pagesCount}', regular, size: 9, color: PdfColors.grey700, align: pw.TextAlign.center)),
      build: (_) => [
        pw.SizedBox(height: 12),
        pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(18), decoration: pw.BoxDecoration(color: teal, borderRadius: pw.BorderRadius.circular(8)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.center, children: [
          _pdfText('รายงานโครงการพัฒนาอาชีพชุมชน', bold, size: 19, color: PdfColors.white, align: pw.TextAlign.center),
          pw.SizedBox(height: 6), _pdfText(title, bold, size: 14, color: PdfColors.white, align: pw.TextAlign.center),
        ])),
        pw.SizedBox(height: 18),
        pw.Text('ข้อมูลโครงการ', style: pw.TextStyle(font: bold, fontSize: 14, color: teal)),
        pw.SizedBox(height: 7),
        pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300, width: .5), columnWidths: {0: const pw.FlexColumnWidth(1.05), 1: const pw.FlexColumnWidth(2.4)}, children: rows),
        if (photos.isNotEmpty) ...[
          pw.SizedBox(height: 18), _pdfText('ภาพประกอบกิจกรรม (${photos.length} ภาพ)', bold, size: 14, color: teal),
          pw.SizedBox(height: 8), pw.Table(columnWidths: {0: const pw.FlexColumnWidth(), 1: const pw.FlexColumnWidth()}, children: photoRows),
        ],
      ],
    ));
    return Uint8List.fromList(await doc.save());
  }

  pw.Widget _pdfPhoto(Uint8List bytes, int number, pw.Font regular) => pw.Padding(
    padding: const pw.EdgeInsets.all(5),
    child: pw.Container(padding: const pw.EdgeInsets.all(5), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(5)), child: pw.Column(children: [
      pw.Container(height: 145, alignment: pw.Alignment.center, child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)),
      pw.SizedBox(height: 4), _pdfText('ภาพที่ $number', regular, size: 9, color: PdfColors.grey700, align: pw.TextAlign.center),
    ])),
  );

  Future<void> runExport(Future<void> Function() task) async {
    if (exporting) return;
    setState(() => exporting = true);
    try { await task(); }
    catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ส่งออกไม่สำเร็จ: $e'), backgroundColor: Colors.red)); }
    finally { if (mounted) setState(() => exporting = false); }
  }

  Future<void> exportPdf({bool print = false}) => runExport(() async {
    final bytes = await makePdf();
    if (print) { await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'รายงานโครงการพัฒนาอาชีพชุมชน.pdf'); }
    else { download(bytes, 'รายงานโครงการพัฒนาอาชีพชุมชน.pdf', 'application/pdf'); }
  });

  Future<void> exportWord() => runExport(() async {
    final photos = await loadPhotos();
    final detailRows = fields.asMap().entries.map((entry) => '<tr class="${entry.key.isEven ? 'even' : 'odd'}"><th>${xml(entry.value.key)}</th><td>${xml(entry.value.value).replaceAll('\n', '<br/>')}</td></tr>').join();
    String imageMime(Uint8List bytes) {
      if (bytes.length >= 8 && bytes[0] == 0x89 && bytes[1] == 0x50) return 'image/png';
      if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8) return 'image/jpeg';
      if (bytes.length >= 12 && String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF') return 'image/webp';
      return 'image/jpeg';
    }
    final photoRows = <String>[];
    for (var i = 0; i < photos.length; i += 2) {
      final first = '<td class="photo-cell" width="50%"><img width="240" height="145" src="data:${imageMime(photos[i])};base64,${base64Encode(photos[i])}" style="width:240px;height:145px;"/></td>';
      final second = i + 1 < photos.length
          ? '<td class="photo-cell" width="50%"><img width="240" height="145" src="data:${imageMime(photos[i + 1])};base64,${base64Encode(photos[i + 1])}" style="width:240px;height:145px;"/></td>'
          : '<td class="photo-cell" width="50%"></td>';
      photoRows.add('<tr>$first$second</tr>');
    }
    final pictures = photos.isEmpty ? '<p class="empty">ไม่มีภาพกิจกรรม</p>' : '<table class="photos">${photoRows.join()}</table>';
    final doc = '''<!DOCTYPE html><html><head><meta charset="utf-8"><title>${xml(title)}</title><style>
@page{size:A4 portrait;margin:16mm 16mm 18mm}body{font-family:"TH Sarabun New","Leelawadee UI",Tahoma,sans-serif;font-size:16pt;line-height:1.35;color:#263238;margin:0;mso-pagination:widow-orphan}h1{text-align:center;color:#087f78;font-size:22pt;margin:0 0 4pt}.subtitle{text-align:center;font-size:18pt;font-weight:bold;margin:0 0 14pt;color:#294b46}.section{background:#087f78;color:white;padding:6pt 9pt;font-size:16pt;font-weight:bold;margin:12pt 0 6pt;page-break-after:avoid}.details{width:100%;border-collapse:collapse;table-layout:fixed}.details th{width:30%;text-align:left;color:#087f78;background:#e8f5f3;font-weight:bold}.details th,.details td{border:1px solid #cbd9d7;padding:6pt 8pt;vertical-align:top;word-wrap:break-word}.details tr{page-break-inside:avoid}.details tr.odd td{background:#fbfdfd}.photos{width:100%;border-collapse:collapse;table-layout:fixed;mso-table-lspace:0pt;mso-table-rspace:0pt}.photos tr{page-break-inside:avoid;mso-row-margin-left:0}.photos td{width:50%;vertical-align:middle;text-align:center;padding:5pt;height:160pt}.photo-cell{text-align:center;border:1px solid #d8e2e0;background:#fff;page-break-inside:avoid;width:50%;height:160pt;mso-height-rule:exactly}.photo-cell img{display:block;width:240px;height:145px;margin:0 auto;border:0}.caption{color:#607d78;font-size:11pt;padding:3pt}.empty{color:#777}.report-footer{margin-top:14pt;padding-top:5pt;border-top:1px solid #cbd9d7;color:#607d78;font-size:11pt;text-align:center}
</style></head><body><h1>รายงานโครงการพัฒนาอาชีพชุมชน</h1><p class="subtitle">${xml(title)}</p><div class="section">ข้อมูลโครงการ</div><table class="details">${detailRows}</table><div class="section">ภาพประกอบกิจกรรม (${photos.length} ภาพ)</div>${pictures}<div class="report-footer">ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก • รายงานโครงการพัฒนาอาชีพชุมชน</div></body></html>''';
    download(Uint8List.fromList([0xEF,0xBB,0xBF,...utf8.encode(doc)]), 'รายงานโครงการพัฒนาอาชีพชุมชน.doc', 'application/msword');
  });

  Future<void> exportExcel() => runExport(() async {
    final excelRows = fields.asMap().entries.map((entry) {
      final f = entry.value;
      final numeric = f.key.contains('จำนวนผู้เข้าร่วม') || f.key == 'รวมผู้เข้าร่วม';
      final raw = f.key == 'รวมผู้เข้าร่วม' ? widget.row['participants_count'] : f.key.contains('ชาย') ? widget.row['male_count'] : widget.row['female_count'];
      final data = numeric ? (raw ?? 0).toString() : xml(f.value);
      return '<Row ss:AutoFitHeight="1"><Cell ss:StyleID="${entry.key.isEven ? 'Data' : 'Alt'}"><Data ss:Type="String">${xml(f.key)}</Data></Cell><Cell ss:StyleID="${numeric ? 'Number' : (entry.key.isEven ? 'Data' : 'Alt')}"><Data ss:Type="${numeric ? 'Number' : 'String'}">$data</Data></Cell></Row>';
    }).join();
    final book = '''<?xml version="1.0" encoding="UTF-8"?><?mso-application progid="Excel.Sheet"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Styles>
<Style ss:ID="Default" ss:Name="Normal"><Alignment ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="11"/></Style>
<Style ss:ID="Title"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:FontName="Tahoma" ss:Size="16" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#087F78" ss:Pattern="Solid"/></Style>
<Style ss:ID="SubTitle"><Alignment ss:Horizontal="Center" ss:Vertical="Center"/><Font ss:FontName="Tahoma" ss:Size="12" ss:Bold="1" ss:Color="#087F78"/><Interior ss:Color="#E8F5F3" ss:Pattern="Solid"/></Style>
<Style ss:ID="Header"><Alignment ss:Horizontal="Center" ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#15978E" ss:Pattern="Solid"/></Style>
<Style ss:ID="Data"><Alignment ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="11"/><Interior ss:Color="#FFFFFF" ss:Pattern="Solid"/></Style>
<Style ss:ID="Alt"><Alignment ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="11"/><Interior ss:Color="#E8F5F3" ss:Pattern="Solid"/></Style>
<Style ss:ID="Number"><Alignment ss:Horizontal="Left" ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="11"/><Interior ss:Color="#F2FAF9" ss:Pattern="Solid"/><NumberFormat ss:Format="0"/></Style>
</Styles><Worksheet ss:Name="ข้อมูลโครงการ"><Table><Column ss:Width="190"/><Column ss:Width="390"/><Row ss:Height="34"><Cell ss:MergeAcross="1" ss:StyleID="Title"><Data ss:Type="String">รายงานโครงการพัฒนาอาชีพชุมชน</Data></Cell></Row><Row ss:Height="28"><Cell ss:MergeAcross="1" ss:StyleID="SubTitle"><Data ss:Type="String">${xml(title)}</Data></Cell></Row><Row ss:Height="8"/><Row ss:Height="26"><Cell ss:StyleID="Header"><Data ss:Type="String">รายการ</Data></Cell><Cell ss:StyleID="Header"><Data ss:Type="String">รายละเอียด</Data></Cell></Row>$excelRows</Table><WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel"><PageSetup><Layout x:Orientation="Portrait"/><PageMargins x:Bottom="0.5" x:Left="0.3" x:Right="0.3" x:Top="0.5"/></PageSetup><Print><ValidPrinterInfo/><FitWidth>1</FitWidth><FitHeight>0</FitHeight><PaperSizeIndex>9</PaperSizeIndex></Print><FreezePanes/><FrozenNoSplit/><SplitHorizontal>4</SplitHorizontal><TopRowBottomPane>4</TopRowBottomPane><ActivePane>2</ActivePane></WorksheetOptions></Worksheet></Workbook>''';
    download(Uint8List.fromList([0xEF,0xBB,0xBF,...utf8.encode(book)]), 'ข้อมูลโครงการพัฒนาอาชีพชุมชน.xls', 'application/vnd.ms-excel');
  });

  Widget info(String label, dynamic raw) {
    final text = (raw ?? '').toString().trim();
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Color(0xFF087F78), fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(text.isEmpty ? '-' : text, style: const TextStyle(fontSize: 15, height: 1.4))]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(title: const Text('รายละเอียดโครงการ'), backgroundColor: const Color(0xFF087F78), foregroundColor: Colors.white),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('พิมพ์และส่งออกรายงาน', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Word และ PDF มีภาพกิจกรรม ส่วน Excel ส่งออกเฉพาะข้อความและตัวเลข'),
          if (exporting) const LinearProgressIndicator(),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(onPressed: exporting ? null : () => exportPdf(print: true), icon: const Icon(Icons.print), label: const Text('พิมพ์รายงาน')),
            OutlinedButton.icon(onPressed: exporting ? null : exportPdf, icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
            OutlinedButton.icon(onPressed: exporting ? null : exportWord, icon: const Icon(Icons.description), label: const Text('Word')),
            OutlinedButton.icon(onPressed: exporting ? null : exportExcel, icon: const Icon(Icons.table_chart), label: const Text('Excel')),
          ]),
        ]))),
        const SizedBox(height: 14),
        Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)), const Divider(height: 24),
          info('ชื่อหลักสูตร', widget.row['course_name']), info('ระยะเวลาจัดกิจกรรม', widget.row['activity_duration']), info('กลุ่มเป้าหมาย', widget.row['target_group']),
          info('จำนวนผู้เข้าร่วมชาย', '${widget.row['male_count'] ?? 0} คน'), info('จำนวนผู้เข้าร่วมหญิง', '${widget.row['female_count'] ?? 0} คน'), info('รวมผู้เข้าร่วม', '${widget.row['participants_count'] ?? 0} คน'),
          info('ตำบล', widget.row['subdistrict']), info('สถานที่จัดกิจกรรม', widget.row['venue']), info('รายละเอียดโครงการ', widget.row['details']), info('วัตถุประสงค์', widget.row['objectives']), info('ผลที่ได้รับ', widget.row['outcomes']), info('ปัญหา/อุปสรรค', widget.row['problems']), info('ข้อเสนอแนะ', widget.row['suggestions']),
        ]))),
        const SizedBox(height: 14),
        Card(color: Colors.white, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ภาพกิจกรรม (${photoIds.length} ภาพ)', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)), const SizedBox(height: 12),
          if (photoIds.isEmpty) const Text('ยังไม่มีภาพกิจกรรม') else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: photoIds.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15), itemBuilder: (context, index) {
            final id = photoIds[index];
            return ClipRRect(borderRadius: BorderRadius.circular(10), child: InkWell(onTap: () => showDialog<void>(context: context, builder: (_) => Dialog(child: InteractiveViewer(child: Image.network(widget.imageUrl(id, thumbnail: false), headers: widget.imageHeaders, fit: BoxFit.contain)))), child: Image.network(widget.imageUrl(id), headers: widget.imageHeaders, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))));
          }),
        ]))),
      ]),
    );
  }
}
