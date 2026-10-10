import 'dart:typed_data';
import 'dart:html' as html;
import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'data_list_page.dart';

class DashboardPage extends StatefulWidget {
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  const DashboardPage({super.key, this.showMenuButton = false, this.onMenuPressed});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final client = Supabase.instance.client;
  final ScrollController _tableHorizontalController = ScrollController();

  static const subdistricts = [
    'เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง',
    'ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี',
  ];

  final types = const [
    DataType.learningResource,
    DataType.localWisdom,
    DataType.localScholar,
    DataType.communityBookHouse,
    DataType.subdistrictLearningCenter,
    DataType.touristAttraction,
    DataType.traditionalFood,
    DataType.villageBookCorner,
  ];

  Map<DataType, List<Map<String, dynamic>>> rowsByType = {};
  bool loading = true;
  String? error;

  @override
  void dispose() {
    _tableHorizontalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) setState(() { loading = true; error = null; });
    try {
      final result = <DataType, List<Map<String, dynamic>>>{};
      for (final type in types) {
        final data = await client
            .from(type.table)
            .select('id,subdistrict,status,created_at')
            .order('created_at', ascending: false);
        result[type] = List<Map<String, dynamic>>.from(data);
      }
      if (!mounted) return;
      setState(() { rowsByType = result; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  int countFor(DataType type, String subdistrict) {
    return rowsByType[type]
            ?.where((r) => (r['subdistrict']?.toString().trim() ?? '') == subdistrict)
            .length ?? 0;
  }

  int totalFor(DataType type) => rowsByType[type]?.length ?? 0;

  int totalAll() => types.fold(0, (sum, t) => sum + totalFor(t));

  int categoriesStarted(String subdistrict) =>
      types.where((t) => countFor(t, subdistrict) > 0).length;

  double progressFor(String subdistrict) => categoriesStarted(subdistrict) / types.length;

  int activeSubdistricts() => subdistricts.where((s) => categoriesStarted(s) > 0).length;

  double overallProgress() {
    final possible = subdistricts.length * types.length;
    if (possible == 0) return 0;
    final done = subdistricts.fold(0, (sum, s) => sum + categoriesStarted(s));
    return done / possible;
  }

  String pct(double v) => '${(v * 100).round()}%';

  Future<void> _downloadWord() async {
    // Build the report from concrete values first. This avoids accidentally
    // serialising a Dart closure into the Word/HTML document on Flutter Web.
    final total = totalAll();
    final active = activeSubdistricts();
    final progress = pct(overallProgress());
    final htmlText = _reportHtml(
      printScript: false,
      totalValue: total,
      activeValue: active,
      progressValue: progress,
    );
    // UTF-8 BOM helps Microsoft Word recognise Thai text reliably.
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(htmlText)]);
    final blob = html.Blob([bytes], 'application/msword');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = 'รายงานสรุปความก้าวหน้าห้องสมุดประชาชนอำเภอหนองจิก.doc'
      ..style.display = 'none';
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    Future.delayed(const Duration(seconds: 5), () => html.Url.revokeObjectUrl(url));
    _message('ดาวน์โหลด Word เรียบร้อยแล้ว');
  }

  void _printReport() {
    final htmlText = _reportHtml(printScript: true);
    final blob = html.Blob([htmlText], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    Future.delayed(const Duration(seconds: 15), () => html.Url.revokeObjectUrl(url));
  }

  Future<void> _downloadPdf() async {
    // On Flutter Web, use the browser's native print engine for PDF output.
    // This preserves Thai glyphs reliably and lets the user choose “Save as PDF”.
    final htmlText = _reportHtml(printScript: true);
    final blob = html.Blob([htmlText], 'text/html;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final reportWindow = html.window.open(url, '_blank');
    if (reportWindow == null) {
      html.Url.revokeObjectUrl(url);
      _message('เบราว์เซอร์บล็อกหน้าต่างรายงาน กรุณาอนุญาต Pop-up แล้วลองอีกครั้ง', error: true);
      return;
    }
    Future.delayed(const Duration(seconds: 15), () => html.Url.revokeObjectUrl(url));
    _message('เปิดหน้ารายงานแล้ว ให้เลือก “Save as PDF” ในหน้าต่างพิมพ์');
  }

  pw.Widget _pdfStat(String label, String value, pw.Font font, pw.Font bold) => pw.Expanded(
    child: pw.Container(
      margin: const pw.EdgeInsets.only(right: 8),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(color: PdfColors.teal50, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label, style: pw.TextStyle(font: font, fontSize: 8)),
        pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 14, color: PdfColors.teal800)),
      ]),
    ),
  );

  String _reportHtml({bool printScript = false, int? totalValue, int? activeValue, String? progressValue}) {
    String esc(String s) => s
        .replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;').replaceAll("'", '&#39;');
    final reportTotal = totalValue ?? totalAll();
    final reportActive = activeValue ?? activeSubdistricts();
    final reportProgress = progressValue ?? pct(overallProgress());
    final rows = subdistricts.map((s) {
      final cells = types.map((t) {
        final n = countFor(t, s);
        return '<td class="num">${n == 0 ? '—' : n}</td>';
      }).join();
      return '<tr><td><strong>${esc(s)}</strong></td>$cells<td class="progress">${esc(pct(progressFor(s)))}</td></tr>';
    }).join();
    final totals = types.map((t) => '<td class="num total">${totalFor(t)}</td>').join();
    final menuRows = types.map((t) => '<tr><td>${esc(t.title)}</td><td class="num">${totalFor(t)}</td></tr>').join();
    final headers = types.map((t) => '<th>${esc(t.title)}</th>').join();
    return '''<!doctype html><html lang="th"><head><meta charset="utf-8"><title>รายงานสรุปความก้าวหน้า</title>
<style>
@page{size:A4 landscape;margin:12mm}body{font-family:"Noto Sans Thai","Leelawadee UI",Tahoma,Arial,sans-serif;color:#173b35;margin:0;font-size:11px}h1{color:#087f70;font-size:20px;margin:0}h2{font-size:15px;color:#087f70;margin:20px 0 8px}.sub{color:#687a75;margin:4px 0 16px}.stats{display:flex;gap:10px;margin-bottom:18px}.stat{flex:1;padding:12px;border-radius:10px;background:#e9f7f4;border:1px solid #c8e4df}.stat b{display:block;font-size:18px;color:#087f70;margin-top:3px}table{width:100%;border-collapse:collapse}th{background:#d9f0ec;color:#075c52}th,td{border:1px solid #cbd9d5;padding:6px 5px}th{font-size:9px}td.num{text-align:center}td.progress{font-weight:800;text-align:center;color:#087f70}.total{font-weight:800}.bar{height:10px;background:#e2ece9;border-radius:8px;overflow:hidden}.fill{height:100%;background:#00897b}.footer{margin-top:18px;color:#778580;font-size:9px}@media print{.no-print{display:none}.pdf-hint{display:none}}
@media screen{.pdf-hint{display:block;margin:0 0 14px;padding:10px 14px;border-radius:10px;background:#fff7d6;border:1px solid #f0d878;color:#6a5510;font-weight:700}}
.logo{width:64px;height:64px;object-fit:contain;border-radius:14px;border:1px solid #c8e4df;background:#fff}.head{display:flex;align-items:center;gap:14px;margin-bottom:8px}.head-text{flex:1}.kicker{font-size:11px;color:#5f756f;margin-top:2px}.report-date{font-size:10px;color:#778580}.table-wrap{overflow:hidden}
</style></head><body><div class="head"><div class="head-text"><h1>งานการศึกษาตลอดชีวิต | ห้องสมุดประชาชนอำเภอหนองจิก</h1><div class="kicker">ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก • สำนักงานส่งเสริมการเรียนรู้ประจำจังหวัดปัตตานี</div></div></div><div class="pdf-hint">สำหรับ PDF: ในหน้าต่างพิมพ์ เลือกปลายทาง “Save as PDF” แล้วกดบันทึก</div><div class="sub">ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก • สำนักงานส่งเสริมการเรียนรู้ประจำจังหวัดปัตตานี<br>รายงาน ณ วันที่ ${DateTime.now().toLocal().day}/${DateTime.now().toLocal().month}/${DateTime.now().toLocal().year + 543}</div>
<div class="stats"><div class="stat">ข้อมูลทั้งหมด<b>${reportTotal} รายการ</b></div><div class="stat">ตำบลที่เริ่มส่งข้อมูล<b>${reportActive} / ${subdistricts.length}</b></div><div class="stat">ความก้าวหน้ารวม<b>${esc(reportProgress)}</b></div></div>
<h2>ความก้าวหน้ารายตำบล</h2><table><thead><tr><th>ตำบล</th>$headers<th>ความก้าวหน้า</th></tr></thead><tbody>$rows<tr><td><strong>รวม</strong></td>$totals<td class="progress">${esc(reportProgress)}</td></tr></tbody></table>
<h2>จำนวนข้อมูลแยกตามเมนู</h2><table><thead><tr><th>เมนู</th><th>จำนวนรายการ</th></tr></thead><tbody>$menuRows</tbody></table><div class="footer">รายงานนี้สร้างจากข้อมูลในระบบคลังข้อมูล ห้องสมุดประชาชนอำเภอหนองจิก</div>${printScript ? '<script>window.onload=function(){setTimeout(function(){window.print()},700)};</script>' : ''}</body></html>''';
  }

  void _message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? Colors.red : null));
  }

  Color _menuColor(DataType type) {
    switch (type) {
      case DataType.learningResource: return const Color(0xFF18A77A);
      case DataType.localWisdom: return const Color(0xFF2D8CFF);
      case DataType.localScholar: return const Color(0xFF7B5CFF);
      case DataType.communityBookHouse: return const Color(0xFFEF6AA8);
      case DataType.subdistrictLearningCenter: return const Color(0xFF21B7D8);
      case DataType.touristAttraction: return const Color(0xFFFF5B86);
      case DataType.traditionalFood: return const Color(0xFFFFB629);
      case DataType.villageBookCorner: return const Color(0xFF8D5CF6);
    }
  }

  IconData _menuIcon(DataType type) {
    switch (type) {
      case DataType.learningResource: return Icons.menu_book_rounded;
      case DataType.localWisdom: return Icons.eco_rounded;
      case DataType.localScholar: return Icons.person_rounded;
      case DataType.communityBookHouse: return Icons.home_work_rounded;
      case DataType.subdistrictLearningCenter: return Icons.apartment_rounded;
      case DataType.touristAttraction: return Icons.location_on_rounded;
      case DataType.traditionalFood: return Icons.restaurant_rounded;
      case DataType.villageBookCorner: return Icons.bookmark_rounded;
    }
  }

  Widget _glassCard({required Widget child, EdgeInsets padding = const EdgeInsets.all(20), double radius = 24}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: .9)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF174E67).withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color, {String? caption}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 700;
    final cardWidth = screenWidth < 1100
        ? (screenWidth - 60) / 2
        : (screenWidth - 390) / 4;
    return SizedBox(
      width: cardWidth,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white.withValues(alpha: .98), color.withValues(alpha: .08)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: .95)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: .10), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 11 : 17),
          child: Row(children: [
            Container(width: compact ? 38 : 54, height: compact ? 38 : 54, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: .72)]), borderRadius: BorderRadius.circular(17), boxShadow: [BoxShadow(color: color.withValues(alpha: .25), blurRadius: 10, offset: const Offset(0, 5))]), child: Icon(icon, color: Colors.white, size: 29)),
            SizedBox(width: compact ? 8 : 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 13, fontWeight: FontWeight.w700, color: Color(0xFF5D6B78))),
              const SizedBox(height: 3),
              Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 20 : 25, fontWeight: FontWeight.w900, color: color)),
              if (caption != null) Text(caption, style: const TextStyle(fontSize: 11, color: Color(0xFF8A969F))),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _progressBar(double value, {Color? color, double height = 10}) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: LinearProgressIndicator(value: value.clamp(0, 1), minHeight: height, backgroundColor: const Color(0xFFE8EFF2), color: color ?? const Color(0xFF08A58D)),
  );

  Widget _sectionTitle(String title, String subtitle, IconData icon, Color color) {
    return Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withValues(alpha: .72)]), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: Colors.white, size: 22)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Color(0xFF17324A))), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF788794)))])),
    ]);
  }

  Widget _barChart() {
    final max = types.map(totalFor).fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 245,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: types.map((t) {
        final total = totalFor(t);
        final ratio = max == 0 ? 0.0 : total / max;
        final color = _menuColor(t);
        return Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text('$total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 5),
          Container(height: 145 * (ratio == 0 ? .025 : ratio), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [color, color.withValues(alpha: .48)]), borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), boxShadow: [BoxShadow(color: color.withValues(alpha: .14), blurRadius: 9, offset: const Offset(0, 4))])),
          const SizedBox(height: 8),
          Icon(_menuIcon(t), size: 19, color: color),
          const SizedBox(height: 4),
          Text(t.title, maxLines: 2, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF52606B))),
        ])));
      }).toList()),
    );
  }

  Widget _donutChart() {
    final total = totalAll();
    final compact = MediaQuery.sizeOf(context).width < 700;
    final chart = SizedBox(
      width: compact ? 150 : 170,
      height: compact ? 150 : 170,
      child: CustomPaint(
        painter: _DonutPainter(
          types: types,
          values: types.map(totalFor).toList(),
          colors: types.map(_menuColor).toList(),
        ),
      ),
    );

    Widget legendItem(int i) {
      final n = totalFor(types[i]);
      final share = total == 0 ? 0 : (n / total * 100).round();
      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Row(
          children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: _menuColor(types[i]), shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(types[i].title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
            const SizedBox(width: 5),
            Text('$n ($share%)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF687681))),
          ],
        ),
      );
    }

    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: chart),
          const SizedBox(height: 14),
          ...List.generate(types.length, legendItem),
        ],
      );
    }

    return SizedBox(
      height: 245,
      child: Row(
        children: [
          chart,
          const SizedBox(width: 18),
          Expanded(child: Column(children: List.generate(types.length, legendItem))),
        ],
      ),
    );
  }

  Widget _headerAction({required IconData icon, required String label, required Color color, required VoidCallback? onPressed}) {
    final enabled = onPressed != null;
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      child: Material(
        color: enabled ? color : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        elevation: enabled ? 3 : 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            constraints: BoxConstraints(minWidth: compact ? 38 : 54, minHeight: 38),
            padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 19),
                if (!compact) ...[
                  const SizedBox(width: 5),
                  Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F7F8),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Dashboard • ภาพรวมความก้าวหน้า',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF17324A), fontSize: MediaQuery.sizeOf(context).width < 380 ? 11 : (MediaQuery.sizeOf(context).width < 500 ? 13 : 20)),
        ),
        actions: [
          if (widget.showMenuButton)
            IconButton(
              tooltip: 'เปิดเมนู',
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF17324A)),
              onPressed: widget.onMenuPressed,
            ),
          _headerAction(
            icon: Icons.refresh_rounded,
            label: 'รีเฟรช',
            color: const Color(0xFF16A085),
            onPressed: loading ? null : load,
          ),
          _headerAction(
            icon: Icons.print_rounded,
            label: 'พิมพ์',
            color: const Color(0xFF2878D8),
            onPressed: loading ? null : _printReport,
          ),
          _headerAction(
            icon: Icons.picture_as_pdf_rounded,
            label: 'PDF',
            color: const Color(0xFFE94B5F),
            onPressed: loading ? null : _downloadPdf,
          ),
          _headerAction(
            icon: Icons.description_rounded,
            label: 'Word',
            color: const Color(0xFF2B65C8),
            onPressed: loading ? null : _downloadWord,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF9F8), Color(0xFFF7F3FF), Color(0xFFFDF7EA)],
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 56, color: Colors.red),
                          const SizedBox(height: 12),
                          const Text('โหลด Dashboard ไม่สำเร็จ'),
                          const SizedBox(height: 8),
                          SelectableText(error!),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: load,
                            icon: const Icon(Icons.refresh),
                            label: const Text('ลองใหม่'),
                          ),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 700;
                      final medium = constraints.maxWidth < 1100;
                      final horizontalPadding = narrow ? 12.0 : (medium ? 16.0 : 20.0);
                      return RefreshIndicator(
                    onRefresh: load,
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 6, horizontalPadding, 32),
                      children: [
                        _glassCard(
                          padding: EdgeInsets.zero,
                          radius: 28,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(narrow ? 14 : 24, narrow ? 14 : 20, narrow ? 14 : 24, narrow ? 14 : 20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF075E74), Color(0xFF008E83), Color(0xFF3B63C8)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: narrow
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                                          child: ClipRRect(borderRadius: BorderRadius.circular(11), child: Image.asset('assets/logo_skr.jpg', fit: BoxFit.contain)),
                                        ),
                                        const SizedBox(width: 10),
                                        const Expanded(child: Text('ห้องสมุดประชาชนอำเภอหนองจิก', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900))),
                                      ]),
                                      const SizedBox(height: 8),
                                      const Text('งานการศึกษาตลอดชีวิต • ระบบคลังข้อมูลแหล่งเรียนรู้', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 5),
                                      const Text('เชื่อมโยงแหล่งเรียนรู้ สู่การเรียนรู้ตลอดชีวิต', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                    ],
                                  )
                                : Row(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.asset('assets/logo_skr.jpg', fit: BoxFit.contain),
                                  ),
                                ),
                                const SizedBox(width: 18),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('ห้องสมุดประชาชนอำเภอหนองจิก', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                                      SizedBox(height: 3),
                                      Text('งานการศึกษาตลอดชีวิต • ระบบคลังข้อมูลแหล่งเรียนรู้', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                                      SizedBox(height: 7),
                                      Text('เชื่อมโยงแหล่งเรียนรู้ สู่การเรียนรู้ตลอดชีวิต', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .14),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 7),
                                      Text('SMART LIBRARY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _statCard('ตำบลทั้งหมด', '${subdistricts.length}', Icons.location_city_rounded, const Color(0xFF6A4CFF), caption: 'พื้นที่รับผิดชอบ'),
                            _statCard('ข้อมูลทั้งหมด', '${totalAll()}', Icons.dataset_rounded, const Color(0xFF008E83), caption: 'รายการในระบบ'),
                            _statCard('ตำบลที่เริ่มส่งข้อมูล', '${activeSubdistricts()}', Icons.groups_rounded, const Color(0xFF1689E5), caption: 'จาก ${subdistricts.length} ตำบล'),
                            _statCard('ความก้าวหน้า', pct(overallProgress()), Icons.insights_rounded, const Color(0xFFF06A8D), caption: 'ภาพรวม 8 เมนู'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (narrow) ...[
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('จำนวนข้อมูลแยกตามเมนู', 'เปรียบเทียบจำนวนรายการของทั้ง 8 เมนู', Icons.bar_chart_rounded, const Color(0xFF1689E5)),
                                const SizedBox(height: 10),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(width: 600, height: 220, child: _barChart()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _glassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('สัดส่วนข้อมูล', 'ภาพรวมการกระจายข้อมูลแต่ละเมนู', Icons.donut_large_rounded, const Color(0xFF7B5CFF)),
                                const SizedBox(height: 10),
                                _donutChart(),
                              ],
                            ),
                          ),
                        ] else Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _glassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionTitle('จำนวนข้อมูลแยกตามเมนู', 'เปรียบเทียบจำนวนรายการของทั้ง 8 เมนู', Icons.bar_chart_rounded, const Color(0xFF1689E5)),
                                    const SizedBox(height: 10),
                                    _barChart(),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _glassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _sectionTitle('สัดส่วนข้อมูล', 'ภาพรวมการกระจายข้อมูลแต่ละเมนู', Icons.donut_large_rounded, const Color(0xFF7B5CFF)),
                                    const SizedBox(height: 10),
                                    _donutChart(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('ความก้าวหน้ารวมของทั้งระบบ', '${pct(overallProgress())} • 8 เมนูหลัก × ${subdistricts.length} ตำบล', Icons.speed_rounded, const Color(0xFF08A58D)),
                              const SizedBox(height: 15),
                              Stack(
                                children: [
                                  Container(
                                    height: 18,
                                    decoration: BoxDecoration(color: const Color(0xFFE6EEF0), borderRadius: BorderRadius.circular(20)),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: overallProgress().clamp(0, 1),
                                    child: Container(
                                      height: 18,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(colors: [Color(0xFF08A58D), Color(0xFF3B63C8), Color(0xFF7B5CFF)]),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(pct(overallProgress()), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF087F70))),
                                  const Spacer(),
                                  Text('${activeSubdistricts()} จาก ${subdistricts.length} ตำบลเริ่มส่งข้อมูล', style: const TextStyle(fontSize: 12, color: Color(0xFF71808B))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _glassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('ความก้าวหน้ารายตำบล', 'ดูสถานะการเพิ่มข้อมูลของแต่ละพื้นที่', Icons.location_on_rounded, const Color(0xFFFF7A59)),
                              const SizedBox(height: 18),
                              ...subdistricts.map(
                                (s) => Padding(
                                  padding: const EdgeInsets.only(bottom: 13),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 115, child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF334D5C)))),
                                      Expanded(child: _progressBar(progressFor(s), color: _menuColor(types[categoriesStarted(s) == 0 ? 0 : categoriesStarted(s) - 1]), height: 11)),
                                      const SizedBox(width: 12),
                                      SizedBox(width: 48, child: Text('${categoriesStarted(s)}/${types.length}', textAlign: TextAlign.right, style: const TextStyle(color: Color(0xFF71808B), fontWeight: FontWeight.w700))),
                                      SizedBox(width: 54, child: Text(pct(progressFor(s)), textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF087F70)))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _glassCard(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: _sectionTitle('ตำบลไหนเพิ่มข้อมูลอะไรแล้วบ้าง', narrow ? 'สรุปข้อมูลแยกตามตำบล' : 'เลื่อนซ้าย–ขวาเพื่อดูเมนูทั้งหมด', Icons.table_chart_rounded, const Color(0xFF087F70)),
                              ),
                              const SizedBox(height: 8),
                              if (narrow) ...[
                                // Mobile-friendly alternative to the wide desktop matrix.
                                // Each subdistrict becomes a card so values are never clipped
                                // and users do not need horizontal scrolling to read them.
                                ...subdistricts.map((s) {
                                  final started = categoriesStarted(s);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: .86),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: const Color(0xFFDCEBE8)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(s, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF17324A), fontSize: 14)),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                              decoration: BoxDecoration(color: const Color(0xFFE1F2EF), borderRadius: BorderRadius.circular(20)),
                                              child: Text('$started/${types.length} เมนู', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF087F70))),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        _progressBar(progressFor(s), color: const Color(0xFF08A58D), height: 7),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: types.map((t) {
                                            final n = countFor(t, s);
                                            final color = _menuColor(t);
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                              decoration: BoxDecoration(
                                                color: n > 0 ? color.withValues(alpha: .10) : const Color(0xFFF2F5F6),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(color: n > 0 ? color.withValues(alpha: .25) : const Color(0xFFE5EAEC)),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(_menuIcon(t), size: 13, color: n > 0 ? color : const Color(0xFF9AA5AB)),
                                                  const SizedBox(width: 4),
                                                  Text('${t.title} ${n == 0 ? '—' : n}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: n > 0 ? color : const Color(0xFF7C898F))),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ] else
                              Scrollbar(
                                controller: _tableHorizontalController,
                                thumbVisibility: true,
                                trackVisibility: true,
                                child: SingleChildScrollView(
                                  controller: _tableHorizontalController,
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: DataTable(
                                    columnSpacing: 24,
                                    headingRowHeight: 54,
                                    dataRowMinHeight: 48,
                                    dataRowMaxHeight: 54,
                                    headingRowColor: const WidgetStatePropertyAll(Color(0xFFE1F2EF)),
                                    columns: [
                                      const DataColumn(label: Text('ตำบล', style: TextStyle(fontWeight: FontWeight.w900))),
                                      ...types.map(
                                        (t) => DataColumn(
                                          label: SizedBox(
                                            width: 125,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(_menuIcon(t), color: _menuColor(t), size: 18),
                                                const SizedBox(width: 5),
                                                Flexible(child: Text(t.title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: _menuColor(t)))),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const DataColumn(label: Text('ก้าวหน้า', style: TextStyle(fontWeight: FontWeight.w900))),
                                    ],
                                    rows: subdistricts.map(
                                      (s) => DataRow(
                                        cells: [
                                          DataCell(Text(s, style: const TextStyle(fontWeight: FontWeight.w800))),
                                          ...types.map((t) {
                                            final n = countFor(t, s);
                                            return DataCell(
                                              Center(
                                                child: n == 0
                                                    ? const Icon(Icons.remove, color: Colors.grey, size: 17)
                                                    : Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        decoration: BoxDecoration(
                                                          color: _menuColor(t).withValues(alpha: .10),
                                                          borderRadius: BorderRadius.circular(18),
                                                          border: Border.all(color: _menuColor(t).withValues(alpha: .20)),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            Icon(Icons.check_circle_rounded, size: 15, color: _menuColor(t)),
                                                            const SizedBox(width: 4),
                                                            Text('$n', style: TextStyle(fontWeight: FontWeight.w900, color: _menuColor(t))),
                                                          ],
                                                        ),
                                                      ),
                                              ),
                                            );
                                          }),
                                          DataCell(Text(pct(progressFor(s)), style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF00796B)))),
                                        ],
                                      ),
                                    ).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                    },
                  ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DataType> types;
  final List<int> values;
  final List<Color> colors;
  _DonutPainter({required this.types, required this.values, required this.colors});
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<int>(0, (a, b) => a + b);
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 26..strokeCap = StrokeCap.butt;
    if (total == 0) { paint.color = const Color(0xFFE2EAED); canvas.drawCircle(center, radius, paint); }
    else { var start = -1.5708; for (var i = 0; i < values.length; i++) { final sweep = values[i] / total * 6.283185307; paint.color = colors[i]; canvas.drawArc(rect, start, sweep, false, paint); start += sweep; } }
    final inner = Paint()..color = Colors.white..style = PaintingStyle.fill; canvas.drawCircle(center, radius - 14, inner);
    final tp = TextPainter(text: TextSpan(text: '$total\nรายการ', style: const TextStyle(fontSize: 15, height: 1.15, fontWeight: FontWeight.w900, color: Color(0xFF17324A))), textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }
  @override bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.values != values;
}
