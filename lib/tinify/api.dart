import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mime/mime.dart' as mime;
import 'package:http_parser/http_parser.dart';
import 'error.dart';
import 'result.dart';
import 'config.dart';

class TinifyClient {
  static Future<Map<String, String>> get _headers async {
    final apiKey = await Configuration.getApiKey();
    final data = utf8.encode('api:$apiKey');
    return {'Authorization': 'Basic ${base64Encode(data)}'};
  }

  static Future<Map<String, String>> get _jsonHeaders async {
    return {
      'Content-Type': 'application/json',
      ...(await _headers),
    };
  }

  /// Compressing images
  /// You can upload any WebP, JPEG or PNG image to the Tinify API to compress it.
  static Future<ImageUploadResult> upload(String imagePath) async {
    final mimeType = mime.lookupMimeType(imagePath);
    MediaType? contentType;
    if (mimeType != null) {
      contentType = MediaType.parse(mimeType);
    }
    final uploadFile = File(imagePath);
    final apiUrl = await Configuration.getBaseUrl();
    final response = await http.post(
      Uri.parse('$apiUrl/shrink'),
      headers: await _headers,
      body: await uploadFile.readAsBytes(),
    );
    _checkError(response);
    final jsonObject = jsonDecode(utf8.decode(response.bodyBytes));
    final output = jsonObject['output'];
    if (output == null || output is! Map) {
      throw ApiError('invalid response', 'unknown');
    }
    final imageUrl = output['url']?.toString() ??
        response.headers[HttpHeaders.locationHeader];
    if (imageUrl == null || imageUrl.isEmpty) {
      throw ApiError('invalid url', 'unknown');
    }
    return ImageUploadResult(
        type: output['type'] ?? contentType?.mimeType ?? '',
        size: output['size'] ??
            (await uploadFile.stat()
              ..size),
        url: imageUrl,
        width: output['width'],
        height: output['height'],
        ratio: output['ratio']);
  }

  /// Resizing images
  ///
  /// [method] scale,fit,cover,thumb
  static Future<ImageResizeResult> resize(
      String imageUrl, String method, int width, int height) async {
    final body = {
      'resize': {
        'method': method,
        'width': width,
        'height': height,
      }
    };
    final response = await http.post(
      Uri.parse(imageUrl),
      headers: await _jsonHeaders,
      body: jsonEncode(body),
    );
    _checkError(response);
    final imageWidth = response.headers['Image-Width'] ?? '0';
    final imageHeight = response.headers['Image-Height'] ?? '0';
    return ImageResizeResult(int.tryParse(imageWidth) ?? 0,
        int.tryParse(imageHeight) ?? 0, response.bodyBytes);
  }

  /// Converting images
  ///
  /// [type] webp,jpeg,png
  ///
  /// [background] [white,black] or "#000000"
  static Future<ImageConvertResult> convert(String imageUrl, String type,
      {String? background}) async {
    final body = {
      'convert': {'type': 'image/$type'},
      if (background != null) 'transform': {'background': background},
    };
    final response = await http.post(
      Uri.parse(imageUrl),
      headers: await _jsonHeaders,
      body: jsonEncode(body),
    );
    _checkError(response);
    final imageWidth = response.headers['Image-Width'] ?? '0';
    final imageHeight = response.headers['Image-Height'] ?? '0';
    return ImageConvertResult(
        int.tryParse(imageWidth) ?? 0,
        int.tryParse(imageHeight) ?? 0,
        response.bodyBytes,
        response.headers[HttpHeaders.contentTypeHeader] ?? '');
  }

  /// Download image
  static Future<ImageConvertResult> download(String imageUrl) async {
    final response =
        await http.get(Uri.parse(imageUrl), headers: await _headers);
    _checkError(response);
    final imageWidth = response.headers['Image-Width'] ?? '0';
    final imageHeight = response.headers['Image-Height'] ?? '0';
    return ImageConvertResult(
        int.tryParse(imageWidth) ?? 0,
        int.tryParse(imageHeight) ?? 0,
        response.bodyBytes,
        response.headers[HttpHeaders.contentTypeHeader] ?? '');
  }

  static void _checkError(http.BaseResponse response) {
    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.created) {
      throw ApiError(response.reasonPhrase ?? '', '${response.statusCode}');
    }
  }
}
