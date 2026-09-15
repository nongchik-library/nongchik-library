import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data_form_page.dart';
import 'data_list_page.dart';

class DataDetailPage extends StatefulWidget {
  final DataType type;
  final Map<String, dynamic> row;

  const DataDetailPage({super.key, required this.type, required this.row});

  @override
  State<DataDetailPage> createState() => _DataDetailPageState();
}

class _DataDetailPageState extends State<DataDetailPage> {
  final client = Supabase.instance.client;
  List<String> photoUrls = [];
  List<String> certificateUrls = [];
  List<String> photoDriveIds = [];
  List<String> certificateDriveIds = [];
  String personPhotoUrl = '';
  bool loadingPhotos = true;
  bool admin = false;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _loadRole();
  }


  Future<void> _loadRole() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final p = await client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      if (mounted) setState(() => admin = p?['role'] == 'admin');
    } catch (_) {}
  }

  void _loadPhotos() {
    // Production-stable image path: build the first real Google Drive
    // thumbnail synchronously. No image-loading setState and no PageView.
    final driveRaw = widget.row['photo_drive_ids'];
    final ids = <String>[];
    if (driveRaw is List) {
      for (final e in driveRaw) {
        final id = e.toString().trim();
        if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
      }
    } else if (driveRaw is String && driveRaw.trim().isNotEmpty) {
      final s = driveRaw.trim();
      if (s.startsWith('[') && s.endsWith(']')) {
        for (final part in s.substring(1, s.length - 1).split(',')) {
          final id = part.trim().replaceAll('"', '').replaceAll("'", '');
          if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
        }
      } else {
        ids.add(s);
      }
    }

    photoDriveIds = ids.take(5).toList();
    photoUrls = photoDriveIds
        .map((id) =>
            'https://ddldegnsupfeqfzbjjcr.supabase.co/functions/v1/drive-image'
            '?file_id=${Uri.encodeComponent(id)}&thumb=1&size=480')
        .toList();

    final certRaw = widget.row['certificate_drive_ids'];
    certificateDriveIds = certRaw is List
        ? certRaw.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];
    certificateUrls = certificateDriveIds
        .map((id) => 'https://drive.google.com/file/d/$id/view')
        .toList();
    final personId = widget.row['person_photo_drive_id']?.toString().trim() ?? '';
    personPhotoUrl = personId.isEmpty ? '' : _driveProxyUrl(personId, size: 480);
    loadingPhotos = false;
  }

  Future<void> _openMaps() async {
    final lat = (widget.row['latitude'] as num?)?.toDouble();
    final lng = (widget.row['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเปิด Google Maps ได้')),
      );
    }
  }


  String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\"', '&quot;')
        .replaceAll("'", '&#39;')
        .replaceAll('\n', '<br>');
  }

  String _printDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    final raw = value.toString();
    try {
      final d = DateTime.parse(raw).toLocal();
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)} น.';
    } catch (_) {
      return raw;
    }
  }

  String _categoryPrintName() => widget.type.title;

  String _driveProxyUrl(String id, {int size = 640}) {
    return 'https://ddldegnsupfeqfzbjjcr.supabase.co/functions/v1/drive-image'
        '?file_id=${Uri.encodeComponent(id)}&thumb=1&size=$size';
  }

  String _personName() {
    final first = widget.row['first_name']?.toString().trim() ?? '';
    final last = widget.row['last_name']?.toString().trim() ?? '';
    return [first, last].where((e) => e.isNotEmpty).join(' ');
  }

  String _certificateImageUrl(String id) => _driveProxyUrl(id, size: 640);

  String _detailRowHtml(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == '-') return '';
    return '''
      <div class="detail-row">
        <div class="detail-label">${_escapeHtml(label)}</div>
        <div class="detail-value">${_escapeHtml(text)}</div>
      </div>
    ''';
  }

  void _printPdf() {
    final row = widget.row;
    final name = row['name']?.toString().trim() ?? '-';
    final firstName = row['first_name']?.toString().trim() ?? '';
    final lastName = row['last_name']?.toString().trim() ?? '';
    final gender = row['gender']?.toString().trim() ?? '';
    final birthDate = row['birth_date']?.toString().trim() ?? '';
    final educationLevel = row['education_level']?.toString().trim() ?? '';
    final currentOccupation = row['current_occupation']?.toString().trim() ?? '';
    final responsibleTeacher = row['responsible_teacher']?.toString().trim() ?? '';
    final learningProcess = row['learning_process']?.toString().trim() ?? '';
    final personName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
    final subdistrict = row['subdistrict']?.toString().trim() ?? '';
    final description = row['description']?.toString().trim() ?? '';
    final address = row['address']?.toString().trim() ?? '';
    final contact = row['contact']?.toString().trim() ?? '';
    final position = row['position']?.toString().trim() ?? '';
    final phone = row['contact_phone']?.toString().trim() ?? '';
    final lineId = row['contact_line']?.toString().trim() ?? '';
    final facebook = row['contact_facebook']?.toString().trim() ?? '';
    final tiktok = row['contact_tiktok']?.toString().trim() ?? '';
    final extra = row['extra_info']?.toString().trim() ?? '';
    final backgroundHistory = row['background_history']?.toString().trim() ?? '';
    final resourceHistory = row['resource_history']?.toString().trim() ?? '';
    final awards = row['awards']?.toString().trim() ?? '';
    final status = row['status']?.toString() ?? 'pending';
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    final mapsUrl = lat != null && lng != null
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
        : '';

    String imageCard(String url, int index, {bool featured = false}) {
      return '''
        <figure class="photo-card ${featured ? 'featured-photo' : ''}">
          <img src="${_escapeHtml(url)}" alt="ภาพประกอบ $index" />
          <figcaption>ภาพที่ $index</figcaption>
        </figure>
      ''';
    }

    final featuredHtml = photoUrls.isNotEmpty
        ? imageCard(photoUrls.first, 1, featured: true)
        : '''<div class="photo-placeholder"><div class="placeholder-icon">▧</div><div>ไม่มีรูปภาพประกอบ</div></div>''';

    final galleryHtml = photoUrls.length > 1
        ? photoUrls.asMap().entries.skip(1).map((entry) {
            return imageCard(entry.value, entry.key + 1);
          }).join()
        : '';

    final statusText = _statusText(status);
    final statusClass = status == 'approved'
        ? 'approved'
        : status == 'rejected'
            ? 'rejected'
            : 'pending';

    final detailRows = [
      _detailRowHtml('รายละเอียด', description),
      _detailRowHtml('ที่อยู่ / สถานที่', address),
      _detailRowHtml('ผู้รับผิดชอบ', contact),
      if (widget.type == DataType.subdistrictLearningCenter) ...[
        _detailRowHtml('ตำแหน่ง', position),
        _detailRowHtml('เบอร์โทรศัพท์', phone),
      ],
      _detailRowHtml('ID Line', lineId),
      _detailRowHtml('Facebook', facebook),
      _detailRowHtml('TikTok', tiktok),
      _detailRowHtml(
        _categoryPrintName() == 'แหล่งเรียนรู้'
            ? 'ประเภท / กิจกรรมการเรียนรู้'
            : 'ข้อมูลเพิ่มเติม',
        extra,
      ),
      if (widget.type != DataType.subdistrictLearningCenter) ...[
        _detailRowHtml('เพศ', gender),
        _detailRowHtml('วัน เดือน ปี เกิด', birthDate),
        _detailRowHtml('จบการศึกษาระดับ', educationLevel),
        _detailRowHtml('อาชีพปัจจุบัน', currentOccupation),
        _detailRowHtml('ครูผู้รับผิดชอบ', responsibleTeacher),
        _detailRowHtml('ตำแหน่ง', position),
        _detailRowHtml('เบอร์โทรติดต่อ', phone),
      ],
      _detailRowHtml('ประวัติความเป็นมา', backgroundHistory),
      _detailRowHtml('ประวัติของแหล่งเรียนรู้', resourceHistory),
      if (widget.type != DataType.subdistrictLearningCenter) _detailRowHtml('กระบวนการเรียนรู้', learningProcess),
      _detailRowHtml('รางวัลที่ได้รับ', awards),
      ...[
        _detailRowHtml('ลักษณะการใช้อาคาร', row['building_use']),
        _detailRowHtml('กรณีได้รับอนุญาต', row['permission_case']),
        _detailRowHtml('ความเป็นเอกเทศ', row['independence']),
        _detailRowHtml('วันจันทร์-ศุกร์', row['weekday_hours']),
        _detailRowHtml('วันเสาร์-อาทิตย์', row['weekend_hours']),
        _detailRowHtml('วันเปิดทำการ', row['opening_days']),
        _detailRowHtml('อินเตอร์เน็ต', row['internet']),
        _detailRowHtml('น้ำประปา', row['water_supply']),
        _detailRowHtml('ไฟฟ้า', row['electricity']),
        _detailRowHtml('สุขา', row['toilet']),
        _detailRowHtml('Notebook', row['notebook']),
        _detailRowHtml('Desktop', row['desktop']),
        _detailRowHtml('TV', row['tv']),
        _detailRowHtml('Tablet', row['tablet']),
        _detailRowHtml('Projector', row['projector']),
        _detailRowHtml('โต๊ะ', row['tables']),
        _detailRowHtml('เก้าอี้', row['chairs']),
      ],
    ].where((e) => e.isNotEmpty).join();

    final certificateHtml = certificateUrls.isNotEmpty
        ? '''<section class="section"><div class="section-title"><span class="section-number">05</span><span>เกียรติบัตร / หลักฐานรางวัล</span></div><div class="certificate-list">${certificateUrls.asMap().entries.map((e) => '<div class="certificate-item"><strong>เกียรติบัตร ${e.key + 1}</strong><a href="${_escapeHtml(e.value)}">เปิดไฟล์เกียรติบัตร</a></div>').join()}</div></section>'''
        : '';

    final gpsHtml = lat != null && lng != null
        ? '''
          <section class="section">
            <div class="section-title"><span class="section-number">04</span><span>พิกัดสถานที่</span></div>
            <div class="gps-grid">
              <div class="gps-item"><span>Latitude</span><strong>${lat.toStringAsFixed(6)}</strong></div>
              <div class="gps-item"><span>Longitude</span><strong>${lng.toStringAsFixed(6)}</strong></div>
              <div class="maps-item"><span>ตำแหน่งแผนที่</span><a href="${_escapeHtml(mapsUrl)}">เปิดตำแหน่งบน Google Maps</a></div>
            </div>
          </section>
        '''
        : '';

    final mapHtml = lat != null && lng != null
        ? '''
          <section class="section map-section">
            <div class="section-title"><span class="section-number">03</span><span>แผนที่แหล่งเรียนรู้</span></div>
            <div class="map-card">
              <iframe
                title="แผนที่ตำแหน่งแหล่งเรียนรู้"
                src="https://www.google.com/maps?q=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}&z=16&output=embed"
                loading="eager"
                referrerpolicy="no-referrer-when-downgrade">
              </iframe>
              <div class="map-pin" aria-label="หมุดสถานที่">
                <div class="pin-label">${_escapeHtml(name)}</div>
                <div class="pin-marker"><span></span></div>
              </div>
            </div>
            <div class="map-caption">พิกัด ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)} • เปิดดูแผนที่แบบละเอียดได้จากลิงก์ Google Maps ด้านล่าง</div>
          </section>
        '''
        : '''
          <section class="section map-section">
            <div class="section-title"><span class="section-number">03</span><span>แผนที่แหล่งเรียนรู้</span></div>
            <div class="map-placeholder">ยังไม่ได้บันทึกพิกัดสถานที่ จึงไม่สามารถแสดงแผนที่ได้</div>
          </section>
        ''';

    final created = _printDate(row['created_at']);
    final updated = _printDate(row['updated_at']);
    final id = row['id']?.toString() ?? '-';
    final galleryPageCount = photoUrls.length > 1 ? ((photoUrls.length - 1) + 3) ~/ 4 : 0;
    final certificatePageCount = certificateDriveIds.isNotEmpty ? 1 : 0;
    final totalPages = 2 + certificatePageCount + galleryPageCount;
    final galleryPagesHtml = <String>[];
    if (photoUrls.length > 1) {
      final extras = photoUrls.asMap().entries.skip(1).toList();
      for (var start = 0; start < extras.length; start += 4) {
        final chunk = extras.skip(start).take(4).toList();
        final gallery = chunk.map((entry) => imageCard(entry.value, entry.key + 1)).join();
        final pageNumber = 3 + certificatePageCount + galleryPagesHtml.length;
        galleryPagesHtml.add('''
<section class="page">
<header class="header">
  <div><div class="brand">ภาพประกอบข้อมูล</div><div class="subtitle">${_escapeHtml(name)}</div></div>
  <div class="doc-meta">${_escapeHtml(_categoryPrintName())}<br>ภาพประกอบเพิ่มเติม</div>
</header>
<section class="section">
  <div class="section-title"><span class="section-number">02</span><span>ภาพประกอบเพิ่มเติม</span></div>
  <div class="gallery-intro">ภาพประกอบทั้งหมด ${photoUrls.length} ภาพ — ภาพหลักแสดงในหน้าแรก</div>
  <div class="gallery-grid">$gallery</div>
</section>
<footer class="footer"><div>งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก</div><div>หน้า $pageNumber / $totalPages</div></footer>
</section>''');
      }
    }
    final galleryPages = galleryPagesHtml.join('\n');

    final personHtml = personPhotoUrl.isNotEmpty
        ? '''<div class="person-card"><img src="${_escapeHtml(personPhotoUrl)}" alt="ภาพบุคคล"><div class="person-info"><div class="person-label">บุคคลผู้ให้ข้อมูล</div><div class="person-name">${_escapeHtml(personName.isEmpty ? '-' : personName)}</div>${position.isNotEmpty ? '<div class="person-position">${_escapeHtml(position)}</div>' : ''}</div></div>'''
        : (personName.isNotEmpty ? '''<div class="person-card no-person-photo"><div class="person-info"><div class="person-label">บุคคลผู้ให้ข้อมูล</div><div class="person-name">${_escapeHtml(personName)}</div>${position.isNotEmpty ? '<div class="person-position">${_escapeHtml(position)}</div>' : ''}</div></div>''' : '');

    final certificateImageHtml = certificateDriveIds.isEmpty
        ? ''
        : certificateDriveIds.asMap().entries.map((e) => '''<figure class="certificate-photo"><img src="${_escapeHtml(_certificateImageUrl(e.value))}" alt="ภาพหลักฐานเกียรติบัตร ${e.key + 1}"><figcaption>หลักฐานเกียรติบัตร ${e.key + 1}</figcaption><a href="${_escapeHtml(certificateUrls[e.key])}">เปิดไฟล์ต้นฉบับ</a></figure>''').join();

    final certificatePageHtml = certificateDriveIds.isNotEmpty
        ? '''<section class="page"><header class="header"><div><div class="brand">เกียรติบัตรและหลักฐาน</div><div class="subtitle">${_escapeHtml(personName.isEmpty ? name : personName)}</div></div><div class="doc-meta">${_escapeHtml(_categoryPrintName())}<br>หลักฐานประกอบ</div></header><section class="section"><div class="section-title"><span class="section-number">05</span><span>ภาพหลักฐานเกียรติบัตร / รางวัล</span></div><div class="certificate-gallery">$certificateImageHtml</div></section><footer class="footer"><div>งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก</div><div>หน้า 3 / $totalPages</div></footer></section>'''
        : '';

    final htmlText = '''<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${_escapeHtml(name)} - ${_escapeHtml(_categoryPrintName())}</title>
<style>
@page { size: A4 portrait; margin: 0; }
* { box-sizing: border-box; }
html, body { margin: 0; padding: 0; }
body { font-family: "Noto Sans Thai", "Leelawadee UI", Tahoma, Arial, sans-serif; color:#19332e; background:#e9efed; font-size:10.2pt; line-height:1.5; -webkit-print-color-adjust:exact; print-color-adjust:exact; }
.page { width:210mm; min-height:267mm; height:auto; padding:13mm 15mm 15mm; margin:0 auto 8mm; background:#fff; position:relative; overflow:visible; page-break-after:always; page-break-inside:auto; }
.page:last-child { page-break-after:auto; }
.header { display:flex; justify-content:space-between; align-items:flex-start; gap:8mm; padding-bottom:3.5mm; border-bottom:1.1mm solid #087f70; }
.brand { color:#087f70; font-weight:800; font-size:16pt; line-height:1.2; }
.subtitle { color:#657a74; font-size:8pt; margin-top:1mm; }
.doc-meta { color:#657a74; font-size:7pt; line-height:1.45; text-align:right; }
.hero { margin-top:5mm; padding:5mm 6mm; border:1px solid #c9dfda; border-radius:3.5mm; background:#eef8f5; }
.category { color:#087f70; font-weight:800; font-size:8.5pt; }
h1 { color:#123f38; margin:1mm 0 .8mm; font-size:20pt; line-height:1.2; }
.location { color:#536a63; font-size:8.8pt; }
.badge { display:inline-block; margin-top:2mm; padding:.8mm 3mm; border-radius:8mm; font-weight:800; font-size:7.5pt; }
.badge.approved { background:#ddf3e5; color:#176d3d; }
.badge.pending { background:#fff0d1; color:#8d5c00; }
.badge.rejected { background:#ffe1e1; color:#a32d2d; }
.section { margin-top:4.5mm; }
.section-title { display:flex; align-items:center; gap:2.2mm; color:#087f70; font-weight:800; font-size:10.5pt; padding-bottom:1.5mm; border-bottom:1px solid #d9e6e3; }
.section-number { width:7mm; height:7mm; border-radius:50%; background:#087f70; color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:6.5pt; }
.feature-label { margin:4mm 0 1.5mm; color:#087f70; font-weight:800; font-size:9.5pt; }
.photo-card { margin:0; border:1px solid #d5e3df; border-radius:3mm; overflow:hidden; background:#fbfdfc; }
.photo-card img { display:block; width:100%; height:58mm; object-fit:contain; background:#f3f7f6; }
.featured-photo img { height:64mm; }
.photo-card figcaption { text-align:center; padding:1mm; font-size:7.5pt; color:#62766f; }
.photo-placeholder { height:76mm; border:1px dashed #b8cbc5; border-radius:3mm; display:flex; flex-direction:column; align-items:center; justify-content:center; color:#748780; background:#f8fbfa; }
.placeholder-icon { font-size:24pt; color:#9eb5ae; }
.detail-box { margin-top:2mm; border:1px solid #dce8e5; border-radius:3mm; overflow:hidden; }
.detail-row { display:grid; page-break-inside:avoid; break-inside:avoid; grid-template-columns:43mm 1fr; border-bottom:1px solid #e4ecea; min-height:8.5mm; }
.detail-row:last-child { border-bottom:0; }
.detail-label { padding:1.8mm 2.8mm; background:#f4f9f7; color:#4d6760; font-weight:800; }
.detail-value { padding:1.8mm 2.8mm; color:#203b36; overflow-wrap:anywhere; }
.gps-grid { margin-top:2.5mm; display:grid; grid-template-columns:1fr 1fr; gap:3mm; }
.gps-item,.maps-item,.system-card { border:1px solid #d7e7e2; border-radius:3mm; padding:2.5mm 3mm; background:#f5faf8; }
.gps-item span,.maps-item span,.system-card span { display:block; color:#6a7e78; font-size:7.2pt; }
.map-card { position:relative; margin-top:2.5mm; border:1px solid #d7e7e2; border-radius:3mm; overflow:hidden; background:#eef5f3; }
.map-card iframe { display:block; width:100%; height:88mm; border:0; }
.map-pin { position:absolute; left:50%; top:50%; transform:translate(-50%,-50%); z-index:5; pointer-events:none; display:flex; flex-direction:column; align-items:center; }
.pin-label { max-width:58mm; margin-bottom:1.5mm; padding:1.2mm 2.5mm; border-radius:2mm; background:#087f70; color:#fff; font-size:7.5pt; font-weight:800; line-height:1.25; text-align:center; box-shadow:0 1mm 2.5mm rgba(0,0,0,.22); white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
.pin-marker { width:9mm; height:9mm; background:#d62828; border:1.2mm solid #fff; border-radius:50% 50% 50% 0; transform:rotate(-45deg); box-shadow:0 1mm 2.5mm rgba(0,0,0,.35); display:flex; align-items:center; justify-content:center; }
.pin-marker span { width:2.6mm; height:2.6mm; background:#fff; border-radius:50%; }
.map-caption { margin-top:1.5mm; color:#667b75; font-size:7.3pt; }
.map-placeholder { margin-top:2.5mm; min-height:35mm; display:flex; align-items:center; justify-content:center; border:1px dashed #b8cbc5; border-radius:3mm; background:#f7faf9; color:#748780; font-size:9pt; text-align:center; padding:5mm; }
.gps-item strong { display:block; margin-top:.5mm; color:#183f38; font-size:10pt; }
.maps-item { grid-column:1 / -1; }
a { color:#087f70; text-decoration:none; }
.system-grid { margin-top:2.5mm; display:grid; grid-template-columns:1fr 1fr; gap:3mm; }
.system-card strong { display:block; margin-top:.7mm; color:#29433e; font-size:8.5pt; overflow-wrap:anywhere; }
.gallery-grid { margin-top:3.5mm; display:grid; grid-template-columns:1fr 1fr; gap:5mm; }
.gallery-grid .photo-card img { height:58mm; }
.gallery-intro { margin-top:2mm; color:#657a74; font-size:8pt; }
.footer { position:static; margin-top:6mm; padding-top:2mm; border-top:1px solid #dce7e4; display:flex; justify-content:space-between; color:#788984; font-size:7pt; page-break-inside:avoid; }
.person-card{margin-top:3mm;page-break-inside:avoid;break-inside:avoid;display:flex;align-items:center;gap:4mm;padding:3.5mm;border:1px solid #cfe2dd;border-radius:4mm;background:#f3faf7}.person-card img{width:30mm;height:36mm;object-fit:cover;border-radius:3mm;border:1px solid #d3e3df;background:#eef5f3}.person-info{flex:1}.person-label{font-size:7.5pt;color:#6a7d77;font-weight:700}.person-name{margin-top:1mm;font-size:15pt;color:#123f38;font-weight:800}.no-person-photo{min-height:20mm}.certificate-gallery{margin-top:3mm;display:grid;grid-template-columns:1fr 1fr;gap:5mm}.certificate-photo{margin:0;padding:3mm;page-break-inside:avoid;break-inside:avoid;border:1px solid #d5e3df;border-radius:3mm;background:#fbfdfc;text-align:center;page-break-inside:avoid}.certificate-photo img{display:block;width:100%;height:68mm;object-fit:contain;background:#f3f7f6;border:1px solid #d6e5e1;border-radius:2mm}.certificate-photo figcaption{font-size:8pt;color:#62766f;margin-top:1.5mm}.certificate-photo a{font-size:7.5pt;color:#087f70;font-weight:800;text-decoration:none}
@media print { body{background:#fff;} .page{margin:0; box-shadow:none;} }
@media screen { .page{box-shadow:0 2px 18px rgba(25,55,49,.12);} }
</style>
</head>
<body>
<section class="page">
<header class="header">
  <div><div class="brand">งานการศึกษาตลอดชีวิต</div><div class="subtitle">ห้องสมุดประชาชนอำเภอหนองจิก<br>ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก<br>สำนักงานส่งเสริมการเรียนรู้ประจำจังหวัดปัตตานี</div></div>
  <div class="doc-meta">รายงานข้อมูลแหล่งเรียนรู้<br>พิมพ์เมื่อ ${_escapeHtml(_printDate(DateTime.now().toIso8601String()))}</div>
</header>
<section class="hero">
  <div class="category">${_escapeHtml(_categoryPrintName())}</div>
  <h1>${_escapeHtml(name)}</h1>
  <div class="location">${subdistrict.isNotEmpty ? '${_categoryPrintName() == 'ศกร.ระดับตำบล' ? 'ศกร.ระดับตำบล' : 'ตำบล'}${_escapeHtml(subdistrict)} • ' : ''}อำเภอหนองจิก • จังหวัดปัตตานี</div>
  <span class="badge $statusClass">สถานะ: ${_escapeHtml(statusText)}</span>
</section>
$personHtml
<div class="feature-label">ภาพหลัก</div>
$featuredHtml
<section class="section">
  <div class="section-title"><span class="section-number">01</span><span>รายละเอียดข้อมูล</span></div>
  <div class="detail-box">
    ${detailRows.isNotEmpty ? detailRows : '<div class="detail-row"><div class="detail-label">ข้อมูล</div><div class="detail-value">ไม่มีรายละเอียดเพิ่มเติม</div></div>'}
  </div>
</section>
<footer class="footer"><div>งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก</div><div>หน้า 1 / $totalPages</div></footer>
</section>

<section class="page">
<header class="header">
  <div><div class="brand">ข้อมูลแหล่งเรียนรู้</div><div class="subtitle">${_escapeHtml(name)}</div></div>
  <div class="doc-meta">${_escapeHtml(_categoryPrintName())}<br>เอกสารประกอบ</div>
</header>
$mapHtml
$gpsHtml
<section class="section">
  <div class="section-title"><span class="section-number">05</span><span>ข้อมูลระบบ</span></div>
  <div class="system-grid">
    <div class="system-card"><span>วันที่สร้างข้อมูล</span><strong>${_escapeHtml(created)}</strong></div>
    <div class="system-card"><span>วันที่แก้ไขล่าสุด</span><strong>${_escapeHtml(updated)}</strong></div>
    <div class="system-card" style="grid-column:1 / -1"><span>รหัสข้อมูล</span><strong>${_escapeHtml(id)}</strong></div>
  </div>
</section>
<footer class="footer"><div>งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก</div><div>หน้า 2 / $totalPages</div></footer>
</section>
$certificatePageHtml
$galleryPages
<script>
(function () {
  var images = Array.prototype.slice.call(document.images);
  var frames = Array.prototype.slice.call(document.querySelectorAll('iframe'));
  var pending = images.length + frames.length;
  var printed = false;
  function doPrint(){ if(printed)return; printed=true; setTimeout(function(){window.print();},700); }
  if(!pending){doPrint();return;}
  function done(){pending--;if(pending<=0)doPrint();}
  images.forEach(function(img){if(img.complete)done();else{img.addEventListener('load',done);img.addEventListener('error',done);}});
  frames.forEach(function(frame){frame.addEventListener('load',done);frame.addEventListener('error',done);});
  setTimeout(doPrint,15000);
})();
</script>
</body>
</html>''';

    final blob = html.Blob([htmlText], 'text/html;charset=utf-8');
    final printUrl = html.Url.createObjectUrlFromBlob(blob);
    final printWindow = html.window.open(printUrl, '_blank');
    if (printWindow == null) {
      html.Url.revokeObjectUrl(printUrl);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('เบราว์เซอร์บล็อกหน้าต่างพิมพ์ กรุณาอนุญาต Pop-up แล้วลองอีกครั้ง')),
        );
      }
      return;
    }
    Future.delayed(const Duration(seconds: 14), () {
      html.Url.revokeObjectUrl(printUrl);
    });
  }

  Future<void> _downloadWord() async {
    final row = widget.row;
    final name = row['name']?.toString().trim() ?? '-';
    final firstName = row['first_name']?.toString().trim() ?? '';
    final lastName = row['last_name']?.toString().trim() ?? '';
    final gender = row['gender']?.toString().trim() ?? '';
    final birthDate = row['birth_date']?.toString().trim() ?? '';
    final educationLevel = row['education_level']?.toString().trim() ?? '';
    final currentOccupation = row['current_occupation']?.toString().trim() ?? '';
    final responsibleTeacher = row['responsible_teacher']?.toString().trim() ?? '';
    final learningProcess = row['learning_process']?.toString().trim() ?? '';
    final personName = [firstName, lastName].where((e) => e.isNotEmpty).join(' ');
    final subdistrict = row['subdistrict']?.toString().trim() ?? '';
    final description = row['description']?.toString().trim() ?? '';
    final address = row['address']?.toString().trim() ?? '';
    final contact = row['contact']?.toString().trim() ?? '';
    final position = row['position']?.toString().trim() ?? '';
    final phone = row['contact_phone']?.toString().trim() ?? '';
    final lineId = row['contact_line']?.toString().trim() ?? '';
    final facebook = row['contact_facebook']?.toString().trim() ?? '';
    final tiktok = row['contact_tiktok']?.toString().trim() ?? '';
    final extra = row['extra_info']?.toString().trim() ?? '';
    final backgroundHistory = row['background_history']?.toString().trim() ?? '';
    final resourceHistory = row['resource_history']?.toString().trim() ?? '';
    final awards = row['awards']?.toString().trim() ?? '';
    final status = _statusText(row['status']?.toString() ?? 'pending');
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    final mapsUrl = lat != null && lng != null
        ? 'https://www.google.com/maps/search/?api=1&query=$lat,$lng'
        : '';

    String esc(String value) => _escapeHtml(value);
    String cell(String label, String value) {
      final safe = value.trim().isEmpty ? '-' : value;
      return '<tr><td class="label">${esc(label)}</td><td>${esc(safe).replaceAll('\n', '<br>')}</td></tr>';
    }

    final embeddedPhotos = <String>[];
    for (final url in photoUrls) {
      try {
        final request = await html.HttpRequest.request(url, responseType: 'arraybuffer');
        final response = request.response;
        if (response is ByteBuffer) {
          final bytes = response.asUint8List();
          final mime = request.getResponseHeader('content-type') ?? 'image/jpeg';
          embeddedPhotos.add('data:$mime;base64,${base64Encode(bytes)}');
        } else {
          embeddedPhotos.add(url);
        }
      } catch (_) {
        embeddedPhotos.add(url);
      }
    }

    String personEmbedded = '';
    if (personPhotoUrl.isNotEmpty) {
      try {
        final request = await html.HttpRequest.request(personPhotoUrl, responseType: 'arraybuffer');
        final response = request.response;
        if (response is ByteBuffer) {
          final bytes = response.asUint8List();
          final mime = request.getResponseHeader('content-type') ?? 'image/jpeg';
          personEmbedded = 'data:$mime;base64,${base64Encode(bytes)}';
        }
      } catch (_) {}
    }

    final embeddedCertificates = <String>[];
    for (final id in certificateDriveIds) {
      try {
        final request = await html.HttpRequest.request(_certificateImageUrl(id), responseType: 'arraybuffer');
        final response = request.response;
        if (response is ByteBuffer) {
          final bytes = response.asUint8List();
          final mime = request.getResponseHeader('content-type') ?? 'image/jpeg';
          if (mime.startsWith('image/')) {
            embeddedCertificates.add('data:$mime;base64,${base64Encode(bytes)}');
          } else {
            embeddedCertificates.add('');
          }
        } else {
          embeddedCertificates.add('');
        }
      } catch (_) {
        embeddedCertificates.add('');
      }
    }

    String certificateWordHtml() {
      if (certificateDriveIds.isEmpty) return '<div class="no-gps">ไม่มีภาพหลักฐานเกียรติบัตรแนบ</div>';
      return certificateDriveIds.asMap().entries.map((e) {
        final src = e.key < embeddedCertificates.length ? embeddedCertificates[e.key] : '';
        final link = certificateUrls[e.key];
        return '<div class="certificate-photo">${src.isNotEmpty ? '<img src="${esc(src)}" alt="หลักฐานเกียรติบัตร ${e.key + 1}">' : '<div class="certificate-missing">ไม่สามารถแสดงภาพตัวอย่างไฟล์นี้ได้</div>'}<div class="caption">หลักฐานเกียรติบัตร ${e.key + 1}</div><a href="${esc(link)}">เปิดไฟล์ต้นฉบับ</a></div>';
      }).join();
    }

    String imageCard(String src, int index, {bool featured = false}) {
      final cls = featured ? 'photo featured' : 'photo';
      return '<div class="${cls}"><img src="${esc(src)}" alt="ภาพประกอบ $index"><div class="caption">ภาพที่ $index</div></div>';
    }

    final photosHtml = embeddedPhotos.isEmpty
        ? '<div class="no-photo">ไม่มีรูปภาพประกอบ</div>'
        : embeddedPhotos.asMap().entries.map((e) => imageCard(e.value, e.key + 1, featured: e.key == 0)).join();

    final gpsHtml = lat != null && lng != null
        ? '<section class="section"><div class="section-title"><span class="num">03</span>พิกัดและตำแหน่งแผนที่</div><div class="gps-grid"><div class="gps"><span>Latitude</span><strong>${lat.toStringAsFixed(6)}</strong></div><div class="gps"><span>Longitude</span><strong>${lng.toStringAsFixed(6)}</strong></div></div><div class="map-link"><span>📍 ตำแหน่งสถานที่</span><a href="${esc(mapsUrl)}">เปิดตำแหน่งบน Google Maps</a></div></section>'
        : '<section class="section"><div class="section-title"><span class="num">03</span>พิกัดและตำแหน่งแผนที่</div><div class="no-gps">ยังไม่ได้บันทึกพิกัด GPS</div></section>';

    final certificateHtml = certificateWordHtml();
    final personWordHtml = personName.isEmpty && personEmbedded.isEmpty
        ? ''
        : '<section class="section"><div class="section-title"><span class="num">01</span>บุคคลผู้ให้ข้อมูล</div><div class="person-card">${personEmbedded.isNotEmpty ? '<img src="${esc(personEmbedded)}" alt="ภาพบุคคล">' : ''}<div class="person-info"><div class="person-name">${esc(personName.isEmpty ? '-' : personName)}</div>${position.isNotEmpty ? '<div class="person-position">${esc(position)}</div>' : ''}${phone.isNotEmpty || lineId.isNotEmpty || facebook.isNotEmpty || tiktok.isNotEmpty ? '<div class="person-contact">${phone.isNotEmpty ? 'โทร: ${esc(phone)}' : ''}${lineId.isNotEmpty ? ' • Line: ${esc(lineId)}' : ''}${facebook.isNotEmpty ? ' • Facebook: ${esc(facebook)}' : ''}${tiktok.isNotEmpty ? ' • TikTok: ${esc(tiktok)}' : ''}</div>' : ''}</div></div></section>';

    final printed = _printDate(DateTime.now().toIso8601String());
    final htmlText = '''<!DOCTYPE html>
<html lang="th"><head><meta charset="utf-8"><title>${esc(name)} - ${esc(_categoryPrintName())}</title>
<style>
@page { size:A4 portrait; margin:0; }
*{box-sizing:border-box} body{margin:0;background:#eef4f2;color:#183b35;font-family:"Noto Sans Thai","Leelawadee UI",Tahoma,Arial,sans-serif;font-size:10.5pt;line-height:1.6;-webkit-print-color-adjust:exact;print-color-adjust:exact}
.page{width:210mm;min-height:267mm;background:#fff;margin:0 auto 8mm;padding:12mm 15mm 14mm;position:relative;page-break-after:always;page-break-inside:auto}.page:last-child{page-break-after:auto}
.header{display:flex;justify-content:space-between;gap:10mm;padding-bottom:4mm;border-bottom:1.2mm solid #087f70}.brand{font-size:18pt;font-weight:800;color:#087f70}.subtitle{font-size:8pt;color:#71837e;margin-top:1mm}.docmeta{text-align:right;font-size:7.5pt;color:#71837e}
.hero{margin-top:5mm;padding:6mm;border:1px solid #cfe3de;border-radius:5mm;background:linear-gradient(135deg,#effaf7,#f7fbfa);box-shadow:0 2mm 6mm rgba(20,70,62,.08)}.category{font-size:8.5pt;font-weight:800;color:#087f70}.hero h1{margin:1.5mm 0 1mm;font-size:22pt;line-height:1.2;color:#123f38}.location{font-size:9pt;color:#60756e}.badge{display:inline-block;margin-top:2.5mm;padding:1mm 3.2mm;border-radius:99px;font-weight:800;font-size:8pt}.approved{background:#dcf4e5;color:#176d3d}.pending{background:#fff0d2;color:#8d5c00}
.section{margin-top:5mm}.section-title{display:flex;align-items:center;gap:2mm;color:#087f70;font-weight:800;font-size:11.5pt;border-bottom:1px solid #d8e7e3;padding-bottom:1.8mm}.num{width:7mm;height:7mm;border-radius:50%;background:#087f70;color:white;display:inline-flex;align-items:center;justify-content:center;font-size:7pt}
table{width:100%;border-collapse:collapse;margin-top:3mm}td{border:1px solid #d8e5e2;padding:2.8mm;vertical-align:top} tr{page-break-inside:avoid;break-inside:avoid}td.label{width:34%;background:#f2f8f6;color:#4e6861;font-weight:800}
.photo{width:47%;display:inline-block;vertical-align:top;margin:0 2% 4mm 0;text-align:center;page-break-inside:avoid}.photo:nth-child(2n){margin-right:0}.photo.featured{width:100%;margin-right:0}.photo img{display:block;width:100%;height:54mm;object-fit:contain;background:#f3f8f6;border:1px solid #d6e5e1;border-radius:4mm}.photo.featured img{height:68mm}.caption{font-size:8pt;color:#6c7e79;margin-top:1mm}.no-photo,.no-gps{padding:12mm;text-align:center;border:1px dashed #b7cbc5;border-radius:4mm;background:#f7faf9;color:#71837e;margin-top:3mm}
.gps-grid{display:grid;grid-template-columns:1fr 1fr;gap:3mm;margin-top:3mm}.gps{padding:3mm;border:1px solid #d4e6e1;border-radius:4mm;background:#f4faf8}.gps span{display:block;font-size:7.5pt;color:#71837e}.gps strong{font-size:11pt;color:#173e37}.map-link{margin-top:3mm;padding:3.2mm 4mm;border:1px solid #d4e6e1;border-radius:4mm;background:#eff8f5;display:flex;justify-content:space-between;gap:5mm}.map-link a{color:#087f70;font-weight:800;text-decoration:none}.certificate-list{margin-top:3mm;display:flex;flex-direction:column;gap:2mm}.certificate-item{padding:3mm 4mm;border:1px solid #d4e6e1;border-radius:3mm;background:#f5faf8;display:flex;justify-content:space-between;gap:5mm}.certificate-item a{color:#087f70;font-weight:800;text-decoration:none}.system{margin-top:3mm}.note{font-size:8pt;color:#71837e;margin-top:2mm}.footer{position:static;margin-top:6mm;border-top:1px solid #dce7e4;padding-top:2mm;display:flex;justify-content:space-between;color:#7b8b87;font-size:7pt;page-break-inside:avoid}
.person-card{margin-top:3mm;page-break-inside:avoid;break-inside:avoid;display:flex;align-items:center;gap:4mm;padding:3.5mm;border:1px solid #cfe2dd;border-radius:4mm;background:#f3faf7}.person-card img{width:30mm;height:36mm;object-fit:cover;border-radius:3mm;border:1px solid #d3e3df;background:#eef5f3}.person-info{flex:1}.person-name{font-size:15pt;color:#123f38;font-weight:800}.person-position{font-size:10.5pt;color:#5b716b;margin-top:1mm;font-weight:700}.person-contact{font-size:9pt;color:#657a74;margin-top:2mm;line-height:1.55}.certificate-photo{display:inline-block;width:47%;vertical-align:top;margin:0 2% 4mm 0;padding:3mm;border:1px solid #d5e3df;border-radius:3mm;background:#fbfdfc;text-align:center}.certificate-photo:nth-child(2n){margin-right:0}.certificate-photo img{display:block;width:100%;height:62mm;object-fit:contain;background:#f3f7f6;border:1px solid #d6e5e1;border-radius:2mm}.certificate-photo .caption{font-size:8pt;color:#62766f;margin-top:1mm}.certificate-photo a{font-size:7.5pt;color:#087f70;font-weight:800;text-decoration:none}.certificate-missing{height:62mm;display:flex;align-items:center;justify-content:center;border:1px dashed #b7cbc5;border-radius:2mm;background:#f7faf9;color:#71837e;font-size:8pt}
@media print{body{background:#fff}.page{margin:0}}
</style></head><body>
<section class="page">
<header class="header"><div><div class="brand">งานการศึกษาตลอดชีวิต</div><div class="subtitle">ห้องสมุดประชาชนอำเภอหนองจิก<br>ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก<br>สำนักงานส่งเสริมการเรียนรู้ประจำจังหวัดปัตตานี</div></div><div class="docmeta">เอกสารข้อมูลแหล่งเรียนรู้<br>พิมพ์เมื่อ ${esc(printed)}</div></header>
<div class="hero"><div class="category">${esc(_categoryPrintName())}</div><h1>${esc(name)}</h1>${personName.isNotEmpty ? '<div class="location"><strong>ผู้ให้ข้อมูล: ${esc(personName)}</strong></div>' : ''}<div class="location">${subdistrict.isNotEmpty ? '${widget.type == DataType.subdistrictLearningCenter ? 'ศกร.ระดับตำบล' : 'ตำบล'}${esc(subdistrict)} • ' : ''}อำเภอหนองจิก • จังหวัดปัตตานี</div><span class="badge ${row['status']?.toString() == 'approved' ? 'approved' : 'pending'}">สถานะ: ${esc(status)}</span></div>
$personWordHtml
<section class="section"><div class="section-title"><span class="num">02</span>ภาพประกอบข้อมูล</div><div style="margin-top:3mm">${photosHtml}</div></section>
<section class="section"><div class="section-title"><span class="num">02</span>รายละเอียดข้อมูล</div><table>${cell('รายละเอียด',description)}${cell('ที่อยู่ / สถานที่',address)}${cell('ผู้รับผิดชอบ',contact)}${widget.type == DataType.subdistrictLearningCenter ? '${cell('ตำแหน่ง',position)}${cell('เบอร์โทรศัพท์',phone)}' : ''}${cell('ID Line',lineId)}${cell('Facebook',facebook)}${cell('TikTok',tiktok)}${cell(_categoryPrintName() == 'แหล่งเรียนรู้' ? 'ประเภท / กิจกรรมการเรียนรู้' : 'ข้อมูลเพิ่มเติม',extra)}${widget.type != DataType.subdistrictLearningCenter ? '${cell('เพศ',gender)}${cell('วัน เดือน ปี เกิด',birthDate)}${cell('จบการศึกษาระดับ',educationLevel)}${cell('อาชีพปัจจุบัน',currentOccupation)}${cell('ครูผู้รับผิดชอบ',responsibleTeacher)}${cell('ตำแหน่ง',position)}${cell('เบอร์โทรติดต่อ',phone)}' : ''}${cell('ประวัติความเป็นมา',backgroundHistory)}${cell('ประวัติของแหล่งเรียนรู้',resourceHistory)}${widget.type != DataType.subdistrictLearningCenter ? cell('กระบวนการเรียนรู้',learningProcess) : ''}${cell('รางวัลที่ได้รับ',awards)}${'''
${cell('ลักษณะการใช้อาคาร',row['building_use']?.toString() ?? '')}
${cell('กรณีได้รับอนุญาต',row['permission_case']?.toString() ?? '')}
${cell('ความเป็นเอกเทศ',row['independence']?.toString() ?? '')}
${cell('วันจันทร์-ศุกร์',row['weekday_hours']?.toString() ?? '')}
${cell('วันเสาร์-อาทิตย์',row['weekend_hours']?.toString() ?? '')}
${cell('วันเปิดทำการ',row['opening_days']?.toString() ?? '')}
${cell('อินเตอร์เน็ต',row['internet']?.toString() ?? '')}
${cell('น้ำประปา',row['water_supply']?.toString() ?? '')}
${cell('ไฟฟ้า',row['electricity']?.toString() ?? '')}
${cell('สุขา',row['toilet']?.toString() ?? '')}
${cell('Notebook',row['notebook']?.toString() ?? '')}
${cell('Desktop',row['desktop']?.toString() ?? '')}
${cell('TV',row['tv']?.toString() ?? '')}
${cell('Tablet',row['tablet']?.toString() ?? '')}
${cell('Projector',row['projector']?.toString() ?? '')}
${cell('โต๊ะ',row['tables']?.toString() ?? '')}
${cell('เก้าอี้',row['chairs']?.toString() ?? '')}
'''}</table></section>
<footer class="footer"><span>งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก</span><span>หน้า 1</span></footer>
</section>
<section class="page">
<header class="header"><div><div class="brand">ข้อมูลตำแหน่งและเอกสารประกอบ</div><div class="subtitle">${esc(name)}</div></div><div class="docmeta">${esc(_categoryPrintName())}</div></header>
${gpsHtml}
${certificateHtml}
<section class="section"><div class="section-title"><span class="num">04</span>ข้อมูลระบบ</div><table class="system">${cell('วันที่สร้างข้อมูล',_printDate(row['created_at']))}${cell('วันที่แก้ไขล่าสุด',_printDate(row['updated_at']))}${cell('รหัสข้อมูล',row['id']?.toString() ?? '-')}</table><div class="note">เอกสารนี้สร้างจากข้อมูลที่บันทึกในระบบงานการศึกษาตลอดชีวิต ห้องสมุดประชาชนอำเภอหนองจิก</div></section>
<footer class="footer"><span>งานการศึกษาตลอดชีวิต • ห้องสมุดประชาชนอำเภอหนองจิก</span><span>หน้า 2</span></footer>
</section>
</body></html>''';

    final blob = html.Blob([htmlText], 'application/msword;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = '${_safeFileName(name)}.doc'
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 3), () => html.Url.revokeObjectUrl(url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ดาวน์โหลดไฟล์ Word รูปแบบสวยงามเรียบร้อยแล้ว')),
      );
    }
  }

  String _safeFileName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'nongchik_library' : cleaned;
  }

  Future<void> _edit() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => DataFormPage(type: widget.type, row: widget.row),
      ),
    );
    if (result == true && mounted) Navigator.pop(context, true);
  }

  void _showFullImage(int index) {
    if (photoUrls.isEmpty) return;
    final safeIndex = (index - 1).clamp(0, photoUrls.length - 1);
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    photoUrls[safeIndex],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white24,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText(String value) {
    switch (value) {
      case 'approved':
        return 'อนุมัติแล้ว';
      case 'rejected':
        return 'ไม่อนุมัติ';
      default:
        return 'รอตรวจสอบ';
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

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    final clean = value.trim();
    if (clean.isEmpty || clean == '-') return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(0, 3), color: Color(0x12000000)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(clean, style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 7),
          Text(_statusText(status), style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _personCard() {
    final first = widget.row['first_name']?.toString().trim() ?? '';
    final last = widget.row['last_name']?.toString().trim() ?? '';
    final fullName = [first, last].where((e) => e.isNotEmpty).join(' ');
    if (fullName.isEmpty && personPhotoUrl.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer.withOpacity(.65), scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final image = Container(
            width: compact ? 150 : 175,
            height: compact ? 175 : 205,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: scheme.outlineVariant, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: personPhotoUrl.isNotEmpty
                ? Image.network(
                    personPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.person_outline, size: 72, color: scheme.onSurfaceVariant),
                  )
                : Icon(Icons.person_outline, size: 72, color: scheme.onSurfaceVariant),
          );

          final details = Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: compact ? 0 : 18, top: compact ? 14 : 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ข้อมูลบุคคล', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(fullName.isEmpty ? '-' : fullName, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 8),
                  if (widget.row['subdistrict']?.toString().trim().isNotEmpty ?? false)
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Flexible(child: Text('ตำบล ${widget.row['subdistrict']}', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  const SizedBox(height: 12),
                  _statusChip(widget.row['status']?.toString() ?? 'pending'),
                ],
              ),
            ),
          );

          return compact
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: image), details])
              : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [image, details]);
        },
      ),
    );
  }

  Widget _photos() {
    final urls = photoUrls.take(5).toList();
    final scheme = Theme.of(context).colorScheme;
    if (urls.isEmpty) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.photo_library_outlined, size: 48, color: scheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text('ยังไม่มีรูปภาพประกอบ', style: TextStyle(color: scheme.onSurfaceVariant)),
        ]),
      );
    }

    Widget imageBox(String url, {required double height, required int index, bool main = false}) {
      return InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showFullImage(index),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
                errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white, size: 42)),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text(main ? 'ภาพหลัก' : 'ภาพที่ $index', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      imageBox(urls.first, height: 390, index: 1, main: true),
      if (urls.length > 1) ...[
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth < 650 ? (constraints.maxWidth - 10) / 2 : (constraints.maxWidth - 20) / 3;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 1; i < urls.length; i++)
                SizedBox(width: w, child: imageBox(urls[i], height: 120, index: i + 1)),
            ],
          );
        }),
      ],
      const SizedBox(height: 10),
      Row(children: [
        Icon(Icons.photo_library_outlined, size: 18, color: scheme.primary),
        const SizedBox(width: 6),
        Text('${urls.length} รูปภาพ', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        const Spacer(),
        TextButton.icon(onPressed: () => _showFullImage(1), icon: const Icon(Icons.fullscreen), label: const Text('ดูภาพเต็มจอ')),
      ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final name = row['name']?.toString().trim() ?? '-';
    final status = row['status']?.toString() ?? 'pending';
    final lat = (row['latitude'] as num?)?.toDouble();
    final lng = (row['longitude'] as num?)?.toDouble();
    final hasGps = lat != null && lng != null;
    final userId = client.auth.currentUser?.id;
    final canEdit = admin || row['created_by']?.toString() == userId;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.title, style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: _printPdf, icon: const Icon(Icons.picture_as_pdf_outlined), tooltip: 'พิมพ์ / PDF'),
          IconButton(onPressed: _downloadWord, icon: const Icon(Icons.description_outlined), tooltip: 'ดาวน์โหลด Word'),
          if (canEdit) IconButton(onPressed: _edit, icon: const Icon(Icons.edit_outlined), tooltip: 'แก้ไขข้อมูล'),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [BoxShadow(blurRadius: 14, offset: Offset(0, 5), color: Color(0x22000000))],
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.type.title, style: TextStyle(color: scheme.onPrimary.withOpacity(.82), fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Text(name, style: TextStyle(color: scheme.onPrimary, fontSize: 29, fontWeight: FontWeight.w900, height: 1.2)),
                      const SizedBox(height: 7),
                      if ((row['subdistrict']?.toString().trim() ?? '').isNotEmpty)
                        Text('ตำบล ${row['subdistrict']} • อำเภอหนองจิก • จังหวัดปัตตานี', style: TextStyle(color: scheme.onPrimary.withOpacity(.86), fontSize: 14)),
                    ])),
                    const SizedBox(width: 12),
                    _statusChip(status),
                  ]),
                ),
                const SizedBox(height: 22),
                if (personPhotoUrl.isNotEmpty || (row['first_name']?.toString().trim().isNotEmpty ?? false) || (row['last_name']?.toString().trim().isNotEmpty ?? false)) ...[
                  _sectionTitle('ข้อมูลบุคคล', Icons.person_outline),
                  _personCard(),
                  const SizedBox(height: 22),
                ],
                _sectionTitle('ภาพประกอบข้อมูล', Icons.photo_library_outlined),
                _photos(),
                const SizedBox(height: 24),
                _sectionTitle('รายละเอียดข้อมูล', Icons.description_outlined),
                _infoCard(
                  icon: Icons.location_city_outlined,
                  title: widget.type == DataType.subdistrictLearningCenter ? 'ศกร.ระดับตำบล' : 'ตำบล',
                  value: widget.type == DataType.subdistrictLearningCenter
                      ? 'ศกร.ระดับตำบล${row['subdistrict']?.toString() ?? '-'}'
                      : row['subdistrict']?.toString() ?? '-',
                ),
                _infoCard(icon: Icons.description_outlined, title: 'รายละเอียด', value: row['description']?.toString() ?? '-'),
                _infoCard(icon: Icons.place_outlined, title: 'ที่อยู่ / สถานที่', value: row['address']?.toString() ?? '-'),
                _infoCard(icon: Icons.person_outline, title: 'ผู้รับผิดชอบ', value: row['contact']?.toString() ?? '-'),
                if (widget.type == DataType.subdistrictLearningCenter) ...[
                  _infoCard(icon: Icons.badge_outlined, title: 'ตำแหน่ง', value: row['position']?.toString() ?? '-'),
                  _infoCard(icon: Icons.phone_outlined, title: 'เบอร์โทรศัพท์', value: row['contact_phone']?.toString() ?? '-'),
                ],
                _infoCard(icon: Icons.chat_bubble_outline, title: 'ID Line', value: row['contact_line']?.toString() ?? '-'),
                _infoCard(icon: Icons.facebook, title: 'Facebook', value: row['contact_facebook']?.toString() ?? '-'),
                _infoCard(icon: Icons.music_note_outlined, title: 'TikTok', value: row['contact_tiktok']?.toString() ?? '-'),
                _infoCard(icon: Icons.category_outlined, title: widget.type == DataType.learningResource ? 'ประเภท / กิจกรรมการเรียนรู้' : 'ข้อมูลเพิ่มเติม', value: row['extra_info']?.toString() ?? '-'),
                if (widget.type != DataType.subdistrictLearningCenter) ...[
                  _infoCard(icon: Icons.wc_outlined, title: 'เพศ', value: row['gender']?.toString() ?? '-'),
                  _infoCard(icon: Icons.cake_outlined, title: 'วัน เดือน ปี เกิด', value: row['birth_date']?.toString() ?? '-'),
                  _infoCard(icon: Icons.school_outlined, title: 'จบการศึกษาระดับ', value: row['education_level']?.toString() ?? '-'),
                  _infoCard(icon: Icons.work_outline, title: 'อาชีพปัจจุบัน', value: row['current_occupation']?.toString() ?? '-'),
                  _infoCard(icon: Icons.person_pin_outlined, title: 'ครูผู้รับผิดชอบ', value: row['responsible_teacher']?.toString() ?? '-'),
                  _infoCard(icon: Icons.badge_outlined, title: 'ตำแหน่ง', value: row['position']?.toString() ?? '-'),
                  _infoCard(icon: Icons.phone_in_talk_outlined, title: 'เบอร์โทรติดต่อ', value: row['contact_phone']?.toString() ?? '-'),
                ],
                _infoCard(icon: Icons.history, title: 'ประวัติความเป็นมา', value: row['background_history']?.toString() ?? '-'),
                _infoCard(icon: Icons.menu_book_outlined, title: 'ประวัติของแหล่งเรียนรู้', value: row['resource_history']?.toString() ?? '-'),
                if (widget.type != DataType.subdistrictLearningCenter)
                  _infoCard(icon: Icons.auto_stories_outlined, title: 'กระบวนการเรียนรู้', value: row['learning_process']?.toString() ?? '-'),
                _infoCard(icon: Icons.emoji_events_outlined, title: 'รางวัลที่ได้รับ', value: row['awards']?.toString() ?? '-'),
                ...[
                  const SizedBox(height: 10),
                  _sectionTitle('ข้อมูลอาคารสถานที่', Icons.apartment_outlined),
                  _infoCard(icon: Icons.business_outlined, title: 'ลักษณะการใช้อาคาร', value: row['building_use']?.toString() ?? '-'),
                  _infoCard(icon: Icons.fact_check_outlined, title: 'กรณีได้รับอนุญาต', value: row['permission_case']?.toString() ?? '-'),
                  _infoCard(icon: Icons.domain_outlined, title: 'ความเป็นเอกเทศ', value: row['independence']?.toString() ?? '-'),
                  const SizedBox(height: 10),
                  _sectionTitle('เวลาเปิดทำการ', Icons.access_time_outlined),
                  _infoCard(icon: Icons.work_history_outlined, title: 'วันจันทร์-ศุกร์', value: row['weekday_hours']?.toString() ?? '-'),
                  _infoCard(icon: Icons.weekend_outlined, title: 'วันเสาร์-อาทิตย์', value: row['weekend_hours']?.toString() ?? '-'),
                  _infoCard(icon: Icons.calendar_month_outlined, title: 'วันเปิดทำการ', value: row['opening_days']?.toString() ?? '-'),
                  const SizedBox(height: 10),
                  _sectionTitle('สิ่งอำนวยความสะดวก', Icons.construction_outlined),
                  _infoCard(icon: Icons.wifi_outlined, title: 'อินเตอร์เน็ต', value: row['internet']?.toString() ?? '-'),
                  _infoCard(icon: Icons.water_drop_outlined, title: 'น้ำประปา', value: row['water_supply']?.toString() ?? '-'),
                  _infoCard(icon: Icons.bolt_outlined, title: 'ไฟฟ้า', value: row['electricity']?.toString() ?? '-'),
                  _infoCard(icon: Icons.wc_outlined, title: 'สุขา', value: row['toilet']?.toString() ?? '-'),
                  const SizedBox(height: 10),
                  _sectionTitle('ครุภัณฑ์', Icons.inventory_2_outlined),
                  _infoCard(icon: Icons.laptop_outlined, title: 'Notebook', value: row['notebook']?.toString() ?? '-'),
                  _infoCard(icon: Icons.desktop_windows_outlined, title: 'Desktop', value: row['desktop']?.toString() ?? '-'),
                  _infoCard(icon: Icons.tv_outlined, title: 'TV', value: row['tv']?.toString() ?? '-'),
                  _infoCard(icon: Icons.tablet_outlined, title: 'Tablet', value: row['tablet']?.toString() ?? '-'),
                  _infoCard(icon: Icons.videocam_outlined, title: 'Projector', value: row['projector']?.toString() ?? '-'),
                  _infoCard(icon: Icons.table_restaurant_outlined, title: 'โต๊ะ', value: row['tables']?.toString() ?? '-'),
                  _infoCard(icon: Icons.chair_outlined, title: 'เก้าอี้', value: row['chairs']?.toString() ?? '-'),
                ],

                const SizedBox(height: 14),
                _sectionTitle('ตำแหน่งที่ตั้ง', Icons.location_on_outlined),
                if (hasGps)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: scheme.outlineVariant)),
                    child: Column(children: [
                      Row(children: [
                        Expanded(child: _infoCard(icon: Icons.north, title: 'Latitude', value: lat!.toStringAsFixed(6))),
                        const SizedBox(width: 10),
                        Expanded(child: _infoCard(icon: Icons.east, title: 'Longitude', value: lng!.toStringAsFixed(6))),
                      ]),
                      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _openMaps, icon: const Icon(Icons.map_outlined), label: const Text('เปิดตำแหน่งใน Google Maps'))),
                    ]),
                  )
                else
                  _infoCard(icon: Icons.location_off_outlined, title: 'พิกัด GPS', value: 'ยังไม่ได้บันทึกพิกัดสถานที่'),
                const SizedBox(height: 24),
                _sectionTitle('สถานะและข้อมูลระบบ', Icons.verified_outlined),
                _infoCard(icon: Icons.verified_outlined, title: 'สถานะข้อมูล', value: _statusText(status)),
                _infoCard(icon: Icons.fingerprint, title: 'รหัสข้อมูล', value: row['id']?.toString() ?? '-'),
              ]),
            ),
          ),
        ),
      ),
    );
  }

}
