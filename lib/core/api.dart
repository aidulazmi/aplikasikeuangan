import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiError implements Exception {
  final String message;
  final int code;
  ApiError(this.message, [this.code = 0]);
  @override
  String toString() => message;
}

class Api {
  // 10.0.2.2 = localhost dari emulator Android. Ubah lewat menu "Server" di aplikasi.
  static String base = 'http://192.168.8.116/dompetku-php';
  static String? token;

  static Map<String, String> get _h => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<T> _run<T>(Future<T> Function() f) async {
    try {
      return await f().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw ApiError('Tidak dapat terhubung ke server. Periksa alamat server & koneksi.');
    } on TimeoutException {
      throw ApiError('Server tidak merespons. Coba lagi.');
    } on http.ClientException {
      throw ApiError('Tidak dapat terhubung ke server.');
    }
  }

  static dynamic _parse(http.Response r) {
    dynamic body;
    try {
      body = r.body.isEmpty ? null : jsonDecode(r.body);
    } catch (_) {}
    if (r.statusCode >= 400) {
      throw ApiError((body is Map ? body['error'] : null) ?? 'Gagal (${r.statusCode})', r.statusCode);
    }
    return body;
  }

  static Future<dynamic> get(String p) => _run(() async => _parse(await http.get(Uri.parse('$base$p'), headers: _h)));
  static Future<dynamic> post(String p, Map b) =>
      _run(() async => _parse(await http.post(Uri.parse('$base$p'), headers: _h, body: jsonEncode(b))));
  static Future<dynamic> put(String p, Map b) =>
      _run(() async => _parse(await http.put(Uri.parse('$base$p'), headers: _h, body: jsonEncode(b))));
  static Future<dynamic> delete(String p) => _run(() async => _parse(await http.delete(Uri.parse('$base$p'), headers: _h)));

  static Future<String> getText(String p) => _run(() async {
        final r = await http.get(Uri.parse('$base$p'), headers: _h);
        if (r.statusCode >= 400) throw ApiError('Gagal mengunduh (${r.statusCode})', r.statusCode);
        return utf8.decode(r.bodyBytes);
      });

  static Future<dynamic> multipart(String method, String p, Map<String, String> fields, File? file) => _run(() async {
        final req = http.MultipartRequest(method, Uri.parse('$base$p'));
        if (token != null) req.headers['Authorization'] = 'Bearer $token';
        req.fields.addAll(fields);
        if (file != null) req.files.add(await http.MultipartFile.fromPath('receipt', file.path));
        return _parse(await http.Response.fromStream(await req.send()));
      });
}
