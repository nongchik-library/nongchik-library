import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class PublicExportService {
  static const _url = 'https://ddldegnsupfeqfzbjjcr.supabase.co';
  static const _key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY', defaultValue: '');
  static const _excluded = {
    'id','created_by','updated_at','created_at','is_public','rejection_reason',
    'photo_drive_ids','photo_paths','certificate_paths','certificate_drive_ids',
    'person_photo_drive_id','password','access_token','refresh_token'
  };
  static const _labels = <String,String>{
    'name':'ชื่อข้อมูล','title':'ชื่อกิจกรรม','project_title':'ชื่อโครงการ','activity_name':'ชื่อกิจกรรม',
    'description':'รายละเอียด','subdistrict':'ตำบล','address':'ที่อยู่','contact':'ช่องทางติดต่อ',
    'extra_info':'ข้อมูลเพิ่มเติม','latitude':'ละติจูด','longitude':'ลองจิจูด','status':'สถานะ',
    'first_name':'ชื่อ','last_name':'นามสกุล','position':'ตำแหน่ง','contact_phone':'หมายเลขโทรศัพท์',
    'contact_line':'LINE','contact_facebook':'Facebook','contact_tiktok':'TikTok','gender':'เพศ',
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
    'created_at':'วันที่บันทึกข้อมูล','updated_at':'วันที่ปรับปรุงข้อมูล'
  };
  static String _label(String key) {
    if (_labels.containsKey(key)) return _labels[key]!;
    // Public documents must keep headings in Thai; unknown database keys use a neutral Thai label.
    return 'รายละเอียดเพิ่มเติม';
  }
  static String _display(String key, dynamic value) {
    if (value == null) return '';
    if (value is List) return value.map((e)=>e.toString()).join('、');
    final s=value.toString();
    if (key=='status') return {'approved':'อนุมัติแล้ว','pending':'รอตรวจสอบ','rejected':'ไม่อนุมัติ'}[s] ?? s;
    if (key=='gender') return {'male':'ชาย','female':'หญิง'}[s] ?? s;
    return s;
  }
  static String _xml(String v) => v.replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;').replaceAll("'",'&#39;');
  static String _safe(String v) => v.replaceAll(RegExp(r'[\\/:*?"<>|]'),'_').replaceAll(RegExp(r'\s+'),'_');
  static List<MapEntry<String,String>> _fields(Map<String,dynamic> row) => row.entries
      .where((e)=>!_excluded.contains(e.key)&&e.value!=null&&e.value.toString().trim().isNotEmpty)
      .map((e)=>MapEntry(_label(e.key),_display(e.key,e.value))).toList();
  static List<String> _ids(Map<String,dynamic> row) {
    final out=<String>[];
    for(final key in ['photo_drive_ids','certificate_drive_ids']) {
      final v=row[key];
      if(v is List) out.addAll(v.map((e)=>e.toString()).where((e)=>e.isNotEmpty));
      if(v is String && v.trim().isNotEmpty) {
        final raw=v.trim();
        if(raw.startsWith('[') && raw.endsWith(']')) {
          out.addAll(raw.substring(1,raw.length-1).split(',').map((e)=>e.trim().replaceAll('"','').replaceAll("'",'')).where((e)=>e.isNotEmpty));
        } else { out.add(raw); }
      }
    }
    final person=row['person_photo_drive_id']?.toString().trim() ?? '';
    if(person.isNotEmpty) out.add(person);
    return out.toSet().toList();
  }
  static Future<List<Uint8List>> _photos(Map<String,dynamic> row) async {
    final out=<Uint8List>[];
    for(final id in _ids(row)) { try {
      final uri=Uri.parse('$_url/functions/v1/drive-image').replace(queryParameters:{'file_id':id});
      final r=await http.get(uri,headers:{'apikey':_key,'Authorization':'Bearer $_key'});
      if(r.statusCode==200&&r.bodyBytes.isNotEmpty) out.add(r.bodyBytes);
    } catch(_){} }
    return out;
  }
  static void _download(Uint8List bytes,String filename,String mime) {
    final blob=html.Blob([bytes],mime); final url=html.Url.createObjectUrlFromBlob(blob);
    final a=html.AnchorElement(href:url)..download=filename..style.display='none';
    html.document.body?.children.add(a); a.click(); a.remove(); html.Url.revokeObjectUrl(url);
  }
  static Future<void> exportPdf(String menu,String title,Map<String,dynamic> row) async {
    final regular=pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf'));
    final bold=pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSansThai-Bold.ttf'));
    // NotoSansThai files are Thai-subset fonts; use DejaVu as fallback for Latin, digits and symbols.
    final latin=pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans.ttf'));
    final latinBold=pw.Font.ttf(await rootBundle.load('assets/fonts/DejaVuSans-Bold.ttf'));
    final fields=_fields(row); final photos=await _photos(row); final doc=pw.Document();
    final teal=PdfColor.fromInt(0xFF087F78);
    final trs=<pw.TableRow>[
      pw.TableRow(repeat:true,decoration:pw.BoxDecoration(color:teal),children:[
        pw.Padding(padding:const pw.EdgeInsets.all(8),child:pw.Text('หัวข้อ',style:pw.TextStyle(font:bold,color:PdfColors.white))),
        pw.Padding(padding:const pw.EdgeInsets.all(8),child:pw.Text('รายละเอียด',style:pw.TextStyle(font:bold,color:PdfColors.white))),
      ]),
      ...fields.asMap().entries.map((e)=>pw.TableRow(decoration:pw.BoxDecoration(color:e.key.isEven?PdfColors.grey100:PdfColors.white),children:[
        pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(e.value.key,style:pw.TextStyle(font:bold,fontSize:10))),
        pw.Padding(padding:const pw.EdgeInsets.all(7),child:pw.Text(e.value.value,style:pw.TextStyle(font:regular,fontSize:10))),
      ])),
    ];
    doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,theme:pw.ThemeData.withFont(base:regular,bold:bold,fontFallback:[latin,latinBold]),margin:const pw.EdgeInsets.all(38),
      header:(_)=>pw.Container(padding:const pw.EdgeInsets.only(bottom:8),decoration:pw.BoxDecoration(border:pw.Border(bottom:pw.BorderSide(color:teal,width:1.2))),child:pw.Text('ศูนย์ส่งเสริมการเรียนรู้ระดับอำเภอหนองจิก',style:pw.TextStyle(font:bold,color:teal,fontSize:10))),
      footer:(ctx)=>pw.Align(alignment:pw.Alignment.center,child:pw.Text('หน้า ${ctx.pageNumber} / ${ctx.pagesCount}',style:pw.TextStyle(font:regular,fontSize:9,color:PdfColors.grey700))),
      build:(_)=>[
        pw.SizedBox(height:14),
        pw.Container(width:double.infinity,padding:const pw.EdgeInsets.all(14),decoration:pw.BoxDecoration(color:teal,borderRadius:pw.BorderRadius.circular(7)),child:pw.Column(children:[
          pw.Text(menu,style:pw.TextStyle(font:bold,color:PdfColors.white,fontSize:13)),pw.SizedBox(height:5),pw.Text(title,style:pw.TextStyle(font:bold,color:PdfColors.white,fontSize:17),textAlign:pw.TextAlign.center),
        ])),
        pw.SizedBox(height:14),pw.Table(border:pw.TableBorder.all(color:PdfColors.grey300,width:.5),columnWidths:{0:const pw.FlexColumnWidth(1),1:const pw.FlexColumnWidth(2.3)},children:trs),
        if(photos.isNotEmpty)...[pw.SizedBox(height:16),pw.Text('ภาพประกอบ (${photos.length} ภาพ)',style:pw.TextStyle(font:bold,fontSize:13,color:teal)),pw.SizedBox(height:8),
          pw.Wrap(spacing:8,runSpacing:8,children:photos.map((b)=>pw.Container(width:245,height:145,padding:const pw.EdgeInsets.all(4),decoration:pw.BoxDecoration(border:pw.Border.all(color:PdfColors.grey300)),child:pw.Image(pw.MemoryImage(b),fit:pw.BoxFit.contain))).toList())]
      ]));
    _download(Uint8List.fromList(await doc.save()),'${_safe(title)}.pdf','application/pdf');
  }
  static Future<void> exportWord(String menu,String title,Map<String,dynamic> row) async {
    final fields=_fields(row); final photos=await _photos(row);
    String imgMime(Uint8List b)=>b.length>3&&b[0]==0x89&&b[1]==0x50?'image/png':'image/jpeg';
    final rows=fields.map((f)=>'<tr><th>${_xml(f.key)}</th><td>${_xml(f.value).replaceAll('\n','<br/>')}</td></tr>').join();
    final pics=<String>[];
    for(var i=0;i<photos.length;i+=2) {
      String cell(Uint8List b)=>'<td style="width:50%;padding:8px;text-align:center;vertical-align:middle"><img width="300" height="190" style="width:300px;height:190px;object-fit:contain;border:1px solid #d6e2df" src="data:${imgMime(b)};base64,${base64Encode(b)}" /></td>';
      pics.add('<tr>${cell(photos[i])}${i+1<photos.length?cell(photos[i+1]):'<td style="width:50%"></td>'}</tr>');
    }
    final doc='''<!DOCTYPE html><html><head><meta charset="utf-8"><style>
@page{size:A4;margin:17mm}body{font-family:"TH Sarabun New",Tahoma,"Leelawadee UI",sans-serif;color:#263238;font-size:16pt;line-height:1.35}
h1{text-align:center;color:#087f78;font-size:24pt;margin:0 0 8pt}.sub{text-align:center;font-weight:bold;font-size:18pt;margin:0 0 18pt}
h2{background:#087f78;color:white;padding:7pt 10pt;font-size:18pt;margin:16pt 0 8pt;page-break-after:avoid}
table{width:100%;border-collapse:collapse;table-layout:fixed}th,td{border:1px solid #cbd9d7;padding:7pt;vertical-align:top;word-wrap:break-word;font-size:15pt}th{width:30%;text-align:left;color:#087f78;background:#e8f5f3}
.photo-table td{border:0}.photo-table{page-break-inside:auto}.photo-table tr{page-break-inside:avoid;page-break-after:auto}img{display:block;margin:auto}
</style></head><body><h1>${_xml(menu)}</h1><p class="sub">${_xml(title)}</p><h2>รายละเอียดข้อมูล</h2><table>$rows</table>${photos.isNotEmpty?'<h2>ภาพประกอบ (${photos.length} ภาพ)</h2><table class="photo-table">${pics.join()}</table>':''}</body></html>''';
    _download(Uint8List.fromList([0xEF,0xBB,0xBF,...utf8.encode(doc)]),'${_safe(title)}.doc','application/msword');
  }
  static Future<void> exportExcel(String menu,String title,Map<String,dynamic> row) async {
    final fields=_fields(row);
    final rows=fields.asMap().entries.map((e)=>'<Row ss:AutoFitHeight="1"><Cell ss:StyleID="${e.key.isEven?'Data':'Alt'}"><Data ss:Type="String">${_xml(e.value.key)}</Data></Cell><Cell ss:StyleID="${e.key.isEven?'Data':'Alt'}"><Data ss:Type="String">${_xml(e.value.value)}</Data></Cell></Row>').join();
    final book='''<?xml version="1.0" encoding="UTF-8"?><?mso-application progid="Excel.Sheet"?><Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet" xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet"><Styles>
<Style ss:ID="Default"><Alignment ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="12"/></Style>
<Style ss:ID="Title"><Font ss:FontName="Tahoma" ss:Size="16" ss:Bold="1" ss:Color="#FFFFFF"/><Interior ss:Color="#087F78" ss:Pattern="Solid"/><Alignment ss:Horizontal="Center" ss:Vertical="Center"/></Style>
<Style ss:ID="Subtitle"><Font ss:FontName="Tahoma" ss:Size="12" ss:Bold="1" ss:Color="#263238"/><Alignment ss:Horizontal="Center" ss:Vertical="Center"/></Style>
<Style ss:ID="Data"><Alignment ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="12"/></Style>
<Style ss:ID="Alt"><Alignment ss:Vertical="Center" ss:WrapText="1"/><Font ss:FontName="Tahoma" ss:Size="12"/><Interior ss:Color="#E8F5F3" ss:Pattern="Solid"/></Style>
</Styles><Worksheet ss:Name="ข้อมูล"><Table><Column ss:Width="210"/><Column ss:Width="440"/><Row ss:Height="32"><Cell ss:MergeAcross="1" ss:StyleID="Title"><Data ss:Type="String">${_xml(menu)}</Data></Cell></Row><Row ss:Height="26"><Cell ss:MergeAcross="1" ss:StyleID="Subtitle"><Data ss:Type="String">${_xml(title)}</Data></Cell></Row><Row ss:Height="24"><Cell ss:StyleID="Title"><Data ss:Type="String">หัวข้อ</Data></Cell><Cell ss:StyleID="Title"><Data ss:Type="String">รายละเอียด</Data></Cell></Row>$rows</Table><WorksheetOptions xmlns="urn:schemas-microsoft-com:office:excel"><FreezePanes/><FrozenNoSplit/><SplitHorizontal>3</SplitHorizontal><TopRowBottomPane>3</TopRowBottomPane><ActivePane>2</ActivePane></WorksheetOptions></Worksheet></Workbook>''';
    _download(Uint8List.fromList([0xEF,0xBB,0xBF,...utf8.encode(book)]),'${_safe(title)}.xls','application/vnd.ms-excel');
  }
}
