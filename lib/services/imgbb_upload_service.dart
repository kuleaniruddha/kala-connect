import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Service to upload product and artisan images to ImgBB cloud storage
/// using the provided API key (482424c79135f8ee4607c86bc95c7b98).
/// Returns a permanent, universally accessible public HTTPS image URL.
class ImgbbUploadService {
  ImgbbUploadService({String? apiKey})
      : _apiKey = apiKey ?? '482424c79135f8ee4607c86bc95c7b98';

  final String _apiKey;

  /// Uploads a local image file to ImgBB and returns the public HTTPS URL.
  /// If the upload fails or file does not exist, returns `null` without throwing.
  Future<String?> uploadImageFile(File file) async {
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      final filename = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      return await uploadImageBytes(bytes, filename: filename);
    } catch (e) {
      debugPrint('[ImgbbUploadService] Error reading file: $e');
      return null;
    }
  }

  /// Uploads raw image bytes via multipart/form-data to ImgBB API.
  Future<String?> uploadImageBytes(List<int> bytes, {String filename = 'product.jpg'}) async {
    HttpClient? client;
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey');
      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      final request = await client.postUrl(uri);
      final boundary = '----KalaConnect${DateTime.now().millisecondsSinceEpoch}';

      request.headers.set(HttpHeaders.contentTypeHeader, 'multipart/form-data; boundary=$boundary');
      request.headers.set(HttpHeaders.userAgentHeader, 'KalaConnectApp/1.0');

      final body = <int>[];

      // Form field: image
      body.addAll(utf8.encode('--$boundary\r\n'));
      body.addAll(utf8.encode('Content-Disposition: form-data; name="image"; filename="$filename"\r\n'));
      body.addAll(utf8.encode('Content-Type: image/jpeg\r\n\r\n'));
      body.addAll(bytes);
      body.addAll(utf8.encode('\r\n'));

      // End boundary
      body.addAll(utf8.encode('--$boundary--\r\n'));

      request.contentLength = body.length;
      request.add(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final decoded = jsonDecode(responseBody) as Map<String, dynamic>;
        if (decoded['success'] == true && decoded['data'] != null) {
          final data = decoded['data'] as Map<String, dynamic>;
          final url = data['url'] as String? ?? data['display_url'] as String?;
          if (url != null && url.startsWith('http')) {
            debugPrint('✨ [ImgbbUploadService] Successfully uploaded to: $url');
            return url;
          }
        }
      }

      debugPrint('[ImgbbUploadService] Upload returned ${response.statusCode}: $responseBody');
      return null;
    } catch (e) {
      debugPrint('[ImgbbUploadService] Network/Upload error: $e');
      return null;
    } finally {
      client?.close();
    }
  }
}
