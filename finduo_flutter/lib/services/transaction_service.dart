import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/transaction.dart';
import 'auth_service.dart';

class TransactionService {
  final _authService = AuthService();

  Future<List<TransactionModel>> fetchTransactions({required String mode}) async {
    try {
      final token = await _authService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de autenticación. Por favor, inicia sesión nuevamente.');
      }
      
      final headers = AuthService.getAuthHeaders(token);
      
      final url = Uri.parse('${ApiConfig.baseUrl}/transactions?mode=$mode');
      print('Obteniendo transacciones: $url');
      
      final resp = await http.get(url, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La operación está tomando demasiado tiempo');
        },
      );

      print('Respuesta del servidor: ${resp.statusCode}');
      print('Body: ${resp.body}');

      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        return data
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (resp.statusCode == 401) {
        throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
      } else {
        final errorDetail = resp.body.isNotEmpty ? '${resp.body}' : 'Error desconocido';
        throw Exception('Error al obtener movimientos (${resp.statusCode}): $errorDetail');
      }
    } catch (e) {
      print('Error en fetchTransactions: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTransaction({
    required String type,
    required String description,
    required int amount,
    required DateTime dateTime,
    required String mode,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/transactions');
      print('Creando transacción: $url');
      
      final body = jsonEncode({
        'type': type,
        'description': description,
        'amount': amount,
        'date_time': dateTime.toUtc().toIso8601String(),
        'mode': mode,
      });
      
      print('Body: $body');
      
      final token = await _authService.getToken();
      final headers = AuthService.getAuthHeaders(token);
      
      final resp = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La operación está tomando demasiado tiempo');
        },
      );
      
      print('Respuesta del servidor: ${resp.statusCode}');
      print('Body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        print('Transacción creada exitosamente: ${data['id']}');
        return data;
      } else {
        throw Exception('Error al crear transacción (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      print('Error en createTransaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction({
    required int id,
    required String type,
    required String description,
    required int amount,
    required DateTime dateTime,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/transactions/$id');
      print('Actualizando transacción: $url');
      
      final body = jsonEncode({
        'type': type,
        'description': description,
        'amount': amount,
        'date_time': dateTime.toUtc().toIso8601String(),
      });
      
      final token = await _authService.getToken();
      final headers = AuthService.getAuthHeaders(token);
      
      final resp = await http.put(
        url,
        headers: headers,
        body: body,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La operación está tomando demasiado tiempo');
        },
      );
      
      if (resp.statusCode == 200) {
        print('Transacción actualizada exitosamente');
      } else {
        throw Exception('Error al actualizar transacción (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      print('Error en updateTransaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction({required int id}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/transactions/$id');
      print('Eliminando transacción: $url');
      
      final token = await _authService.getToken();
      final headers = AuthService.getAuthHeaders(token);
      
      final resp = await http.delete(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout: La operación está tomando demasiado tiempo');
        },
      );
      
      if (resp.statusCode == 200) {
        print('Transacción eliminada exitosamente');
      } else {
        throw Exception('Error al eliminar transacción (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      print('Error en deleteTransaction: $e');
      rethrow;
    }
  }

  Future<int> syncEmail({required String mode}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/sync-email');
      print('Sincronizando correo: $url');
      
      final token = await _authService.getToken();
      final headers = AuthService.getAuthHeaders(token);
      
      final resp = await http.post(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout: La sincronización está tomando demasiado tiempo');
        },
      );
      
      print('Respuesta del servidor: ${resp.statusCode}');
      print('Body: ${resp.body}');
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final imported = data['imported'] as int;
        print('Sincronización exitosa. Importados: $imported');
        return imported;
      } else {
        throw Exception('Error al sincronizar correo (${resp.statusCode}): ${resp.body}');
      }
    } catch (e) {
      print('Error en syncEmail: $e');
      rethrow;
    }
  }
}
