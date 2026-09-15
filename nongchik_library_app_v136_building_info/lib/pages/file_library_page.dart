import 'dart:typed_data';
import 'dart:html' as html;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/storage_service.dart';
import '../services/google_drive_service.dart';

class FileLibraryPage extends StatefulWidget {
  const FileLibraryPage({super.key});

  @override
  State<FileLibraryPage> createState() => _FileLibraryPageState();
}

class _FileLibraryPageState extends State<FileLibraryPage> {
  final service = StorageService();
  final drive = GoogleDriveService();
  final search = TextEditingController();

  List<Map<String, dynamic>> files = [];
  List<Map<String, dynamic>> folders = [];
  bool loadingFiles = false;
  bool loadingFolders = false;
  bool isAdmin = false;
  bool loadingRole = true;
  String? fileError;
  String? folderError;
  String filter = 'all';
  String selectedFolder = 'ทั้งหมด';

  // Batch upload state is kept on the page (not inside an async dialog).
  // This avoids Flutter lifecycle/assertion problems when many files finish.
  bool batchUploading = false;
  int batchCompleted = 0;
  int batchFailed = 0;
  int batchTotal = 0;

  @override
  void initState() {
    super.initState();
    // Render the page immediately. Data loading must never make the whole page blank.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadData();
      loadRole();
    });
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadRole() async {
    try {
      final value = await service.isCurrentUserAdmin();
      if (!mounted) return;
      setState(() {
        isAdmin = value;
        loadingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isAdmin = false;
        loadingRole = false;
      });
    }
  }

  Future<void> loadData() async {
    if (!mounted) return;
    setState(() {
      loadingFiles = true;
      loadingFolders = true;
      fileError = null;
      folderError = null;
    });

    // Load files and folders independently so one missing table cannot blank the page.
    await Future.wait([loadFiles(), loadFolders()]);
  }

  Future<void> loadFiles() async {
    try {
      final result = await service.getFiles().timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        files = result;
        loadingFiles = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingFiles = false;
        fileError = _friendlyError(e);
      });
    }
  }

  Future<void> loadFolders() async {
    try {
      final result = await service.getFolders().timeout(const Duration(seconds: 12));
      if (!mounted) return;
      setState(() {
        folders = result;
        loadingFolders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadingFolders = false;
        folderError = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final text = e.toString();
    if (text.contains('relation') && text.contains('library_folders')) {
      return 'ไม่พบตาราง library_folders ใน Supabase';
    }
    if (text.contains('relation') && text.contains('library_files')) {
      return 'ไม่พบตาราง library_files ใน Supabase';
    }
    if (text.contains('permission denied') || text.contains('row-level security')) {
      return 'Supabase ปฏิเสธสิทธิ์ (RLS): กรุณาตรวจสอบ Policy ของตาราง/Storage';
    }
    return text.replaceFirst('Exception: ', '');
  }

  List<String> get folderNames {
    final names = <String>{'ทั่วไป'};
    for (final f in folders) {
      final n = (f['name'] ?? '').toString().trim();
      if (n.isNotEmpty) names.add(n);
    }
    for (final f in files) {
      final n = (f['folder_name'] ?? 'ทั่วไป').toString().trim();
      if (n.isNotEmpty) names.add(n);
    }
    final list = names.toList();
    list.sort((a, b) {
      if (a == 'ทั่วไป') return -1;
      if (b == 'ทั่วไป') return 1;
      return a.compareTo(b);
    });
    return list;
  }

  String? _folderIdByName(String name) {
    final clean = name.trim();
    if (clean.isEmpty || clean == 'ทั่วไป') return null;
    for (final f in folders) {
      if ((f['name'] ?? '').toString().trim() == clean) {
        return (f['id'] ?? '').toString().trim().isEmpty ? null : (f['id'] ?? '').toString();
      }
    }
    return null;
  }

  List<Map<String, dynamic>> get visibleFiles {
    final q = search.text.trim().toLowerCase();
    return files.where((f) {
      final typeOk = filter == 'all' ||
          (filter == 'image' && f['file_type'] == 'image') ||
          (filter == 'document' && f['file_type'] != 'image');
      final folder = (f['folder_name'] ?? 'ทั่วไป').toString();
      final folderOk = selectedFolder == 'ทั้งหมด' || folder == selectedFolder;
      final text = '${f['title'] ?? ''} ${f['file_name'] ?? ''} ${f['description'] ?? ''} ${f['subdistrict'] ?? ''} $folder'.toLowerCase();
      return typeOk && folderOk && (q.isEmpty || text.contains(q));
    }).toList();
  }

  Future<void> createFolder() async {
    final name = TextEditingController();
    final description = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Row(children: [
            Icon(Icons.create_new_folder_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            const Text('สร้างโฟลเดอร์ใหม่'),
          ]),
          content: SizedBox(
            width: 520,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'ชื่อโฟลเดอร์ *',
                  hintText: 'เช่น กิจกรรมปี 2569, ภาพกิจกรรม, เอกสารราชการ',
                  prefixIcon: Icon(Icons.folder_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดโฟลเดอร์',
                  hintText: 'อธิบายว่าโฟลเดอร์นี้ใช้เก็บข้อมูลอะไร',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
            FilledButton.icon(
              onPressed: () {
                if (name.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('สร้างโฟลเดอร์'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await service.createFolder(name: name.text.trim(), description: description.text.trim());
      await loadFolders();
      if (!mounted) return;
      setState(() => selectedFolder = name.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('สร้างโฟลเดอร์สำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สร้างโฟลเดอร์ไม่สำเร็จ: ${_friendlyError(e)}')),
      );
    } finally {
      name.dispose();
      description.dispose();
    }
  }

  Future<void> pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        withData: true,
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'docx', 'doc', 'pdf'],
      );
      if (result == null || result.files.isEmpty) return;

      final validFiles = result.files.where((f) => f.bytes != null && f.bytes!.isNotEmpty).toList();
      if (validFiles.isEmpty) {
        throw Exception('ไม่พบข้อมูลของไฟล์ กรุณาเลือกไฟล์ใหม่');
      }
      await showBatchUploadDialog(validFiles);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เปิด/อัปโหลดไฟล์ไม่สำเร็จ: ${_friendlyError(e)}')),
      );
    }
  }

  /// V68: Select many files once, then upload them sequentially with one common
  /// folder/category/description. Each file remains a separate library item.
  Future<void> showBatchUploadDialog(List<PlatformFile> selectedFiles) async {
    final description = TextEditingController();
    final newFolder = TextEditingController();
    final newFolderDescription = TextEditingController();
    String folder = selectedFolder == 'ทั้งหมด' ? 'ทั่วไป' : selectedFolder;
    String category = 'other';
    bool makeFolder = false;
    String? folderId = _folderIdByName(folder);

    // The dialog only collects options. Uploading starts AFTER the dialog closes,
    // so no StatefulBuilder is kept alive while asynchronous uploads run.
    final config = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('อัปโหลดหลายไฟล์เข้าคลังรูปภาพและเอกสาร'),
          content: SizedBox(
            width: 680,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    const Icon(Icons.library_add_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'เลือกแล้ว ${selectedFiles.length} ไฟล์ — อัปโหลดทั้งหมดในครั้งเดียว',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: selectedFiles.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = selectedFiles[i];
                      final ext = (f.extension ?? '').toLowerCase();
                      final image = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
                      return ListTile(
                        dense: true,
                        leading: Icon(image ? Icons.image_rounded : Icons.description_rounded),
                        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Text('${(f.size / 1024 / 1024).toStringAsFixed(2)} MB'),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียด (ใช้กับทุกไฟล์)',
                    hintText: 'ที่มา วันที่ เนื้อหา หรือหมายเหตุ',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: folder,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'โฟลเดอร์', prefixIcon: Icon(Icons.folder_open_rounded)),
                  items: folderNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: (v) => setDialogState(() {
                    folder = v ?? 'ทั่วไป';
                    folderId = _folderIdByName(folder);
                    makeFolder = false;
                  }),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setDialogState(() => makeFolder = !makeFolder),
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(makeFolder ? 'ยกเลิกการสร้างโฟลเดอร์ใหม่' : 'สร้างโฟลเดอร์ใหม่พร้อมอัปโหลด'),
                  ),
                ),
                if (makeFolder) ...[
                  TextField(controller: newFolder, decoration: const InputDecoration(labelText: 'ชื่อโฟลเดอร์ใหม่ *', prefixIcon: Icon(Icons.folder_special_outlined))),
                  const SizedBox(height: 10),
                  TextField(controller: newFolderDescription, maxLines: 2, decoration: const InputDecoration(labelText: 'รายละเอียดโฟลเดอร์', prefixIcon: Icon(Icons.notes_outlined))),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<String>(
                  value: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่ (ใช้กับทุกไฟล์)', prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'learning_resource', child: Text('แหล่งเรียนรู้')),
                    DropdownMenuItem(value: 'local_wisdom', child: Text('ภูมิปัญญา')),
                    DropdownMenuItem(value: 'scholar', child: Text('ปราชญ์')),
                    DropdownMenuItem(value: 'activity', child: Text('กิจกรรม')),
                    DropdownMenuItem(value: 'other', child: Text('อื่น ๆ')),
                  ],
                  onChanged: (v) => setDialogState(() => category = v ?? 'other'),
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('ยกเลิก'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (makeFolder && newFolder.text.trim().isEmpty) return;
                Navigator.pop(dialogContext, {
                  'description': description.text.trim(),
                  'folder': folder,
                  'folder_id': folderId,
                  'category': category,
                  'make_folder': makeFolder,
                  'new_folder': newFolder.text.trim(),
                  'new_folder_description': newFolderDescription.text.trim(),
                });
              },
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text('อัปโหลด ${selectedFiles.length} ไฟล์'),
            ),
          ],
        ),
      ),
    );

    final descValue = description.text.trim();
    final newFolderValue = newFolder.text.trim();
    final newFolderDescValue = newFolderDescription.text.trim();
    description.dispose();
    newFolder.dispose();
    newFolderDescription.dispose();

    if (config == null || !mounted) return;

    await _uploadBatch(
      selectedFiles,
      description: descValue,
      folder: (config['folder'] ?? 'ทั่วไป').toString(),
      folderId: (config['folder_id'] ?? '').toString().trim().isEmpty ? null : (config['folder_id'] ?? '').toString(),
      category: (config['category'] ?? 'other').toString(),
      makeFolder: config['make_folder'] == true,
      newFolder: newFolderValue,
      newFolderDescription: newFolderDescValue,
    );
  }

  Future<void> _uploadBatch(
    List<PlatformFile> selectedFiles, {
    required String description,
    required String folder,
    required String? folderId,
    required String category,
    required bool makeFolder,
    required String newFolder,
    required String newFolderDescription,
  }) async {
    if (batchUploading || selectedFiles.isEmpty) return;

    setState(() {
      batchUploading = true;
      batchCompleted = 0;
      batchFailed = 0;
      batchTotal = selectedFiles.length;
    });

    var targetFolder = folder;
    var targetFolderId = folderId;

    try {
      if (makeFolder) {
        final created = await service.ensureFolder(
          name: newFolder,
          description: newFolderDescription,
        );
        targetFolder = (created['name'] ?? newFolder).toString();
        targetFolderId = (created['id'] ?? '').toString().trim().isEmpty ? null : (created['id'] ?? '').toString();
      }

      for (final file in selectedFiles) {
        try {
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            throw Exception('ไม่พบข้อมูลของไฟล์ ${file.name}');
          }
          final ext = (file.extension ?? '').toLowerCase();
          final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
          await service.uploadFile(
            bytes: bytes,
            fileName: file.name,
            title: file.name,
            description: description,
            fileType: isImage ? 'image' : (ext == 'pdf' ? 'pdf' : 'document'),
            category: category,
            folderName: targetFolder,
            folderId: targetFolderId,
            mimeType: _mime(ext),
          );
          if (mounted) setState(() => batchCompleted++);
        } catch (_) {
          if (mounted) setState(() => batchFailed++);
        }
      }

      if (!mounted) return;
      await loadData();
      if (!mounted) return;
      final message = batchFailed == 0
          ? 'อัปโหลดสำเร็จ $batchCompleted ไฟล์ — ส่งเข้ารอตรวจสอบแล้ว'
          : 'อัปโหลดสำเร็จ $batchCompleted ไฟล์ และไม่สำเร็จ $batchFailed ไฟล์';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('อัปโหลดไม่สำเร็จ: ${_friendlyError(e)}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => batchUploading = false);
      }
    }
  }

  Future<void> showUploadDialog(PlatformFile file, Uint8List bytes) async {
    final ext = (file.extension ?? '').toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
    final title = TextEditingController(text: file.name);
    final description = TextEditingController();
    final newFolder = TextEditingController();
    final newFolderDescription = TextEditingController();
    String folder = selectedFolder == 'ทั้งหมด' ? 'ทั่วไป' : selectedFolder;
    String category = 'other';
    bool makeFolder = false;
    bool saving = false;
    String? folderId = _folderIdByName(folder);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('อัปโหลดเข้าคลังรูปภาพและเอกสาร'),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(isImage ? Icons.image_rounded : Icons.description_rounded),
                    const SizedBox(width: 10),
                    Expanded(child: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text('${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB'),
                  ]),
                ),
                const SizedBox(height: 14),
                TextField(controller: title, decoration: const InputDecoration(labelText: 'ชื่อรายการ / ชื่อเอกสาร *', prefixIcon: Icon(Icons.title_rounded))),
                const SizedBox(height: 12),
                TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'รายละเอียด', hintText: 'ที่มา วันที่ เนื้อหา หรือหมายเหตุ', prefixIcon: Icon(Icons.description_outlined))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: folder,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'โฟลเดอร์', prefixIcon: Icon(Icons.folder_open_rounded)),
                  items: folderNames.map((n) => DropdownMenuItem(value: n, child: Text(n))).toList(),
                  onChanged: saving ? null : (v) => setDialogState(() {
                    folder = v ?? 'ทั่วไป';
                    folderId = _folderIdByName(folder);
                    makeFolder = false;
                  }),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: saving ? null : () => setDialogState(() => makeFolder = !makeFolder),
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: Text(makeFolder ? 'ยกเลิกการสร้างโฟลเดอร์ใหม่' : 'สร้างโฟลเดอร์ใหม่พร้อมอัปโหลด'),
                  ),
                ),
                if (makeFolder) ...[
                  TextField(controller: newFolder, decoration: const InputDecoration(labelText: 'ชื่อโฟลเดอร์ใหม่ *', prefixIcon: Icon(Icons.folder_special_outlined))),
                  const SizedBox(height: 10),
                  TextField(controller: newFolderDescription, maxLines: 2, decoration: const InputDecoration(labelText: 'รายละเอียดโฟลเดอร์', prefixIcon: Icon(Icons.notes_outlined))),
                  const SizedBox(height: 10),
                ],
                DropdownButtonFormField<String>(
                  value: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'หมวดหมู่', prefixIcon: Icon(Icons.category_outlined)),
                  items: const [
                    DropdownMenuItem(value: 'learning_resource', child: Text('แหล่งเรียนรู้')),
                    DropdownMenuItem(value: 'local_wisdom', child: Text('ภูมิปัญญา')),
                    DropdownMenuItem(value: 'scholar', child: Text('ปราชญ์')),
                    DropdownMenuItem(value: 'activity', child: Text('กิจกรรม')),
                    DropdownMenuItem(value: 'other', child: Text('อื่น ๆ')),
                  ],
                  onChanged: saving ? null : (v) => setDialogState(() => category = v ?? 'other'),
                ),
                if (saving) ...[
                  const SizedBox(height: 18),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('กำลังอัปโหลด กรุณารอสักครู่...'),
                ],
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
            FilledButton.icon(
              onPressed: saving ? null : () async {
                if (title.text.trim().isEmpty) return;
                if (makeFolder && newFolder.text.trim().isEmpty) return;
                setDialogState(() => saving = true);
                try {
                  if (makeFolder) {
                    // Create only when needed; if the folder already exists,
                    // use it instead of failing with a duplicate-key error.
                    final createdFolder = await service.ensureFolder(
                      name: newFolder.text.trim(),
                      description: newFolderDescription.text.trim(),
                    );
                    folder = createdFolder['name'] ?? newFolder.text.trim();
                    folderId = createdFolder['id'];
                  }
                  await service.uploadFile(
                    bytes: bytes,
                    fileName: file.name,
                    title: title.text.trim(),
                    description: description.text.trim(),
                    fileType: isImage ? 'image' : (ext == 'pdf' ? 'pdf' : 'document'),
                    category: category,
                    folderName: folder,
                    folderId: folderId,
                    mimeType: _mime(ext),
                  );
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                } catch (e) {
                  setDialogState(() => saving = false);
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: ${_friendlyError(e)}')));
                  }
                }
              },
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('อัปโหลด'),
            ),
          ],
        ),
      ),
    );

    title.dispose();
    description.dispose();
    newFolder.dispose();
    newFolderDescription.dispose();

    if (confirmed == true) {
      await loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อัปโหลดสำเร็จ — ส่งเข้ารอตรวจสอบแล้ว')));
    }
  }

  String? _mime(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }

  Future<String> _viewUrl(Map<String, dynamic> file) async {
    if ((file['storage_provider'] ?? '').toString() == 'google_drive') {
      final id = (file['drive_file_id'] ?? '').toString().trim();
      if (id.isEmpty) throw Exception('ไม่พบ Google Drive File ID');
      return drive.viewUrl(id);
    }
    final bucket = (file['storage_bucket'] ?? '').toString();
    final path = (file['storage_path'] ?? '').toString();
    if (bucket.isEmpty || path.isEmpty) throw Exception('ไม่พบตำแหน่งไฟล์ในระบบ');
    return service.createDownloadUrl(bucket, path);
  }

  Future<String> _signedUrl(Map<String, dynamic> file) async {
    if ((file['storage_provider'] ?? '').toString() == 'google_drive') {
      final id = (file['drive_file_id'] ?? '').toString().trim();
      if (id.isEmpty) throw Exception('ไม่พบ Google Drive File ID');
      return drive.downloadUrl(id);
    }
    final bucket = (file['storage_bucket'] ?? '').toString();
    final path = (file['storage_path'] ?? '').toString();
    if (bucket.isEmpty || path.isEmpty) throw Exception('ไม่พบตำแหน่งไฟล์ในระบบ');
    return service.createDownloadUrl(bucket, path);
  }

  Future<void> openFile(Map<String, dynamic> file) async {
    // IMPORTANT: Do not use HttpRequest/Blob here. Google Drive and other
    // cross-origin file URLs can reject browser XHR with CORS, producing
    // [object ProgressEvent]. Normal browser navigation does not have this
    // problem.
    final popup = html.window.open('about:blank', '_blank');
    try {
      final url = await _viewUrl(file);
      final ext = ((file['file_name'] ?? '').toString().split('.').last).toLowerCase();
      final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
      final isPdf = ext == 'pdf' || (file['mime_type'] ?? '').toString() == 'application/pdf';
      final isWord = ['doc', 'docx'].contains(ext);

      if (isImage || isPdf) {
        if (popup != null) {
          popup.location.href = url;
        } else {
          html.window.open(url, '_blank');
        }
      } else if (isWord) {
        // Chrome does not natively render .doc/.docx. Google Drive files are
        // public-by-link, so Microsoft Office Online can open the URL.
        final viewer = 'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(url)}';
        if (popup != null) {
          popup.location.href = viewer;
        } else {
          html.window.open(viewer, '_blank');
        }
      } else {
        if (popup != null) {
          popup.location.href = url;
        } else {
          html.window.open(url, '_blank');
        }
      }
    } catch (e) {
      try {
        popup?.close();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เปิดไฟล์ไม่สำเร็จ: ${_friendlyError(e)}')));
    }
  }

  Future<void> download(Map<String, dynamic> file) async {
    try {
      final url = await _signedUrl(file);
      // Do not fetch the cross-origin URL with HttpRequest. Google Drive
      // download endpoints are intended to be navigated to directly.
      final anchor = html.AnchorElement(href: url)
        ..download = (file['file_name'] ?? 'download').toString()
        ..target = '_blank'
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เริ่มดาวน์โหลดไฟล์แล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ดาวน์โหลดไม่สำเร็จ: ${_friendlyError(e)}')));
    }
  }

  Future<void> deleteFile(Map<String, dynamic> file) async {
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เฉพาะ Admin เท่านั้นที่สามารถลบไฟล์ได้')),
      );
      return;
    }

    final name = (file['title'] ?? file['file_name'] ?? 'ไฟล์นี้').toString();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded, size: 42, color: Colors.red),
        title: const Text('ยืนยันการลบไฟล์'),
        content: Text('ต้องการลบ “$name” หรือไม่?\n\nการลบจะนำไฟล์ออกจากคลังและไม่สามารถกู้คืนจากระบบได้'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('ยกเลิก')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('ลบไฟล์'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await service.deleteFile(
        id: (file['id'] ?? '').toString(),
        bucket: (file['storage_bucket'] ?? '').toString(),
        path: (file['storage_path'] ?? '').toString(),
      );
      await loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบไฟล์เรียบร้อยแล้ว')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไฟล์ไม่สำเร็จ: ${_friendlyError(e)}')),
      );
    }
  }

  String statusText(String status) => switch (status) {
        'approved' => 'อนุมัติแล้ว',
        'rejected' => 'ไม่อนุมัติ',
        _ => 'รอตรวจสอบ',
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final list = visibleFiles;
    final folderMissing = folderError != null && folderError!.contains('library_folders');

    return Scaffold(
      appBar: AppBar(
        title: const Text('คลังรูปภาพและเอกสาร', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(onPressed: loadData, tooltip: 'รีเฟรช', icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: pickAndUpload,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('อัปโหลดไฟล์'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: scheme.primary.withValues(alpha: .20), blurRadius: 22, offset: const Offset(0, 10))],
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              final buttons = Wrap(spacing: 10, runSpacing: 10, children: [
                FilledButton.icon(
                  onPressed: pickAndUpload,
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: scheme.primary),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('อัปโหลดรูปภาพ / เอกสาร'),
                ),
                OutlinedButton.icon(
                  onPressed: createFolder,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                  icon: const Icon(Icons.create_new_folder_rounded),
                  label: const Text('สร้างโฟลเดอร์'),
                ),
              ]);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD54F), Color(0xFFFFA000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(19),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .16),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.folder_copy_rounded, color: Colors.white, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('คลังรูปภาพและเอกสาร', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                    SizedBox(height: 5),
                    Text('จัดเก็บข้อมูลเป็นโฟลเดอร์ พร้อมรายละเอียด และดาวน์โหลดได้ง่าย', style: TextStyle(color: Colors.white70)),
                    if (isAdmin) ...[
                      const SizedBox(height: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text('โหมดผู้ดูแลระบบ • สามารถลบไฟล์ได้', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ])),
                ]),
                SizedBox(height: compact ? 16 : 18),
                buttons,
              ]);
            }),
          ),
          const SizedBox(height: 16),
          if (batchUploading) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.primary.withValues(alpha: .25)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const SizedBox(width: 4, height: 4),
                  Icon(Icons.cloud_upload_rounded, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text('กำลังอัปโหลด $batchCompleted / $batchTotal ไฟล์', style: const TextStyle(fontWeight: FontWeight.w800))),
                  if (batchFailed > 0) Text('ล้มเหลว $batchFailed', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: batchTotal == 0 ? 0 : batchCompleted / batchTotal),
                const SizedBox(height: 7),
                const Text('ระบบส่งไฟล์ไป Google Drive ทีละไฟล์โดยอัตโนมัติ กรุณาอย่าปิดหน้านี้'),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          if (folderMissing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scheme.secondaryContainer, borderRadius: BorderRadius.circular(18)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, color: scheme.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(child: Text('ระบบไฟล์ยังใช้งานได้ แต่ยังไม่พบตารางโฟลเดอร์ใน Supabase กรุณารันไฟล์ supabase_schema_v34.sql จำนวน 1 ครั้ง แล้วกดรีเฟรช', style: TextStyle(color: scheme.onSecondaryContainer, fontWeight: FontWeight.w700))),
              ]),
            ),
          if (fileError != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(18)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('โหลดรายการไฟล์ไม่สำเร็จ', style: TextStyle(color: scheme.onErrorContainer, fontWeight: FontWeight.w800)), const SizedBox(height: 5), SelectableText(fileError!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 12))])),
                IconButton(onPressed: loadFiles, icon: const Icon(Icons.refresh_rounded)),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          TextField(controller: search, onChanged: (_) => setState(() {}), decoration: const InputDecoration(hintText: 'ค้นหาชื่อไฟล์ / รายละเอียด / โฟลเดอร์...', prefixIcon: Icon(Icons.search_rounded))),
          const SizedBox(height: 12),
          SizedBox(height: 44, child: ListView(scrollDirection: Axis.horizontal, children: [
            _filter('all', 'ทั้งหมด', Icons.apps_rounded),
            _filter('image', 'รูปภาพ', Icons.image_rounded),
            _filter('document', 'Word / PDF', Icons.description_rounded),
          ])),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: folderNames.contains(selectedFolder) || selectedFolder == 'ทั้งหมด' ? selectedFolder : 'ทั้งหมด',
            isExpanded: true,
            decoration: InputDecoration(labelText: loadingFolders ? 'กำลังโหลดโฟลเดอร์...' : 'เลือกโฟลเดอร์', prefixIcon: const Icon(Icons.folder_open_rounded)),
            items: ['ทั้งหมด', ...folderNames].toSet().map((n) => DropdownMenuItem<String>(value: n, child: Text(n, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: loadingFolders ? null : (v) => setState(() => selectedFolder = v ?? 'ทั้งหมด'),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Icon(Icons.inventory_2_outlined, color: scheme.primary),
            const SizedBox(width: 8),
            Text('รายการในคลัง ${list.length} รายการ', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const Spacer(),
            if (loadingFiles) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            if (isAdmin && !loadingRole) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Text('ADMIN • ลบได้', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          ]),
          const SizedBox(height: 10),
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 55),
              decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(22), border: Border.all(color: scheme.outlineVariant)),
              child: Column(children: [
                Icon(loadingFiles ? Icons.hourglass_top_rounded : Icons.folder_open_rounded, size: 58, color: scheme.primary),
                const SizedBox(height: 12),
                Text(loadingFiles ? 'กำลังโหลดข้อมูล...' : 'ยังไม่มีไฟล์ในเงื่อนไขที่เลือก', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 6),
                Text('กด “อัปโหลดรูปภาพ / เอกสาร” เพื่อเพิ่มข้อมูล', style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 18),
                FilledButton.icon(onPressed: pickAndUpload, icon: const Icon(Icons.upload_file_rounded), label: const Text('เริ่มอัปโหลดไฟล์')),
              ]),
            )
          else
            ...list.map(_fileCard),
        ],
      ),
    );
  }

  Widget _filter(String value, String label, IconData icon) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          avatar: Icon(icon, size: 18),
          label: Text(label),
          selected: filter == value,
          onSelected: (_) => setState(() => filter = value),
        ),
      );

  Widget _fileCard(Map<String, dynamic> f) {
    final status = (f['status'] ?? 'pending').toString();
    final folder = (f['folder_name'] ?? 'ทั่วไป').toString();
    final isImage = f['file_type'] == 'image';
    DateTime? created;
    final rawDate = f['created_at']?.toString();
    if (rawDate != null) created = DateTime.tryParse(rawDate)?.toLocal();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isImage
                  ? [const Color(0xFF80CBC4), const Color(0xFF26A69A)]
                  : [const Color(0xFF90CAF9), const Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .10),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            isImage ? Icons.image_rounded : Icons.description_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        title: Text((f['title'] ?? f['file_name'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: Wrap(spacing: 6, runSpacing: 5, children: [
          Chip(label: Text(folder), avatar: const Icon(Icons.folder_outlined, size: 16)),
          Text('${f['file_name'] ?? ''} • ${statusText(status)}'),
          if ((f['description'] ?? '').toString().trim().isNotEmpty) Text((f['description'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (created != null) Text(DateFormat('dd/MM/yyyy HH:mm').format(created!)),
        ])),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 1,
          children: [
            IconButton(
              tooltip: 'เปิดดู',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55),
              ),
              onPressed: () => openFile(f),
              icon: const Icon(Icons.visibility_rounded),
            ),
            IconButton(
              tooltip: 'ดาวน์โหลด',
              style: IconButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.secondary,
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: .55),
              ),
              onPressed: () => download(f),
              icon: const Icon(Icons.download_rounded),
            ),
            if (isAdmin)
              IconButton(
                tooltip: 'ลบไฟล์ (Admin)',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  backgroundColor: Colors.red.shade50,
                ),
                onPressed: () => deleteFile(f),
                icon: const Icon(Icons.delete_forever_rounded),
              ),
          ],
        ),
      ),
    );
  }
}
