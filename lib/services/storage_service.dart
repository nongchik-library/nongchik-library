import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'google_drive_service.dart';

class StorageService {
  final SupabaseClient client = Supabase.instance.client;
  final GoogleDriveService drive = GoogleDriveService();

  Future<bool> isCurrentUserAdmin() async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    final profile = await client
        .from('profiles')
        .select('role,is_active')
        .eq('id', user.id)
        .maybeSingle();
    return profile?['role'] == 'admin' && profile?['is_active'] != false;
  }

  Future<void> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String title,
    required String fileType,
    required String category,
    String? description,
    String? subdistrict,
    String? folderName,
    String? folderId,
    String? mimeType,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    // V55: new library uploads go to Google Drive. Existing Supabase files remain supported.
    final driveResult = await drive.upload(
      bytes: bytes,
      fileName: fileName,
      mimeType: mimeType ?? 'application/octet-stream',
      folderId: folderId,
      folderName: (folderName ?? '').trim().isEmpty ? 'ทั่วไป' : folderName!.trim(),
      category: category,
    );
    // V72: drive-upload now saves the library_files row with the verified
    // Supabase user on the server. This avoids the Drive upload succeeding
    // while the client-side INSERT is rejected, which previously left orphan
    // files in Google Drive that did not appear in the web library.
    return;

    /* Legacy Supabase upload path kept below for existing/rollback use.
    final bucket = fileType == 'image' ? 'library-images' : 'library-documents';
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    // Never put Thai/space folder names directly into a Storage object key.
    // Supabase Storage can reject some Unicode keys with InvalidKey (400).
    // The visible folder name is kept in library_files; Storage uses the
    // stable folder UUID when available, so creating/selecting folders is safe.
    final safeFolderId = (folderId ?? '').trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
    final prefix = safeFolderId.isEmpty
        ? '${user.id}/root'
        : '${user.id}/folders/$safeFolderId';
    final path = '$prefix/${DateTime.now().millisecondsSinceEpoch}-$safeName';

    var uploaded = false;
    try {
      await client.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(contentType: mimeType, upsert: false),
      );
      uploaded = true;

      final row = {
        'title': title.trim(),
        'description': (description ?? '').trim(),
        'file_name': fileName,
        'file_type': fileType,
        'category': category,
        'subdistrict': subdistrict,
        'folder_name': (folderName ?? '').trim().isEmpty ? 'ทั่วไป' : folderName!.trim(),
        'storage_bucket': bucket,
        'storage_path': path,
        'mime_type': mimeType,
        'file_size': bytes.length,
        'uploaded_by': user.id,
        'status': 'pending',
      };

      await client.from('library_files').insert(row).select('id').single();
    } on PostgrestException catch (e) {
      if (uploaded) {
        try { await client.storage.from(bucket).remove([path]); } catch (_) {}
      }
      throw Exception('Supabase: ${e.message} (code ${e.code ?? '-'})');
    } catch (e) {
      if (uploaded) {
        try { await client.storage.from(bucket).remove([path]); } catch (_) {}
      }
      rethrow;
    }
  }

    */
  }

  Future<List<Map<String, dynamic>>> getFolders() async {
    final data = await client
        .from('library_folders')
        .select()
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> createFolder({
    required String name,
    String? description,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');
    final clean = name.trim();
    if (clean.isEmpty) throw Exception('กรุณาระบุชื่อโฟลเดอร์');

    // Check first so the UI gets a friendly result instead of a 23505
    // unique-constraint error when the folder already exists.
    final existing = await client
        .from('library_folders')
        .select('id')
        .eq('created_by', user.id)
        .ilike('name', clean)
        .limit(1);
    if ((existing as List).isNotEmpty) {
      throw Exception('มีโฟลเดอร์ “$clean” อยู่แล้ว กรุณาใช้โฟลเดอร์เดิม');
    }

    await client.from('library_folders').insert({
      'name': clean,
      'description': (description ?? '').trim(),
      'created_by': user.id,
    });
  }

  /// Returns the existing folder (id + name), or creates it.
  /// The folder name is for display/metadata; Storage uses folder id.
  Future<Map<String, String>> ensureFolder({
    required String name,
    String? description,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');
    final clean = name.trim();
    if (clean.isEmpty) throw Exception('กรุณาระบุชื่อโฟลเดอร์');

    final existing = await client
        .from('library_folders')
        .select('id,name')
        .eq('created_by', user.id)
        .ilike('name', clean)
        .limit(1);
    final rows = List<Map<String, dynamic>>.from(existing);
    if (rows.isNotEmpty) {
      return {
        'id': (rows.first['id'] ?? '').toString(),
        'name': (rows.first['name'] ?? clean).toString(),
      };
    }

    try {
      final created = await client
          .from('library_folders')
          .insert({
            'name': clean,
            'description': (description ?? '').trim(),
            'created_by': user.id,
          })
          .select('id,name')
          .single();
      return {
        'id': (created['id'] ?? '').toString(),
        'name': (created['name'] ?? clean).toString(),
      };
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        final retry = await client
            .from('library_folders')
            .select('id,name')
            .eq('created_by', user.id)
            .ilike('name', clean)
            .limit(1);
        final retryRows = List<Map<String, dynamic>>.from(retry);
        if (retryRows.isNotEmpty) {
          return {
            'id': (retryRows.first['id'] ?? '').toString(),
            'name': (retryRows.first['name'] ?? clean).toString(),
          };
        }
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFiles() async {
    final data = await client
        .from('library_files')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<String> createDownloadUrl(String bucket, String path, {int expiresIn = 3600}) async {
    final cleanBucket = bucket.trim();
    final cleanPath = path.trim();
    if (cleanBucket.isEmpty || cleanPath.isEmpty) {
      throw Exception('ไม่พบตำแหน่งไฟล์ในคลัง');
    }
    return client.storage.from(cleanBucket).createSignedUrl(cleanPath, expiresIn);
  }

  Future<Uint8List> downloadFile(String bucket, String path) async {
    // Keep a byte-download API for non-web callers, but validate the path.
    final cleanBucket = bucket.trim();
    final cleanPath = path.trim();
    if (cleanBucket.isEmpty || cleanPath.isEmpty) {
      throw Exception('ไม่พบตำแหน่งไฟล์ในคลัง');
    }
    return client.storage.from(cleanBucket).download(cleanPath);
  }

  Future<void> deleteFile({
    required String id,
    required String bucket,
    required String path,
  }) async {
    final profile = await client
        .from('profiles')
        .select('role')
        .eq('id', client.auth.currentUser!.id)
        .single();

    if (profile['role'] != 'admin') {
      throw Exception('เฉพาะ Admin เท่านั้นที่สามารถลบไฟล์ได้');
    }

    if (await _isDriveRecord(id)) {
      final row = await client.from('library_files').select('drive_file_id,storage_provider').eq('id', id).single();
      if (row['storage_provider'] == 'google_drive') {
        final driveId = (row['drive_file_id'] ?? '').toString();
        if (driveId.isNotEmpty) {
          final response = await client.functions.invoke('drive-delete', body: {'drive_file_id': driveId});
          if (response.data is Map && (response.data['error'] != null)) {
            throw Exception(response.data['error'].toString());
          }
        }
        await client.from('library_files').delete().eq('id', id);
        return;
      }
    }
    await client.storage.from(bucket).remove([path]);
    await client.from('library_files').delete().eq('id', id);
  }


  Future<bool> _isDriveRecord(String id) async {
    final row = await client.from('library_files').select('storage_provider').eq('id', id).maybeSingle();
    return row?['storage_provider'] == 'google_drive';
  }

  Future<void> approve(String id) async {
    await client
        .from('library_files')
        .update({'status': 'approved', 'rejection_reason': null})
        .eq('id', id);
  }

  Future<void> reject(String id, String reason) async {
    await client
        .from('library_files')
        .update({
          'status': 'rejected',
          'rejection_reason': reason,
        })
        .eq('id', id);
  }
}
