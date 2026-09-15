import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/google_drive_service.dart';

import 'data_list_page.dart';

class DataFormPage extends StatefulWidget {
  final DataType type;
  final Map<String, dynamic>? row;
  const DataFormPage({super.key, required this.type, this.row});

  @override
  State<DataFormPage> createState() => _DataFormPageState();
}

class _DataFormPageState extends State<DataFormPage> {
  final client = Supabase.instance.client;
  final formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  final drive = GoogleDriveService();

  late final TextEditingController name;
  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final TextEditingController gender;
  late final TextEditingController birthDate;
  late final TextEditingController educationLevel;
  late final TextEditingController currentOccupation;
  late final TextEditingController responsibleTeacher;
  late final TextEditingController learningProcess;
  late final TextEditingController description;
  late final TextEditingController backgroundHistory;
  late final TextEditingController resourceHistory;
  late final TextEditingController awards;
  late final TextEditingController subdistrict;
  late final TextEditingController address;
  late final TextEditingController contact;
  late final TextEditingController position;
  late final TextEditingController phone;
  late final TextEditingController lineId;
  late final TextEditingController facebook;
  late final TextEditingController tiktok;
  late final TextEditingController extra;
  late final TextEditingController buildingUse;
  late final TextEditingController permissionCase;
  late final TextEditingController independence;
  late final TextEditingController weekdayHours;
  late final TextEditingController weekendHours;
  late final TextEditingController openingDays;
  late final TextEditingController learnerCapacity;
  late final TextEditingController parkingCapacity;
  late final TextEditingController internet;
  late final TextEditingController waterSupply;
  late final TextEditingController electricity;
  late final TextEditingController toilet;
  late final TextEditingController notebook;
  late final TextEditingController desktop;
  late final TextEditingController tv;
  late final TextEditingController tablet;
  late final TextEditingController projector;
  late final TextEditingController tables;
  late final TextEditingController chairs;
  late final TextEditingController latitude;
  late final TextEditingController longitude;

  final List<XFile> newImages = [];
  XFile? newPersonImage;
  final List<PlatformFile> newCertificates = [];
  List<String> photoPaths = [];
  List<String> certificatePaths = [];
  List<String> photoDriveIds = [];
  List<String> certificateDriveIds = [];
  String personPhotoDriveId = '';
  bool saving = false;
  bool loadingProfile = true;
  bool isAdmin = false;
  bool active = true;
  String assignedSubdistrict = '';

  static const subdistrictOptions = [
    'เกาะเปาะ','ลิปะสะโง','คอลอตันหยง','ดอนรัก','ดาโต๊ะ','ตุยง',
    'ท่ากำชำ','บางเขา','บางตาวา','บ่อทอง','ปุโละปุโย','ยาบี',
  ];

  bool get editing => widget.row != null;

  // library_files.category in Supabase accepts only the controlled values
  // used by the File Library UI.  Keep the human-readable DataType title
  // for the app UI, but send the database-safe category code to Drive.
  String get uploadCategory {
    switch (widget.type) {
      case DataType.learningResource:
        return 'learning_resource';
      case DataType.localWisdom:
        return 'local_wisdom';
      case DataType.localScholar:
        return 'scholar';
      case DataType.communityBookHouse:
      case DataType.subdistrictLearningCenter:
      case DataType.touristAttraction:
      case DataType.traditionalFood:
        return 'other';
    }
  }

  @override
  void initState() {
    super.initState();
    final r = widget.row;
    name = TextEditingController(text: r?['name']?.toString() ?? '');
    firstName = TextEditingController(text: r?['first_name']?.toString() ?? '');
    lastName = TextEditingController(text: r?['last_name']?.toString() ?? '');
    gender = TextEditingController(text: r?['gender']?.toString() ?? '');
    birthDate = TextEditingController(text: r?['birth_date']?.toString() ?? '');
    educationLevel = TextEditingController(text: r?['education_level']?.toString() ?? '');
    currentOccupation = TextEditingController(text: r?['current_occupation']?.toString() ?? '');
    responsibleTeacher = TextEditingController(text: r?['responsible_teacher']?.toString() ?? '');
    learningProcess = TextEditingController(text: r?['learning_process']?.toString() ?? '');
    description = TextEditingController(text: r?['description']?.toString() ?? '');
    backgroundHistory = TextEditingController(text: r?['background_history']?.toString() ?? '');
    resourceHistory = TextEditingController(text: r?['resource_history']?.toString() ?? '');
    awards = TextEditingController(text: r?['awards']?.toString() ?? '');
    subdistrict = TextEditingController(text: r?['subdistrict']?.toString() ?? '');
    address = TextEditingController(text: r?['address']?.toString() ?? '');
    contact = TextEditingController(text: r?['contact']?.toString() ?? '');
    position = TextEditingController(text: r?['position']?.toString() ?? '');
    phone = TextEditingController(text: r?['contact_phone']?.toString() ?? '');
    lineId = TextEditingController(text: r?['contact_line']?.toString() ?? '');
    facebook = TextEditingController(text: r?['contact_facebook']?.toString() ?? '');
    tiktok = TextEditingController(text: r?['contact_tiktok']?.toString() ?? '');
    extra = TextEditingController(text: r?['extra_info']?.toString() ?? '');
    buildingUse = TextEditingController(text: r?['building_use']?.toString() ?? '');
    permissionCase = TextEditingController(text: r?['permission_case']?.toString() ?? '');
    independence = TextEditingController(text: r?['independence']?.toString() ?? '');
    weekdayHours = TextEditingController(text: r?['weekday_hours']?.toString() ?? '');
    weekendHours = TextEditingController(text: r?['weekend_hours']?.toString() ?? '');
    openingDays = TextEditingController(text: r?['opening_days']?.toString() ?? '');
learnerCapacity = TextEditingController(text: r?['learner_capacity']?.toString() ?? '');
parkingCapacity = TextEditingController(text: r?['parking_capacity']?.toString() ?? '');
    internet = TextEditingController(text: r?['internet']?.toString() ?? '');
    waterSupply = TextEditingController(text: r?['water_supply']?.toString() ?? '');
    electricity = TextEditingController(text: r?['electricity']?.toString() ?? '');
    toilet = TextEditingController(text: r?['toilet']?.toString() ?? '');
    notebook = TextEditingController(text: r?['notebook']?.toString() ?? '');
    desktop = TextEditingController(text: r?['desktop']?.toString() ?? '');
    tv = TextEditingController(text: r?['tv']?.toString() ?? '');
    tablet = TextEditingController(text: r?['tablet']?.toString() ?? '');
    projector = TextEditingController(text: r?['projector']?.toString() ?? '');
    tables = TextEditingController(text: r?['tables']?.toString() ?? '');
    chairs = TextEditingController(text: r?['chairs']?.toString() ?? '');
    latitude = TextEditingController(text: r?['latitude']?.toString() ?? '');
    longitude = TextEditingController(text: r?['longitude']?.toString() ?? '');
    photoPaths = _stringList(r?['photo_paths']);
    certificatePaths = _stringList(r?['certificate_paths']);
    photoDriveIds = _stringList(r?['photo_drive_ids']);
    certificateDriveIds = _stringList(r?['certificate_drive_ids']);
    personPhotoDriveId = r?['person_photo_drive_id']?.toString() ?? '';
    _loadProfile();
  }

  List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return <String>[];
  }

  Future<void> _loadProfile() async {
    final user = client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => loadingProfile = false);
      return;
    }
    try {
      final p = await client.from('profiles').select('role,subdistrict,is_active').eq('id', user.id).maybeSingle();
      if (!mounted) return;
      final admin = p?['role']?.toString() == 'admin';
      final assigned = p?['subdistrict']?.toString() ?? '';
      final isActive = p?['is_active'] != false;
      setState(() {
        isAdmin = admin;
        assignedSubdistrict = assigned;
        active = isActive;
        loadingProfile = false;
        if (!editing && !admin && assigned.isNotEmpty) subdistrict.text = assigned;
      });
    } catch (_) {
      if (mounted) setState(() => loadingProfile = false);
    }
  }

  @override
  void dispose() {
    for (final c in [name, firstName, lastName, gender, birthDate, educationLevel, currentOccupation, responsibleTeacher, learningProcess, description, backgroundHistory, resourceHistory, awards, subdistrict, address, contact, position, phone, lineId, facebook, tiktok, extra, buildingUse, permissionCase, independence, weekdayHours, weekendHours, openingDays, internet, waterSupply, electricity, toilet, notebook, desktop, tv, tablet, projector, tables, chairs, latitude, longitude]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
  );

  Widget card(String title, IconData icon, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: scheme.primary.withOpacity(.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primaryContainer],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Icon(icon, color: scheme.onPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: scheme.onSurface))),
          ]),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }

  Future<void> pickImages() async {
    try {
      final files = await picker.pickMultiImage(imageQuality: 85);
      if (files.isNotEmpty && mounted) setState(() => newImages.addAll(files));
    } catch (e) { if (mounted) _error('เลือกรูปไม่สำเร็จ: $e'); }
  }

  Future<void> pickPersonImage() async {
    try {
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (file != null && mounted) setState(() => newPersonImage = file);
    } catch (e) {
      if (mounted) _error('เลือกรูปบุคคลไม่สำเร็จ: $e');
    }
  }

  Future<String> uploadPersonImage(XFile file, String uid) async {
    final bytes = await file.readAsBytes();
    final result = await drive.upload(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType ?? 'image/jpeg',
      folderName: '${subdistrict.text.trim()}/${widget.type.title}/ภาพบุคคล',
      category: uploadCategory,
      subdistrict: subdistrict.text.trim(),
    );
    return (result['id'] ?? '').toString();
  }

  Future<void> pickCertificates() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true, withData: true, type: FileType.custom,
        allowedExtensions: ['pdf','jpg','jpeg','png','doc','docx'],
      );
      if (result == null || !mounted) return;
      final files = result.files.where((f) => f.bytes != null).toList();
      setState(() => newCertificates.addAll(files));
    } catch (e) { if (mounted) _error('เลือกเกียรติบัตรไม่สำเร็จ: $e'); }
  }

  Future<String> uploadImage(XFile file, String uid) async {
    final bytes = await file.readAsBytes();
    final result = await drive.upload(
      bytes: bytes,
      fileName: file.name,
      mimeType: file.mimeType ?? 'image/jpeg',
      folderName: '${subdistrict.text.trim()}/${widget.type.title}/ภาพแหล่งเรียนรู้',
      category: uploadCategory,
      subdistrict: subdistrict.text.trim(),
    );
    photoDriveIds.add((result['id'] ?? '').toString());
    return '';
  }

  Future<String> uploadCertificate(PlatformFile file, String uid) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('ไม่สามารถอ่านไฟล์ ${file.name} ได้');
    final ext = (file.extension ?? '').toLowerCase();
    final mime = switch (ext) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'png' => 'image/png',
      _ => 'image/jpeg',
    };
    final result = await drive.upload(
      bytes: bytes,
      fileName: file.name,
      mimeType: mime,
      folderName: '${subdistrict.text.trim()}/${widget.type.title}/ภาพเกียรติบัตร',
      category: uploadCategory,
      subdistrict: subdistrict.text.trim(),
    );
    certificateDriveIds.add((result['id'] ?? '').toString());
    return '';
  }

  Future<void> captureGps() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw Exception('กรุณาเปิดบริการตำแหน่งของเครื่อง');
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw Exception('ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง');
      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      if (!mounted) return;
      setState(() {
        latitude.text = p.latitude.toStringAsFixed(6);
        longitude.text = p.longitude.toStringAsFixed(6);
      });
      _ok('ดึงพิกัด GPS ปัจจุบันแล้ว');
    } catch (e) { if (mounted) _error(e.toString().replaceFirst('Exception: ', '')); }
  }

  LatLng? get gps {
    final a = double.tryParse(latitude.text.trim());
    final b = double.tryParse(longitude.text.trim());
    if (a == null || b == null || a < -90 || a > 90 || b < -180 || b > 180) return null;
    return LatLng(a, b);
  }

  Future<void> chooseFromMap() async {
    final start = gps ?? const LatLng(6.74, 101.18);
    LatLng picked = start;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('เลือกพิกัดจากแผนที่'),
        content: SizedBox(
          width: 700, height: 430,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: start,
              initialZoom: gps == null ? 11 : 16,
              onTap: (_, point) { picked = point; },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.nongchik.library'),
              MarkerLayer(markers: [Marker(point: picked, width: 52, height: 52, child: const Icon(Icons.location_on, color: Colors.red, size: 46))]),
              RichAttributionWidget(attributions: const [TextSourceAttribution('OpenStreetMap contributors')]),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () {
            latitude.text = picked.latitude.toStringAsFixed(6);
            longitude.text = picked.longitude.toStringAsFixed(6);
            Navigator.pop(dialogContext);
            if (mounted) setState(() {});
          }, child: const Text('ใช้พิกัดนี้')),
        ],
      ),
    );
  }

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (saving) return;
    setState(() => saving = true);
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');
      final p = await client.from('profiles').select('role,subdistrict,is_active').eq('id', user.id).maybeSingle();
      if (p == null) throw Exception('ไม่พบข้อมูลบัญชี');
      if (p['is_active'] == false) throw Exception('บัญชีถูกปิดการใช้งาน');
      final admin = p['role']?.toString() == 'admin';
      final assigned = p['subdistrict']?.toString() ?? '';
      if (!admin && assigned.isEmpty) throw Exception('บัญชียังไม่ได้กำหนดตำบลที่รับผิดชอบ');
      final selectedSub = admin ? subdistrict.text.trim() : assigned;
      if (selectedSub.isEmpty) throw Exception('กรุณาเลือกตำบล');

      final allPhotos = photoPaths.where((e) => e.trim().isNotEmpty).toList();
      final allCertificates = certificatePaths.where((e) => e.trim().isNotEmpty).toList();
      for (final image in newImages) allPhotos.add(await uploadImage(image, user.id));
      for (final cert in newCertificates) allCertificates.add(await uploadCertificate(cert, user.id));
      if (newPersonImage != null) {
        personPhotoDriveId = await uploadPersonImage(newPersonImage!, user.id);
      }

      final lat = double.tryParse(latitude.text.trim());
      final lng = double.tryParse(longitude.text.trim());
      if ((lat == null) != (lng == null)) throw Exception('กรุณากรอก Latitude และ Longitude ให้ครบทั้งสองช่อง');
      if (lat != null && (lat < -90 || lat > 90 || lng! < -180 || lng > 180)) throw Exception('พิกัดไม่ถูกต้อง');

      final payload = <String, dynamic>{
        'name': name.text.trim(),
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        if (widget.type != DataType.subdistrictLearningCenter) ...{
          'gender': gender.text.trim(),
          'birth_date': birthDate.text.trim(),
          'education_level': educationLevel.text.trim(),
          'current_occupation': currentOccupation.text.trim(),
          'responsible_teacher': responsibleTeacher.text.trim(),
        },
        'person_photo_drive_id': personPhotoDriveId.trim().isEmpty ? null : personPhotoDriveId.trim(),
        'description': description.text.trim(),
        'background_history': backgroundHistory.text.trim(), 'resource_history': resourceHistory.text.trim(),
        if (widget.type != DataType.subdistrictLearningCenter) 'learning_process': learningProcess.text.trim(),
        'awards': awards.text.trim(), 'certificate_paths': allCertificates,
        'photo_drive_ids': photoDriveIds.where((e) => e.trim().isNotEmpty).toList(),
        'certificate_drive_ids': certificateDriveIds.where((e) => e.trim().isNotEmpty).toList(),
        'subdistrict': selectedSub, 'address': address.text.trim(), 'contact': contact.text.trim(), 'position': position.text.trim(), 'contact_phone': phone.text.trim(), 'contact_line': lineId.text.trim(), 'contact_facebook': facebook.text.trim(), 'contact_tiktok': tiktok.text.trim(),
        'extra_info': extra.text.trim(),
        'building_use': buildingUse.text.trim(),
        'permission_case': permissionCase.text.trim(),
        'independence': independence.text.trim(),
        'weekday_hours': weekdayHours.text.trim(),
        'weekend_hours': weekendHours.text.trim(),
        'opening_days': openingDays.text.trim(),
        'internet': internet.text.trim(),
        'water_supply': waterSupply.text.trim(),
        'electricity': electricity.text.trim(),
        'toilet': toilet.text.trim(),
        'notebook': notebook.text.trim(),
        'desktop': desktop.text.trim(),
        'tv': tv.text.trim(),
        'tablet': tablet.text.trim(),
        'projector': projector.text.trim(),
        'tables': tables.text.trim(),
        'chairs': chairs.text.trim(),
        'latitude': lat, 'longitude': lng, 'photo_paths': allPhotos,
        'status': 'pending',
      };
      if (editing) {
        await client.from(widget.type.table).update(payload).eq('id', widget.row!['id']);
      } else {
        payload['created_by'] = user.id;
        await client.from(widget.type.table).insert(payload);
      }
      if (!mounted) return;
      _ok('บันทึกข้อมูลสำเร็จ • ส่งให้ห้องสมุดตรวจสอบแล้ว');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) _error('บันทึกไม่สำเร็จ\n$e');
    } finally { if (mounted) setState(() => saving = false); }
  }

  void _ok(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  void _error(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s), duration: const Duration(seconds: 8)));

  @override
  Widget build(BuildContext context) {
    final selected = subdistrictOptions.contains(subdistrict.text)
        ? subdistrict.text
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(editing ? 'แก้ไข${widget.type.title}' : 'เพิ่ม${widget.type.title}'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              if (!active)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text('บัญชีนี้ถูกปิดการใช้งาน'),
                ),

              card(
                'ข้อมูลหลัก',
                Icons.info_outline,
                Column(
                  children: [
                    TextFormField(
                      controller: name,
                      decoration: decoration('ชื่อ${widget.type.title} *', Icons.title),
                      validator: (v) => v == null || v.trim().isEmpty ? 'กรุณาระบุชื่อ' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: firstName,
                            decoration: decoration('ชื่อ', Icons.person_outline),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: lastName,
                            decoration: decoration('นามสกุล', Icons.person_outline),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: description,
                      maxLines: 4,
                      decoration: decoration('รายละเอียด', Icons.description_outlined),
                    ),
                    const SizedBox(height: 12),
                    if (loadingProfile) const LinearProgressIndicator(minHeight: 3),
                    if (!loadingProfile) ...[
                      const SizedBox(height: 8),
                      if (!isAdmin && assignedSubdistrict.isEmpty)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('ยังไม่ได้กำหนดตำบลที่รับผิดชอบ', style: TextStyle(color: Colors.red)),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: selected,
                          isExpanded: true,
                          decoration: decoration(widget.type == DataType.subdistrictLearningCenter ? 'ศกร.ระดับตำบล *' : 'ตำบล *', Icons.location_city),
                          items: subdistrictOptions
                              .map((s) => DropdownMenuItem<String>(value: s, child: Text(widget.type == DataType.subdistrictLearningCenter ? 'ศกร.ระดับตำบล$s' : s)))
                              .toList(),
                          onChanged: isAdmin
                              ? (v) {
                                  if (v != null) setState(() => subdistrict.text = v);
                                }
                              : null,
                          validator: (_) => subdistrict.text.trim().isEmpty ? (widget.type == DataType.subdistrictLearningCenter ? 'กรุณาเลือก ศกร.ระดับตำบล' : 'กรุณาเลือกตำบล') : null,
                        ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: address,
                      maxLines: 2,
                      decoration: decoration('ที่อยู่ / สถานที่', Icons.place_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contact,
                      decoration: decoration('ผู้รับผิดชอบ', Icons.person_outline),
                    ),
                    const SizedBox(height: 12),
                    if (widget.type == DataType.subdistrictLearningCenter) ...[
                      TextFormField(
                        controller: position,
                        decoration: decoration('ตำแหน่ง', Icons.badge_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: decoration('เบอร์โทรศัพท์', Icons.phone_outlined),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: lineId,
                      decoration: decoration('ID Line', Icons.chat_bubble_outline),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: facebook,
                      decoration: decoration('Facebook', Icons.facebook),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tiktok,
                      decoration: decoration('TikTok', Icons.music_note_outlined),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: extra,
                      maxLines: 4,
                      decoration: decoration(_extraLabel, Icons.notes_outlined),
                    ),
                  ],
                ),
              ),

              if (widget.type != DataType.subdistrictLearningCenter) ...[
                card(
                  'ข้อมูลบุคคลและผู้รับผิดชอบ',
                  Icons.badge_outlined,
                  Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: ['ชาย', 'หญิง', 'อื่น ๆ'].contains(gender.text) ? gender.text : null,
                        isExpanded: true,
                        decoration: decoration('เพศ', Icons.wc_outlined),
                        items: const [
                          DropdownMenuItem(value: 'ชาย', child: Text('ชาย')),
                          DropdownMenuItem(value: 'หญิง', child: Text('หญิง')),
                          DropdownMenuItem(value: 'อื่น ๆ', child: Text('อื่น ๆ')),
                        ],
                        onChanged: (v) => setState(() => gender.text = v ?? ''),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: birthDate,
                        decoration: decoration('วัน เดือน ปี เกิด', Icons.cake_outlined).copyWith(
                          hintText: 'เช่น 15/08/2525',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: educationLevel,
                        decoration: decoration('จบการศึกษาระดับ', Icons.school_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: currentOccupation,
                        decoration: decoration('อาชีพปัจจุบัน', Icons.work_outline),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: responsibleTeacher,
                        decoration: decoration('ครูผู้รับผิดชอบ', Icons.person_pin_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: position,
                        decoration: decoration('ตำแหน่ง', Icons.badge_outlined),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: decoration('เบอร์โทรติดต่อ', Icons.phone_in_talk_outlined),
                      ),
                    ],
                  ),
                ),
              ],

              card(
                'ข้อมูลอาคารสถานที่',
                  Icons.apartment_outlined,
                  Column(
  children: [
    TextFormField(
      controller: buildingUse,
      maxLines: 2,
      decoration: decoration(
        'ลักษณะการใช้อาคาร',
        Icons.business_outlined,
      ),
    ),
    const SizedBox(height: 12),

    TextFormField(
      controller: permissionCase,
      maxLines: 2,
      decoration: decoration(
        'กรณีได้รับอนุญาต',
        Icons.fact_check_outlined,
      ),
    ),
    const SizedBox(height: 12),

    TextFormField(
      controller: independence,
      maxLines: 2,
      decoration: decoration(
        'ความเป็นเอกเทศ',
        Icons.business_outlined,
      ),
    ),
    const SizedBox(height: 12),

    TextFormField(
      controller: learnerCapacity,
      keyboardType: TextInputType.number,
      decoration: decoration(
        'จำนวนผู้เรียนที่รองรับ',
        Icons.groups_outlined,
      ),
    ),
    const SizedBox(height: 12),

    TextFormField(
      controller: parkingCapacity,
      keyboardType: TextInputType.number,
      decoration: decoration(
        'จำนวนที่จอดรถ',
        Icons.local_parking_outlined,
      ),
    ),
  ],
),
                ),
                card(
                  'เวลาเปิดทำการ',
                  Icons.access_time_outlined,
                  Column(
                    children: [
                      TextFormField(controller: weekdayHours, decoration: decoration('วันจันทร์-ศุกร์', Icons.work_history_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: weekendHours, decoration: decoration('วันเสาร์-อาทิตย์', Icons.weekend_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: openingDays, decoration: decoration('วันเปิดทำการ', Icons.calendar_month_outlined)),
                    ],
                  ),
                ),
                card(
                  'สิ่งอำนวยความสะดวก',
                  Icons.construction_outlined,
                  Column(
                    children: [
                      TextFormField(controller: internet, decoration: decoration('อินเตอร์เน็ต', Icons.wifi_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: waterSupply, decoration: decoration('น้ำประปา', Icons.water_drop_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: electricity, decoration: decoration('ไฟฟ้า', Icons.bolt_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: toilet, decoration: decoration('สุขา', Icons.wc_outlined)),
                    ],
                  ),
                ),
                card(
                  'ครุภัณฑ์',
                  Icons.inventory_2_outlined,
                  Column(
                    children: [
                      TextFormField(controller: notebook, keyboardType: TextInputType.number, decoration: decoration('Notebook', Icons.laptop_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: desktop, keyboardType: TextInputType.number, decoration: decoration('Desktop', Icons.desktop_windows_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: tv, keyboardType: TextInputType.number, decoration: decoration('TV', Icons.tv_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: tablet, keyboardType: TextInputType.number, decoration: decoration('Tablet', Icons.tablet_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: projector, keyboardType: TextInputType.number, decoration: decoration('Projector', Icons.videocam_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: tables, keyboardType: TextInputType.number, decoration: decoration('โต๊ะ', Icons.table_restaurant_outlined)),
                      const SizedBox(height: 12),
                      TextFormField(controller: chairs, keyboardType: TextInputType.number, decoration: decoration('เก้าอี้', Icons.chair_outlined)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

              card(
                'ประวัติและรางวัล',
                Icons.workspace_premium_outlined,
                Column(
                  children: [
                    TextFormField(controller: backgroundHistory, maxLines: 5, decoration: decoration('ประวัติความเป็นมา', Icons.history_edu)),
                    const SizedBox(height: 12),
                    TextFormField(controller: resourceHistory, maxLines: 5, decoration: decoration('ประวัติของแหล่งเรียนรู้', Icons.menu_book_outlined)),
                    const SizedBox(height: 12),
                    TextFormField(controller: learningProcess, maxLines: 5, decoration: decoration('กระบวนการเรียนรู้', Icons.auto_stories_outlined)),
                    const SizedBox(height: 12),
                    TextFormField(controller: awards, maxLines: 5, decoration: decoration('รางวัลที่ได้รับ', Icons.emoji_events_outlined)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: pickCertificates,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('อัปโหลดเกียรติบัตร / หลักฐานรางวัล'),
                      ),
                    ),
                    ...certificatePaths.map((p) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.verified),
                          title: Text(p.split('/').last, overflow: TextOverflow.ellipsis),
                        )),
                    ...newCertificates.asMap().entries.map((entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.attach_file),
                          title: Text(entry.value.name, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            onPressed: () => setState(() => newCertificates.removeAt(entry.key)),
                            icon: const Icon(Icons.close),
                          ),
                        )),
                  ],
                ),
              ),

              card(
                'รูปภาพชื่อ–นามสกุล',
                Icons.account_circle_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('รูปบุคคลของชื่อ–นามสกุล • แนะนำรูปหน้าตรง เห็นใบหน้าชัดเจน'),
                    const SizedBox(height: 10),
                    if (newPersonImage != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.image_outlined),
                        title: Text(newPersonImage!.name, overflow: TextOverflow.ellipsis),
                        trailing: IconButton(
                          onPressed: () => setState(() => newPersonImage = null),
                          icon: const Icon(Icons.close),
                        ),
                      )
                    else if (personPhotoDriveId.isNotEmpty)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.check_circle_outline),
                        title: const Text('มีรูปบุคคลที่บันทึกไว้แล้ว'),
                      ),
                    OutlinedButton.icon(
                      onPressed: pickPersonImage,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(personPhotoDriveId.isNotEmpty ? 'เปลี่ยนรูปบุคคล' : 'เลือกรูปบุคคล'),
                    ),
                  ],
                ),
              ),

              card(
                'รูปภาพ',
                Icons.photo_library_outlined,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('เพิ่มรูปได้หลายรูป • ${photoPaths.length + newImages.length} รูป'),
                    const SizedBox(height: 10),
                    ...newImages.asMap().entries.map((entry) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.image_outlined),
                          title: Text(entry.value.name, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            onPressed: () => setState(() => newImages.removeAt(entry.key)),
                            icon: const Icon(Icons.close),
                          ),
                        )),
                    OutlinedButton.icon(
                      onPressed: pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('เลือกรูปภาพ'),
                    ),
                  ],
                ),
              ),

              card(
                'พิกัด GPS',
                Icons.location_on_outlined,
                Column(
                  children: [
                    TextFormField(
                      controller: latitude,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: decoration('Latitude', Icons.north),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: longitude,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: decoration('Longitude', Icons.east),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: captureGps,
                        icon: const Icon(Icons.my_location),
                        label: const Text('ดึงพิกัดอัตโนมัติ'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: chooseFromMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('เลือกจากแผนที่'),
                      ),
                    ),
                    if (gps != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('📍 ${gps!.latitude.toStringAsFixed(6)}, ${gps!.longitude.toStringAsFixed(6)}'),
                      ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('ข้อมูลจะถูกส่งเป็น “รอตรวจสอบ” และจะแสดงต่อสาธารณะหลังแอดมินอนุมัติ'),
              ),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: saving || !active ? null : save,
                  icon: saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'กำลังบันทึก...' : 'บันทึกและส่งให้ห้องสมุดตรวจสอบ'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String get _extraLabel {
    switch (widget.type) {
      case DataType.learningResource: return 'ประเภท / กิจกรรมการเรียนรู้';
      case DataType.localWisdom: return 'สาขาภูมิปัญญา / การสืบทอด';
      case DataType.localScholar: return 'ความเชี่ยวชาญ / ประวัติย่อ';
      case DataType.communityBookHouse: return 'เวลาเปิดบริการ / รายละเอียดบ้านหนังสือ';
      case DataType.subdistrictLearningCenter: return 'ข้อมูลบริการ / กิจกรรมของ ศกร.';
      case DataType.touristAttraction: return 'จุดเด่น / ข้อมูลการท่องเที่ยว';
      case DataType.traditionalFood: return 'ส่วนผสม / วิธีทำ / เรื่องราวของอาหาร';
    }
  }
}
