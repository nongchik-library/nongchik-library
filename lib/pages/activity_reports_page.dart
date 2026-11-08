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

class ActivityReportsPage extends StatefulWidget {
  const ActivityReportsPage({super.key});

  @override
  State<ActivityReportsPage> createState() => _ActivityReportsPageState();
}

class _ActivityReportsPageState extends State<ActivityReportsPage> {
  final SupabaseClient client = Supabase.instance.client;
  final TextEditingController search = TextEditingController();
  final GoogleDriveService drive = GoogleDriveService();
  static const menuOptions = <String, String>{
    'learning_resources': 'แหล่งเรียนรู้',
    'local_wisdom': 'ภูมิปัญญาท้องถิ่น',
    'local_scholars': 'ปราชญ์ชาวบ้าน',
    'community_book_houses': 'บ้านหนังสือชุมชน',
    'subdistrict_learning_centers': 'ศกร.ระดับตำบล',
    'tourist_attractions': 'แหล่งท่องเที่ยวในตำบล',
    'traditional_foods': 'อาหาร/ขนมโบราณในชุมชน',
    'village_book_corners': 'มุมหนังสือหมู่บ้าน',
  };
  static const subdistricts = [
    'เกาะเปาะ', 'ลิปะสะโง', 'คอลอตันหยง', 'ดอนรัก', 'ดาโต๊ะ', 'ตุยง',
    'ท่ากำชำ', 'บางเขา', 'บางตาวา', 'บ่อทอง', 'ปุโละปุโย', 'ยาบี',
  ];

  List<Map<String, dynamic>> reports = [];
  bool loading = true;
  bool admin = false;
  String assignedSubdistrict = '';
  String filterSubdistrict = 'ทั้งหมด';
  String filterMenu = 'ทั้งหมด';
  String? error;

  @override
  void initState() {
    super.initState();
    search.addListener(_refresh);
    _load();
  }

  @override
  void dispose() {
    search.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('กรุณาเข้าสู่ระบบใหม่');
      final profile = await client.from('profiles').select('role,subdistrict').eq('id', user.id).maybeSingle();
      admin = profile?['role'] == 'admin';
      assignedSubdistrict = (profile?['subdistrict'] ?? '').toString();
      final data = await client.from('activity_reports').select().order('activity_date', ascending: false);
      if (!mounted) return;
      setState(() {
        reports = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = search.text.trim().toLowerCase();
    return reports.where((r) {
      final sub = (r['subdistrict'] ?? '').toString();
      final text = [r['title'], r['activity_type'], r['venue'], r['subdistrict'], r['target_group'], r['related_item_name'], menuOptions[(r['linked_menu'] ?? '').toString()]]
          .map((v) => (v ?? '').toString().toLowerCase()).join(' ');
      final menuMatch = filterMenu == 'ทั้งหมด' || (r['linked_menu'] ?? '') == filterMenu;
      return menuMatch && (filterSubdistrict == 'ทั้งหมด' || filterSubdistrict == sub) && (q.isEmpty || text.contains(q));
    }).toList();
  }

  void _refresh() { if (mounted) setState(() {}); }

  Future<void> _openForm({Map<String, dynamic>? existing}) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ActivityReportForm(
        existing: existing,
        defaultSubdistrict: assignedSubdistrict,
        isAdmin: admin,
        client: client,
        drive: drive,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _togglePublic(Map<String, dynamic> row) async {
    if (!admin) return;
    final next = row['is_public'] != true;
    try {
      await client.from('activity_reports').update({'is_public': next}).eq('id', row['id']);
      await _load();
      if (mounted) _snack(next ? 'เผยแพร่รายงานแล้ว' : 'ยกเลิกเผยแพร่รายงานแล้ว');
    } catch (e) {
      if (mounted) _snack('เปลี่ยนสถานะเผยแพร่ไม่สำเร็จ: $e', error: true);
    }
  }

  Future<void> _delete(Map<String, dynamic> row) async {
    final ok = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('ยืนยันการลบรายงาน'),
      content: Text('ต้องการลบรายงาน “${row['title']}” ใช่หรือไม่?'),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ'))],
    ));
    if (ok != true) return;
    try {
      await client.from('activity_reports').delete().eq('id', row['id']);
      await _load();
      if (mounted) _snack('ลบรายงานเรียบร้อยแล้ว');
    } catch (e) { if (mounted) _snack('ลบไม่สำเร็จ: $e', error: true); }
  }

  void _snack(String value, {bool error = false}) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(value), backgroundColor: error ? Colors.red.shade700 : const Color(0xFF00897B)),
  );

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    final totalParticipants = reports.fold<int>(0, (sum, r) => sum + ((r['participants_count'] as num?)?.toInt() ?? 0));
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        title: const Text('รายงานผลกิจกรรม', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF18364D),
        elevation: 0,
        actions: [IconButton(onPressed: _load, tooltip: 'รีเฟรช', icon: const Icon(Icons.refresh_rounded))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(), icon: const Icon(Icons.add_rounded), label: const Text('บันทึกกิจกรรม'),
        backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF006B73), Color(0xFF2863B8)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('ระบบรายงานผลกิจกรรม', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 5),
              const Text('บันทึกผลการดำเนินงานและกิจกรรมส่งเสริมการเรียนรู้', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 10, children: [
                _stat('กิจกรรมทั้งหมด', '${reports.length}', Icons.event_note_rounded),
                _stat('ผู้เข้าร่วมรวม', '$totalParticipants', Icons.groups_rounded),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: search,
            decoration: InputDecoration(
              hintText: 'ค้นหาชื่อกิจกรรม / สถานที่ / ตำบล', prefixIcon: const Icon(Icons.search),
              filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: filterMenu,
            decoration: InputDecoration(labelText: 'กรองตามเมนูหลัก', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            items: ['ทั้งหมด', ...menuOptions.keys].map((k) => DropdownMenuItem(value: k, child: Text(k == 'ทั้งหมด' ? k : menuOptions[k]!))).toList(),
            onChanged: (v) => setState(() => filterMenu = v ?? 'ทั้งหมด'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: filterSubdistrict,
            decoration: InputDecoration(labelText: 'กรองตามตำบล', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            items: ['ทั้งหมด', ...subdistricts].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => setState(() => filterSubdistrict = v ?? 'ทั้งหมด'),
          ),
          const SizedBox(height: 12),
          const Text('สรุปรายงานแยกตามเมนูหลักทั้ง 8 เมนู', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18364D))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: menuOptions.entries.map((entry) {
            final count = reports.where((r) => r['linked_menu'] == entry.key).length;
            return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFE2EAF0))), child: Text('${entry.value}  $count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF40576A))));
          }).toList()),
          const SizedBox(height: 14),
          if (loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else if (error != null) _empty('โหลดข้อมูลไม่สำเร็จ\n$error', icon: Icons.cloud_off_rounded)
          else if (items.isEmpty) _empty('ยังไม่มีรายงานกิจกรรม\nกด “บันทึกกิจกรรม” เพื่อเพิ่มรายงานแรก', icon: Icons.event_available_rounded)
          else ...items.map(_reportCard),
          const SizedBox(height: 90),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white24)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white), const SizedBox(width: 9), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))])]),
  );

  Widget _empty(String text, {required IconData icon}) => Container(
    padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(children: [Icon(icon, size: 42, color: Colors.blueGrey.shade300), const SizedBox(height: 10), Text(text, textAlign: TextAlign.center, style: const TextStyle(color: Colors.blueGrey))]),
  );

  Widget _reportCard(Map<String, dynamic> row) {
    final date = (row['activity_date'] ?? '').toString();
    final photos = List<String>.from(row['photo_drive_ids'] ?? const []);
    final canEdit = admin || row['created_by'] == client.auth.currentUser?.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12), elevation: 1, color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetails(row),
        child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFE4F4F1), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.event_note_rounded, color: Color(0xFF00897B))),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((row['title'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF18364D))),
            Text('${row['activity_type'] ?? 'กิจกรรม'} • $date', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
            if (admin) Text(row['is_public'] == true ? 'เผยแพร่แล้ว' : 'ยังไม่เผยแพร่', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: row['is_public'] == true ? Colors.teal : Colors.blueGrey)),
          ])),
          if (canEdit) PopupMenuButton<String>(onSelected: (v) { if (v == 'edit') _openForm(existing: row); if (v == 'delete') _delete(row); if (v == 'publish') _togglePublic(row); }, itemBuilder: (_) => [const PopupMenuItem(value: 'edit', child: Text('แก้ไข')), if (admin) PopupMenuItem(value: 'publish', child: Text(row['is_public'] == true ? 'ยกเลิกเผยแพร่' : 'เผยแพร่ให้ประชาชน')), if (admin) const PopupMenuItem(value: 'delete', child: Text('ลบ'))]),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 8, children: [
          _meta(Icons.category_outlined, menuOptions[(row['linked_menu'] ?? '').toString()] ?? 'ไม่ระบุเมนู'),
          if ((row['related_item_name'] ?? '').toString().trim().isNotEmpty) _meta(Icons.link_rounded, row['related_item_name'].toString()),
          _meta(Icons.location_on_outlined, '${row['subdistrict'] ?? '-'}'),
          _meta(Icons.place_outlined, '${row['venue'] ?? '-'}'),
          _meta(Icons.groups_outlined, ((row['male_count'] ?? 0) == 0 && (row['female_count'] ?? 0) == 0 && (row['participants_count'] ?? 0) > 0) ? 'ผู้เข้าร่วมรวม ${row['participants_count']} คน' : 'ชาย ${row['male_count'] ?? 0} / หญิง ${row['female_count'] ?? 0} คน'),
          if (['age_under_15','age_15_25','age_26_40','age_41_59','age_60_plus'].any((k) => (row[k] ?? 0) > 0)) _meta(Icons.cake_outlined, 'ช่วงอายุ: ต่ำกว่า 15 ปี ${row['age_under_15'] ?? 0} • 15–25 ปี ${row['age_15_25'] ?? 0} • 26–40 ปี ${row['age_26_40'] ?? 0} • 41–59 ปี ${row['age_41_59'] ?? 0} • 60 ปีขึ้นไป ${row['age_60_plus'] ?? 0} คน'),
        ]),
        if ((row['outcomes'] ?? '').toString().trim().isNotEmpty) ...[
          const SizedBox(height: 10), const Text('ผลการดำเนินงาน', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(row['outcomes'].toString(), maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 7, runSpacing: 7, children: photos.take(4).map((id) {
            return ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(
              drive.imageUrl(id, thumbnail: true), headers: drive.imageHeaders, width: 74, height: 64, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 74, height: 64, color: Colors.black12, child: const Icon(Icons.broken_image)),
            ));
          }).toList()),
        ],
      ])),
      ),
    );
  }


  bool _exporting = false;
  String _xml(String v) => v.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&apos;');
  void _download(Uint8List bytes, String filename, String mime) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final a = html.AnchorElement(href: url)..download = filename..style.display = 'none';
    html.document.body?.children.add(a); a.click(); a.remove(); html.Url.revokeObjectUrl(url);
  }
  Future<List<Uint8List>> _loadReportPhotos(List<String> ids) async {
    final out = <Uint8List>[];
    for (final id in ids) {
      try {
        final r = await http.get(Uri.parse(drive.imageUrl(id, thumbnail: false)), headers: drive.imageHeaders);
        if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) out.add(r.bodyBytes);
      } catch (_) {}
    }
    return out;
  }
  // แยกฟอนต์ตามชุดอักขระ: Noto Sans Thai สำหรับภาษาไทย และ DejaVu Sans
  // สำหรับเลขอารบิก ตัวอักษรละติน และเครื่องหมาย ซึ่ง NotoSansThai ในชุดนี้ไม่มี glyph
  pw.Widget _pdfReportText(
    String text,
    pw.Font thai, {
    required pw.Font latinRegular,
    required pw.Font latinBold,
    bool bold = false,
    double size = 10,
    PdfColor? color,
  }) {
    final spans = <pw.TextSpan>[];
    final runes = text.runes.toList();
    var start = 0;
    while (start < runes.length) {
      final isThai = runes[start] >= 0x0E00 && runes[start] <= 0x0E7F;
      var end = start + 1;
      while (end < runes.length &&
          ((runes[end] >= 0x0E00 && runes[end] <= 0x0E7F) == isThai)) {
        end++;
      }
      final part = String.fromCharCodes(runes.sublist(start, end));
      spans.add(pw.TextSpan(
        text: part,
        style: pw.TextStyle(
          font: isThai ? thai : (bold ? latinBold : latinRegular),
          fontSize: size,
          color: color,
        ),
      ));
      start = end;
    }
    return pw.RichText(text: pw.TextSpan(children: spans));
  }
  Future<void> _exportReport(Map<String, dynamic> row, List<List<String>> fields, List<String> photoIds, String format) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final safeTitle = (row['title'] ?? 'รายงานกิจกรรม').toString().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      if (format == 'pdf') {
        final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf'));
        final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansThai-Bold.ttf'));
        final latinRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
        final latinBold = pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
        final photos = await _loadReportPhotos(photoIds);
        final doc = pw.Document();
        final teal = PdfColor.fromInt(0xFF087F78), pale = PdfColor.fromInt(0xFFE8F5F3);
        doc.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4, theme: pw.ThemeData.withFont(base: regular, bold: bold),
          margin: const pw.EdgeInsets.fromLTRB(38, 42, 38, 42),
          header: (_) => pw.Container(padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: teal, width: 1.5))),
            child: _pdfReportText('สกร.ระดับอำเภอหนองจิก  |  รายงานผลกิจกรรม', bold, latinRegular: latinRegular, latinBold: latinBold, bold: true, size: 9, color: teal)),
          footer: (ctx) => pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.only(top: 8),
            child: _pdfReportText('หน้า ${ctx.pageNumber} / ${ctx.pagesCount}', regular, latinRegular: latinRegular, latinBold: latinBold, size: 9)),
          build: (_) => [
            pw.Container(width: double.infinity, padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(color: teal, borderRadius: pw.BorderRadius.circular(7)),
              child: _pdfReportText('รายงานผลกิจกรรม\n${row['title'] ?? '-'}', bold, latinRegular: latinRegular, latinBold: latinBold, size: 17, color: PdfColors.white)),
            pw.SizedBox(height: 14),
            pw.Table(border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              columnWidths: {0: const pw.FlexColumnWidth(1), 1: const pw.FlexColumnWidth(2.2)},
              children: [
                pw.TableRow(decoration: pw.BoxDecoration(color: teal), children: [
                  for (final h in ['รายการ','รายละเอียด']) pw.Padding(padding: const pw.EdgeInsets.all(8), child: _pdfReportText(h, bold, latinRegular: latinRegular, latinBold: latinBold, color: PdfColors.white)),
                ]),
                ...fields.asMap().entries.map((e) => pw.TableRow(decoration: pw.BoxDecoration(color: e.key.isEven ? pale : PdfColors.white), children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(7), child: _pdfReportText(e.value[0], bold, latinRegular: latinRegular, latinBold: latinBold, size: 9)),
                  pw.Padding(padding: const pw.EdgeInsets.all(7), child: _pdfReportText(e.value[1], regular, latinRegular: latinRegular, latinBold: latinBold, size: 9)),
                ])),
              ]),
            if (photos.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              _pdfReportText('ภาพประกอบกิจกรรม (${photos.length} ภาพ)', bold, latinRegular: latinRegular, latinBold: latinBold, bold: true, size: 13, color: teal),
              pw.SizedBox(height: 8),
              for (var i = 0; i < photos.length; i += 2)
                pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  for (var j = i; j < (i + 2 < photos.length ? i + 2 : photos.length); j++)
                    pw.Expanded(child: pw.Container(margin: const pw.EdgeInsets.all(4), padding: const pw.EdgeInsets.all(5),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300)),
                      child: pw.Column(children: [
                        pw.Container(height: 125, alignment: pw.Alignment.center, child: pw.Image(pw.MemoryImage(photos[j]), fit: pw.BoxFit.contain)),
                        _pdfReportText('ภาพที่ ${j + 1}', regular, latinRegular: latinRegular, latinBold: latinBold, size: 8),
                      ]))),
                  if (i + 1 >= photos.length) pw.Expanded(child: pw.SizedBox()),
                ]),
            ],
          ],
        ));
        _download(Uint8List.fromList(await doc.save()), '$safeTitle.pdf', 'application/pdf');
      } else if (format == 'word') {
        final photos = await _loadReportPhotos(photoIds);
        final rows = fields.asMap().entries.map((e) => '<tr style="background:${e.key.isEven ? '#E8F5F3' : '#FFFFFF'}"><th>${_xml(e.value[0])}</th><td>${_xml(e.value[1]).replaceAll('\n','<br/>')}</td></tr>').join();
        final imageRows = <String>[];
        for (var i = 0; i < photos.length; i += 2) {
          final cells = <String>[];
          for (var j = i; j < (i + 2 < photos.length ? i + 2 : photos.length); j++) {
            cells.add('<td style="width:50%;border:1px solid #D5E1E1;padding:8px;text-align:center;vertical-align:middle;"><img src="data:image/jpeg;base64,${base64Encode(photos[j])}" width="280" style="width:280px;max-width:100%;height:180px;object-fit:contain;display:block;margin:0 auto;"/><p style="margin:6px 0 0;color:#526779;font-size:9pt;">ภาพที่ ${j+1}</p></td>');
          }
          if (cells.length == 1) cells.add('<td style="width:50%;border:1px solid #D5E1E1;"></td>');
          imageRows.add('<tr style="page-break-inside:avoid;">${cells.join()}</tr>');
        }
        final gallery = '<table style="width:100%;border-collapse:collapse;table-layout:fixed;">${imageRows.join()}</table>';
        final docHtml = '<!DOCTYPE html><html><head><meta charset="utf-8"><style>@page{size:A4;margin:18mm}body{font-family:Tahoma,sans-serif;color:#263238;font-size:11pt}h1{background:#087F78;color:white;text-align:center;padding:18px;font-size:18pt}h2{color:#087F78;border-bottom:2px solid #087F78;padding-bottom:6px;page-break-after:avoid}table{width:100%;border-collapse:collapse;table-layout:fixed}th,td{border:1px solid #D5E1E1;padding:8px;text-align:left;vertical-align:top;overflow-wrap:break-word}th{width:32%;color:#087F78}tr{page-break-inside:avoid}img{max-width:100%;height:180px;object-fit:contain}</style></head><body><h1>รายงานผลกิจกรรม</h1><h2>${_xml(safeTitle)}</h2><table>$rows</table>${photos.isEmpty ? '' : '<h2>ภาพประกอบกิจกรรม (${photos.length} ภาพ)</h2>$gallery'}</body></html>';
        _download(Uint8List.fromList([0xEF,0xBB,0xBF,...utf8.encode(docHtml)]), '$safeTitle.doc', 'application/msword;charset=utf-8');
      } else {
        final rows = fields.map((f) => '<Row><Cell><Data ss:Type="String">${_xml(f[0])}</Data></Cell><Cell><Data ss:Type="String">${_xml(f[1])}</Data></Cell></Row>').join();
        final book = '<?xml version="1.0" encoding="UTF-8"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Styles><Style ss:ID="title"><Font ss:FontName="Tahoma" ss:Size="16" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#087F78" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center"/></Style><Style ss:ID="head"><Font ss:FontName="Tahoma" ss:Size="11" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#087F78" ss:Pattern="Solid"/></Style><Style ss:ID="cell"><Font ss:FontName="Tahoma" ss:Size="11"/><Interior ss:Color="#E8F5F3" ss:Pattern="Solid"/><Alignment ss:Vertical="Top" ss:WrapText="1"/></Style></Styles><Worksheet ss:Name="รายงานกิจกรรม"><Table><Column ss:Width="190"/><Column ss:Width="420"/><Row><Cell ss:MergeAcross="1" ss:StyleID="title"><Data ss:Type="String">รายงานผลกิจกรรม - ${_xml(safeTitle)}</Data></Cell></Row><Row><Cell ss:StyleID="head"><Data ss:Type="String">รายการ</Data></Cell><Cell ss:StyleID="head"><Data ss:Type="String">รายละเอียด</Data></Cell></Row>$rows</Table></Worksheet></Workbook>';
        _download(Uint8List.fromList([0xEF,0xBB,0xBF,...utf8.encode(book)]), '$safeTitle.xls', 'application/vnd.ms-excel;charset=utf-8');
      }
    } catch (e) {
      if (mounted) _snack('ส่งออกไม่สำเร็จ: $e', error: true);
    } finally { if (mounted) setState(() => _exporting = false); }
  }

  Future<void> _showDetails(Map<String, dynamic> row) async {
    final photos = List<String>.from(row['photo_drive_ids'] ?? const []);
    final fields = <List<String>>[
      ['ชื่อกิจกรรม', (row['title'] ?? '').toString()],
      ['วันที่จัดกิจกรรม', (row['activity_date'] ?? '').toString()],
      ['ประเภทกิจกรรม', (row['activity_type'] ?? '').toString()],
      ['เมนูหลักที่เกี่ยวข้อง', menuOptions[(row['linked_menu'] ?? '').toString()] ?? ''],
      ['ข้อมูล/แหล่งเรียนรู้ที่เกี่ยวข้อง', (row['related_item_name'] ?? '').toString()],
      ['ตำบล', (row['subdistrict'] ?? '').toString()],
      ['สถานที่จัดกิจกรรม', (row['venue'] ?? '').toString()],
      ['กลุ่มเป้าหมาย', (row['target_group'] ?? '').toString()],
      ['จำนวนผู้เข้าร่วมชาย', '${row['male_count'] ?? 0} คน'],
      ['จำนวนผู้เข้าร่วมหญิง', '${row['female_count'] ?? 0} คน'],
      ['รวมผู้เข้าร่วม', '${row['participants_count'] ?? 0} คน'],
      ['อายุต่ำกว่า 15 ปี', '${row['age_under_15'] ?? 0} คน'],
      ['อายุ 15–25 ปี', '${row['age_15_25'] ?? 0} คน'],
      ['อายุ 26–40 ปี', '${row['age_26_40'] ?? 0} คน'],
      ['อายุ 41–59 ปี', '${row['age_41_59'] ?? 0} คน'],
      ['อายุ 60 ปีขึ้นไป', '${row['age_60_plus'] ?? 0} คน'],
      ['วัตถุประสงค์', (row['objectives'] ?? '').toString()],
      ['รายละเอียดการดำเนินกิจกรรม', (row['activity_details'] ?? '').toString()],
      ['ผลการดำเนินงาน', (row['outcomes'] ?? '').toString()],
      ['ปัญหา/อุปสรรค', (row['problems'] ?? '').toString()],
      ['ข้อเสนอแนะ', (row['suggestions'] ?? '').toString()],
    ];
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 820),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  color: Color(0xFF00897B),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(children: [
                  const Icon(Icons.description_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(child: Text((row['title'] ?? 'รายละเอียดกิจกรรม').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))),
                  IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close, color: Colors.white)),
                ]),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    const Text('ข้อมูลกิจกรรม', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF00897B))),
                    const SizedBox(height: 10),
                    ...fields.where((f) => (f[1] ?? '').toString().trim().isNotEmpty).map((f) => Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(color: const Color(0xFFF2F7F7), borderRadius: BorderRadius.circular(10)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f[0], style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        Text(f[1]!.toString(), style: const TextStyle(fontSize: 14, color: Color(0xFF203746))),
                      ]),
                    )),
                    if (photos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text('ภาพประกอบกิจกรรม (${photos.length} ภาพ)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF00897B))),
                      const SizedBox(height: 10),
                      ...photos.map((id) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            drive.imageUrl(id, thumbnail: false),
                            headers: drive.imageHeaders,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                            errorBuilder: (_, __, ___) => Container(height: 120, color: Colors.black12, alignment: Alignment.center, child: const Text('ไม่สามารถโหลดรูปภาพนี้ได้')),
                          ),
                        ),
                      )),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (_exporting) const LinearProgressIndicator(),
                  Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                    OutlinedButton.icon(onPressed: _exporting ? null : () => _exportReport(row, fields, photos, 'pdf'), icon: const Icon(Icons.picture_as_pdf), label: const Text('PDF')),
                    OutlinedButton.icon(onPressed: _exporting ? null : () => _exportReport(row, fields, photos, 'word'), icon: const Icon(Icons.description), label: const Text('Word')),
                    OutlinedButton.icon(onPressed: _exporting ? null : () => _exportReport(row, fields, photos, 'excel'), icon: const Icon(Icons.table_chart), label: const Text('Excel')),
                  ]),
                  const SizedBox(height: 6),
                  SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.check), label: const Text('ปิดรายละเอียด'))),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String value) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: Colors.teal), const SizedBox(width: 4), Text(value, style: const TextStyle(fontSize: 12, color: Colors.blueGrey))]);
}

class _ActivityReportForm extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final String defaultSubdistrict;
  final bool isAdmin;
  final SupabaseClient client;
  final GoogleDriveService drive;
  const _ActivityReportForm({required this.existing, required this.defaultSubdistrict, required this.isAdmin, required this.client, required this.drive});
  @override
  State<_ActivityReportForm> createState() => _ActivityReportFormState();
}

class _ActivityReportFormState extends State<_ActivityReportForm> {
  final key = GlobalKey<FormState>();
  final picker = ImagePicker();
  late final TextEditingController title, date, venue, target, relatedItem, otherActivityType, maleCount, femaleCount, ageUnder15, age15To25, age26To40, age41To59, age60Plus, objectives, details, outcomes, problems, suggestions;
  late String subdistrict, activityType, linkedMenu;
  final List<XFile> newPhotos = [];
  List<String> oldPhotoIds = [];
  bool saving = false;
  static const types = ['ส่งเสริมการอ่าน', 'ส่งเสริมการเรียนรู้', 'การศึกษาต่อเนื่อง', 'ทักษะชีวิต', 'อาชีพและการพัฒนาอาชีพ', 'จิตอาสา/กิจกรรมชุมชน', 'อื่น ๆ'];

  @override
  void initState() {
    super.initState();
    final r = widget.existing ?? {};
    title = TextEditingController(text: r['title']?.toString() ?? '');
    date = TextEditingController(text: r['activity_date']?.toString() ?? DateTime.now().toIso8601String().substring(0, 10));
    venue = TextEditingController(text: r['venue']?.toString() ?? '');
    relatedItem = TextEditingController(text: r['related_item_name']?.toString() ?? '');
    final savedActivityType = (r['activity_type'] ?? '').toString();
    otherActivityType = TextEditingController(text: types.contains(savedActivityType) ? '' : savedActivityType);
    target = TextEditingController(text: r['target_group']?.toString() ?? '');
    maleCount = TextEditingController(text: r['male_count']?.toString() ?? '0');
    femaleCount = TextEditingController(text: r['female_count']?.toString() ?? '0');
    ageUnder15 = TextEditingController(text: r['age_under_15']?.toString() ?? '0');
    age15To25 = TextEditingController(text: r['age_15_25']?.toString() ?? '0');
    age26To40 = TextEditingController(text: r['age_26_40']?.toString() ?? '0');
    age41To59 = TextEditingController(text: r['age_41_59']?.toString() ?? '0');
    age60Plus = TextEditingController(text: r['age_60_plus']?.toString() ?? '0');
    objectives = TextEditingController(text: r['objectives']?.toString() ?? '');
    details = TextEditingController(text: r['activity_details']?.toString() ?? '');
    outcomes = TextEditingController(text: r['outcomes']?.toString() ?? '');
    problems = TextEditingController(text: r['problems']?.toString() ?? '');
    suggestions = TextEditingController(text: r['suggestions']?.toString() ?? '');
    subdistrict = (r['subdistrict'] ?? widget.defaultSubdistrict).toString();
    if (!['เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง','ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี'].contains(subdistrict)) subdistrict = 'ดาโต๊ะ';
    activityType = types.contains(savedActivityType) ? savedActivityType : 'อื่น ๆ';
    linkedMenu = _ActivityReportsPageState.menuOptions.containsKey(r['linked_menu']) ? r['linked_menu'].toString() : _ActivityReportsPageState.menuOptions.keys.first;
    oldPhotoIds = List<String>.from(r['photo_drive_ids'] ?? const []);
    maleCount.addListener(_refreshParticipantTotal);
    femaleCount.addListener(_refreshParticipantTotal);
    for (final c in [ageUnder15, age15To25, age26To40, age41To59, age60Plus]) { c.addListener(_refreshParticipantTotal); }
  }

  void _refreshParticipantTotal() { if (mounted) setState(() {}); }

  @override
  void dispose() {
    maleCount.removeListener(_refreshParticipantTotal);
    femaleCount.removeListener(_refreshParticipantTotal);
    for (final c in [ageUnder15, age15To25, age26To40, age41To59, age60Plus]) { c.removeListener(_refreshParticipantTotal); }
    for (final c in [title,date,venue,target,relatedItem,otherActivityType,maleCount,femaleCount,ageUnder15,age15To25,age26To40,age41To59,age60Plus,objectives,details,outcomes,problems,suggestions]) { c.dispose(); }
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, {String? helper, bool alignLabel = false}) => InputDecoration(
    labelText: label,
    helperText: helper,
    alignLabelWithHint: alignLabel,
    labelStyle: const TextStyle(fontSize: 14, color: Color(0xFF526779), fontWeight: FontWeight.w600),
    floatingLabelStyle: const TextStyle(color: Color(0xFF087F78), fontWeight: FontWeight.w800),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD9E5E8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.8)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD9534F))),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFD9534F), width: 1.6)),
  );

  Widget _field(String label, TextEditingController c, {int lines = 1, TextInputType? keyboard, String? Function(String?)? validator}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: c, maxLines: lines, keyboardType: keyboard, validator: validator,
      style: const TextStyle(fontSize: 15, color: Color(0xFF203747), fontWeight: FontWeight.w500),
      cursorColor: const Color(0xFF00897B),
      decoration: _inputDecoration(label, alignLabel: lines > 1),
    ),
  );

  Widget _sectionTitle(String title, String subtitle, IconData icon) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 12),
    child: Row(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFE3F3F0), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: const Color(0xFF087F78), size: 20)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF18364D))),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF718391))),
      ])),
    ]),
  );

  String? _nonNegative(String? value) {
    final n = int.tryParse((value ?? '').trim());
    return n == null || n < 0 ? 'กรุณากรอกจำนวนตั้งแต่ 0 ขึ้นไป' : null;
  }

  String? _ageValidator(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final n = int.tryParse(value!.trim());
    return n == null || n < 0 || n > 120 ? 'กรุณากรอกอายุ 0–120 ปี' : null;
  }

  Future<void> _pickPhotos() async {
    final picked = await picker.pickMultiImage(imageQuality: 82);
    if (picked.isNotEmpty && mounted) setState(() => newPhotos.addAll(picked));
  }

  Future<void> _save() async {
    if (!key.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      final user = widget.client.auth.currentUser;
      if (user == null) throw Exception('กรุณาเข้าสู่ระบบใหม่');
      final ids = [...oldPhotoIds];
      for (final photo in newPhotos) {
        final Uint8List bytes = await photo.readAsBytes();
        final result = await widget.drive.upload(
          bytes: bytes, fileName: photo.name, mimeType: photo.mimeType ?? 'image/jpeg',
          folderName: '$subdistrict/รายงานผลกิจกรรม', category: 'other', subdistrict: subdistrict,
        );
        final id = (result['id'] ?? '').toString();
        if (id.isNotEmpty) ids.add(id);
      }
      final payload = <String, dynamic>{
        'title': title.text.trim(), 'activity_date': date.text.trim(),
        'activity_type': activityType == 'อื่น ๆ' ? otherActivityType.text.trim() : activityType,
        'subdistrict': subdistrict, 'venue': venue.text.trim(), 'target_group': target.text.trim(),
        'linked_menu': linkedMenu, 'related_item_name': relatedItem.text.trim(),
        'male_count': int.tryParse(maleCount.text.trim()) ?? 0,
        'female_count': int.tryParse(femaleCount.text.trim()) ?? 0,
        'age_under_15': int.tryParse(ageUnder15.text.trim()) ?? 0,
        'age_15_25': int.tryParse(age15To25.text.trim()) ?? 0,
        'age_26_40': int.tryParse(age26To40.text.trim()) ?? 0,
        'age_41_59': int.tryParse(age41To59.text.trim()) ?? 0,
        'age_60_plus': int.tryParse(age60Plus.text.trim()) ?? 0,
        'participants_count': (int.tryParse(maleCount.text.trim()) ?? 0) + (int.tryParse(femaleCount.text.trim()) ?? 0),
        'objectives': objectives.text.trim(), 'activity_details': details.text.trim(),
        'outcomes': outcomes.text.trim(), 'problems': problems.text.trim(), 'suggestions': suggestions.text.trim(),
        'photo_drive_ids': ids,
      };
      if (widget.existing == null) {
        payload['created_by'] = user.id;
        await widget.client.from('activity_reports').insert(payload);
      } else {
        await widget.client.from('activity_reports').update(payload).eq('id', widget.existing!['id']);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: Colors.red));
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Tahoma'),
      inputDecorationTheme: const InputDecorationTheme(isDense: false),
    ),
    child: Dialog(
    insetPadding: const EdgeInsets.all(12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: ConstrainedBox(constraints: BoxConstraints(maxWidth: 760, maxHeight: MediaQuery.sizeOf(context).height * .92), child: Column(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18), decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF087F78), Color(0xFF079688)]), borderRadius: BorderRadius.vertical(top: Radius.circular(22))), child: Row(children: [const Expanded(child: Text('บันทึกรายงานผลกิจกรรม', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: .1)),), IconButton(onPressed: saving ? null : () => Navigator.pop(context, false), icon: const Icon(Icons.close, color: Colors.white))])),
      Expanded(child: Form(key: key, child: ListView(padding: const EdgeInsets.all(18), children: [
        _sectionTitle('ข้อมูลพื้นฐาน', 'รายละเอียดทั่วไปของกิจกรรม', Icons.assignment_outlined),
        _field('ชื่อกิจกรรม *', title, validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณาระบุชื่อกิจกรรม' : null),
        _field('วันที่จัดกิจกรรม (YYYY-MM-DD) *', date, validator: (v) => (v == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v.trim())) ? 'รูปแบบวันที่ไม่ถูกต้อง' : null),
        DropdownButtonFormField<String>(value: activityType, decoration: _inputDecoration('ประเภทกิจกรรม'), items: types.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => activityType = v ?? types.first)),
        if (activityType == 'อื่น ๆ') ...[
          const SizedBox(height: 10),
          _field('ระบุประเภทกิจกรรม *', otherActivityType, validator: (v) => (activityType == 'อื่น ๆ' && (v == null || v.trim().isEmpty)) ? 'กรุณาระบุว่าจัดกิจกรรมอะไร' : null),
        ],
        DropdownButtonFormField<String>(value: subdistrict, decoration: _inputDecoration('ตำบล'), items: const ['เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง','ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(), onChanged: widget.isAdmin ? (v) => setState(() => subdistrict = v ?? subdistrict) : null),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: linkedMenu, isExpanded: true, decoration: _inputDecoration('เชื่อมโยงกับเมนูหลัก *', helper: 'เลือก 1 ใน 8 เมนูที่เกี่ยวข้องกับกิจกรรมนี้'), items: _ActivityReportsPageState.menuOptions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, overflow: TextOverflow.ellipsis))).toList(), onChanged: (v) => setState(() => linkedMenu = v ?? linkedMenu)),
        const SizedBox(height: 2),
        _sectionTitle('รายละเอียดสถานที่และกลุ่มเป้าหมาย', 'ข้อมูลการจัดกิจกรรมและหน่วยงานที่เกี่ยวข้อง', Icons.location_on_outlined),
        _field('ชื่อข้อมูล / แหล่งเรียนรู้ที่เกี่ยวข้อง (ถ้ามี)', relatedItem),
        _field('สถานที่จัดกิจกรรม', venue),
        _field('กลุ่มเป้าหมาย', target),
        const SizedBox(height: 4),
        _sectionTitle('ข้อมูลผู้เข้าร่วม', 'ระบุจำนวนผู้เข้าร่วมและช่วงอายุ', Icons.groups_rounded),
        const Text('จำนวนผู้เข้าร่วมกิจกรรม', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF355267))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _field('ชาย (คน)', maleCount, keyboard: TextInputType.number, validator: _nonNegative)),
          const SizedBox(width: 10),
          Expanded(child: _field('หญิง (คน)', femaleCount, keyboard: TextInputType.number, validator: _nonNegative)),
        ]),
        Builder(builder: (context) {
          final total = (int.tryParse(maleCount.text.trim()) ?? 0) + (int.tryParse(femaleCount.text.trim()) ?? 0);
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE7F5F2), borderRadius: BorderRadius.circular(12)), child: Text('รวมผู้เข้าร่วม  $total คน', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF087F78))));
        }),
        const Text('จำนวนผู้เข้าร่วมแยกตาม 5 ช่วงอายุ (คน)', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF18364D))),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _field('ต่ำกว่า 15 ปี', ageUnder15, keyboard: TextInputType.number, validator: _nonNegative)),
          const SizedBox(width: 10),
          Expanded(child: _field('15–25 ปี', age15To25, keyboard: TextInputType.number, validator: _nonNegative)),
        ]),
        Row(children: [
          Expanded(child: _field('26–40 ปี', age26To40, keyboard: TextInputType.number, validator: _nonNegative)),
          const SizedBox(width: 10),
          Expanded(child: _field('41–59 ปี', age41To59, keyboard: TextInputType.number, validator: _nonNegative)),
        ]),
        _field('60 ปีขึ้นไป', age60Plus, keyboard: TextInputType.number, validator: _nonNegative),
        Builder(builder: (context) {
          final ageTotal = [ageUnder15, age15To25, age26To40, age41To59, age60Plus]
              .fold<int>(0, (sum, c) => sum + (int.tryParse(c.text.trim()) ?? 0));
          return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFE7F5F2), borderRadius: BorderRadius.circular(12)), child: Text('รวมตามช่วงอายุ  $ageTotal คน', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF087F78))));
        }),
        _sectionTitle('ผลการดำเนินงาน', 'บันทึกวัตถุประสงค์ รายละเอียด และผลที่เกิดขึ้น', Icons.fact_check_outlined),
        _field('วัตถุประสงค์', objectives, lines: 2),
        _field('รายละเอียดการดำเนินกิจกรรม', details, lines: 3),
        _field('ผลที่ได้รับ / ผลการดำเนินงาน', outcomes, lines: 3),
        _field('ปัญหาและอุปสรรค', problems, lines: 2),
        _field('ข้อเสนอแนะ', suggestions, lines: 2),
        _sectionTitle('ภาพประกอบกิจกรรม', 'เพิ่มภาพถ่ายเพื่อเป็นหลักฐานการดำเนินงาน', Icons.photo_library_outlined),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ...oldPhotoIds.map((id) => Stack(children: [ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.network(widget.drive.viewUrl(id), width: 78, height: 70, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 78, height: 70, child: Icon(Icons.broken_image)))), Positioned(right: 0, top: 0, child: InkWell(onTap: () => setState(() => oldPhotoIds.remove(id)), child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 13, color: Colors.white))))])),
          ...newPhotos.map((f) => FutureBuilder<Uint8List>(future: f.readAsBytes(), builder: (_, snap) => snap.hasData ? ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.memory(snap.data!, width: 78, height: 70, fit: BoxFit.cover)) : const SizedBox(width: 78, height: 70, child: Center(child: CircularProgressIndicator(strokeWidth: 2))))),
          OutlinedButton.icon(onPressed: _pickPhotos, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('เพิ่มภาพ')),
        ]),
      ]))),
      Padding(padding: const EdgeInsets.fromLTRB(18, 10, 18, 18), child: SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saving ? null : _save, icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save_rounded), label: Text(saving ? 'กำลังบันทึก...' : 'บันทึกรายงาน'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00897B), padding: const EdgeInsets.symmetric(vertical: 14))))),
    ])),
  ));
}
