import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class DuoInfo {
  final String? inviteCode;
  final String? role;
  final String? name;
  final String? email;

  DuoInfo({
    this.inviteCode,
    this.role,
    this.name,
    this.email,
  });

  factory DuoInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DuoInfo();
    return DuoInfo(
      inviteCode: json['invite_code'] as String?,
      role: json['role'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
    );
  }
}

class UserInfo {
  final String name;
  final String email;
  final DuoInfo? duo;

  UserInfo({
    required this.name,
    required this.email,
    this.duo,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      name: json['name'] as String,
      email: json['email'] as String,
      duo: json['duo'] != null
          ? DuoInfo.fromJson(json['duo'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DuoService {
  final _authService = AuthService();

  Future<UserInfo> fetchMe() async {
    final token = await _authService.getToken();
    final headers = AuthService.getAuthHeaders(token);
    
    final url = Uri.parse('${ApiConfig.baseUrl}/me');
    final resp = await http.get(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Error al obtener info usuario');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return UserInfo.fromJson(data);
  }

  Future<DuoInfo> fetchDuoInfo() async {
    final userInfo = await fetchMe();
    return userInfo.duo ?? DuoInfo();
  }

  Future<String> createInvite() async {
    final token = await _authService.getToken();
    final headers = AuthService.getAuthHeaders(token);
    
    final url = Uri.parse('${ApiConfig.baseUrl}/duo/invite');
    final resp = await http.post(url, headers: headers);
    if (resp.statusCode != 200) {
      throw Exception('Error al crear invitación');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['invite_code'] as String;
  }

  Future<void> joinWithCode(String code) async {
    final token = await _authService.getToken();
    final headers = AuthService.getAuthHeaders(token);
    
    final url = Uri.parse('${ApiConfig.baseUrl}/duo/join');
    final resp = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'invite_code': code}),
    );
    if (resp.statusCode != 200) {
      throw Exception('No se pudo unir al FinDuo');
    }
  }
}
