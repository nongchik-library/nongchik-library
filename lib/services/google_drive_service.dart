
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
  defaultValue: '',
);

/// Google Drive gateway used by the app.
class GoogleDriveService {
  final SupabaseClient client = Supabase.instance.client;

  Future<Map<String, dynamic>> upload({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    String? folderId,
    String? folderName,
    String? category,
    String? subdistrict,
  }) async {
    final response = await client.functions.invoke(
      'drive-upload',
      body: {
        'file_name': fileName,
        'mime_type': mimeType,
        'folder_id': folderId,
        'folder_name': folderName,
        'category': category,
        'subdistrict': subdistrict,
        'title': fileName,
        'description': '',
        'file_type': _fileTypeFromMime(mimeType),
        'file_size': bytes.length,
        'content_base64': base64Encode(bytes),
      },
    );

    final data = response.data;
    if (data is! Map) {
      throw Exception('Google Drive ตอบกลับไม่ถูกต้อง');
    }
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }

    return Map<String, dynamic>.from(data);
  }

  String _fileTypeFromMime(String mime) {
    if (mime.startsWith('image/')) return 'image';
    if (mime == 'application/pdf') return 'pdf';
    return 'document';
  }

  String viewUrl(String fileId) =>
      'https://drive.google.com/uc?export=view&id=${Uri.encodeComponent(fileId)}';

  // Read images through the secured Supabase Edge Function.
  String imageUrl(String fileId, {bool thumbnail = true}) {
    const baseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://ddldegnsupfeqfzbjjcr.supabase.co',
    );

    final query =
        'file_id=${Uri.encodeQueryComponent(fileId)}'
        '&thumb=${thumbnail ? '1' : '0'}';

    return '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/functions/v1/drive-image?$query';
  }

  Map<String, String> get imageHeaders {
    final token = client.auth.currentSession?.accessToken;

    return {
      'apikey': _supabasePublishableKey,
      'Authorization':
          'Bearer ${token ?? _supabasePublishableKey}',
    };
  }

  String downloadUrl(String fileId) =>
      'https://drive.google.com/uc?export=download&id=${Uri.encodeComponent(fileId)}';
}
