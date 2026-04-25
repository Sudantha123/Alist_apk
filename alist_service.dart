import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/file_model.dart';
import '../models/server_config.dart';

class AlistService {
  String? _baseUrl;
  String? _token;
  final http.Client _client = http.Client();

  static final AlistService _instance = AlistService._internal();
  factory AlistService() => _instance;
  AlistService._internal();

  void configure(ServerConfig config) {
    _baseUrl = config.baseUrl.endsWith('/')
        ? config.baseUrl.substring(0, config.baseUrl.length - 1)
        : config.baseUrl;
    _token = config.token;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null && _token!.isNotEmpty) 'Authorization': _token!,
      };

  Future<String?> login(String username, String password) async {
    if (_baseUrl == null) return null;
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          _token = data['data']['token'];
          return _token;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<AlistFile>> listFiles(String path) async {
    if (_baseUrl == null) return [];
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/fs/list'),
            headers: _headers,
            body: jsonEncode({
              'path': path,
              'password': '',
              'page': 1,
              'per_page': 100,
              'refresh': false,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final content = data['data']['content'] as List?;
          return content
                  ?.map((item) => AlistFile.fromJson(item, path))
                  .toList() ??
              [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<FileDetail?> getFileInfo(String path) async {
    if (_baseUrl == null) return null;
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/api/fs/get'),
            headers: _headers,
            body: jsonEncode({'path': path, 'password': ''}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return FileDetail.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String getDownloadUrl(String path) {
    return '$_baseUrl/d$path';
  }

  String getStreamUrl(String path) {
    return '$_baseUrl/d$path';
  }

  Future<bool> testConnection(String url) async {
    try {
      final testUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final response = await http
          .get(Uri.parse('$testUrl/api/me'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 401;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
