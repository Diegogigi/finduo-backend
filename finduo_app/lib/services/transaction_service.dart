import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/transaction.dart';

class TransactionService {
  Future<List<TransactionModel>> fetchTransactions({required String mode}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/transactions?mode=$mode');
    final resp = await http.get(url);

    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al obtener movimientos (${resp.statusCode})');
    }
  }

  Future<int> syncEmail({required String mode}) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/sync-email');
      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Timeout: La sincronización está tomando demasiado tiempo');
        },
      );
      
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final imported = data['imported'] as int;
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
