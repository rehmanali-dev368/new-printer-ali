import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

class DocConvertApi {
  static const _endpoint = 'https://www.techtools.ink/all_doc_convert';

  static Future<Uint8List> convert({
    required String filePath,
    required String targetFormat,
  }) async {
    final source = File(filePath);
    if (!await source.exists()) {
      throw Exception('Selected file not found.');
    }

    try {
      final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
      request.fields['target_format'] = targetFormat.trim().toLowerCase();
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: p.basename(filePath),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 120));
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        throw Exception(
          body.trim().isEmpty
              ? 'Conversion failed (${streamed.statusCode}).'
              : body.trim(),
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw Exception('Invalid response from conversion server.');
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['status'] != true) {
        throw Exception(map['message']?.toString() ?? 'Conversion failed.');
      }
      final downloadUrl = map['download_url']?.toString().trim() ?? '';
      if (downloadUrl.isEmpty) {
        throw Exception('Conversion finished without a file.');
      }

      final response = await http
          .get(Uri.parse(downloadUrl))
          .timeout(const Duration(seconds: 120));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Could not download the converted file.');
      }
      if (response.bodyBytes.isEmpty) {
        throw Exception('Downloaded file is empty.');
      }
      return response.bodyBytes;
    } on SocketException {
      throw Exception('No internet connection. Please try again.');
    }
  }
}
