// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> gerarRoteiro({
    required String tema,
    required String formato,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gerar-roteiro'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tema': tema, 'formato': formato}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro ao gerar roteiro: ${response.body}');
  }

  static Future<Map<String, dynamic>> gerarVideo({
    required String jobId,
    required List slides,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/gerar-video'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'job_id': jobId, 'slides': slides}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro ao iniciar vídeo: ${response.body}');
  }

  static Future<Map<String, dynamic>> verificarStatus(String jobId) async {
    final response = await http.get(Uri.parse('$baseUrl/status/$jobId'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro ao verificar status: ${response.body}');
  }

  static String urlDownload(String jobId) => '$baseUrl/video/$jobId';

  // ── Studio ──

  static Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro GET $path: ${response.body}');
  }

  static Future<Map<String, dynamic>> post(
      String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro POST $path: ${response.body}');
  }

  static Future<Map<String, dynamic>> patch(
      String path, Map<String, dynamic> body) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro PATCH $path: ${response.body}');
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final response = await http.delete(Uri.parse('$baseUrl$path'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erro DELETE $path: ${response.body}');
  }
}