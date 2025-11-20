import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _service = TransactionService();
  List<TransactionModel> _txs = [];
  bool _isLoading = false;
  bool _isDuoMode = false;
  String _selectedPeriod = 'all'; // 'all', 'month', 'week'

  @override
  void initState() {
    super.initState();
    _loadTx();
  }

  Future<void> _loadTx() async {
    setState(() => _isLoading = true);
    try {
      final mode = _isDuoMode ? 'duo' : 'individual';
      final data = await _service.fetchTransactions(mode: mode);
      setState(() {
        _txs = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  List<TransactionModel> get _filteredTxs {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return _txs.where((t) => t.dateTime.isAfter(weekAgo)).toList();
      case 'month':
        final monthAgo = DateTime(now.year, now.month - 1, now.day);
        return _txs.where((t) => t.dateTime.isAfter(monthAgo)).toList();
      default:
        return _txs;
    }
  }

  double get totalExpenses {
    final filtered = _filteredTxs;
    return filtered
        .where((t) => t.type != 'income' && t.type != 'transfer_in')
        .fold(0.0, (p, e) => p + e.amount);
  }

  double get totalIncome {
    final filtered = _filteredTxs;
    return filtered
        .where((t) => t.type == 'income' || t.type == 'transfer_in')
        .fold(0.0, (p, e) => p + e.amount);
  }

  double get balance => totalIncome - totalExpenses;

  double get averageExpense {
    final expenses = _filteredTxs
        .where((t) => t.type != 'income' && t.type != 'transfer_in')
        .toList();
    if (expenses.isEmpty) return 0;
    return totalExpenses / expenses.length;
  }

  Map<String, double> _expensesByCategory() {
    final Map<String, double> map = {};
    for (final t in _filteredTxs) {
      if (t.type == 'income' || t.type == 'transfer_in') continue;
      // Usar la descripción como categoría (simplificado)
      final category = _getCategory(t.description);
      map[category] = (map[category] ?? 0) + t.amount;
    }
    return map;
  }

  String _getCategory(String description) {
    final desc = description.toLowerCase();
    if (desc.contains('super') || desc.contains('mercado') || desc.contains('comida')) {
      return 'Alimentos';
    } else if (desc.contains('transporte') || desc.contains('uber') || desc.contains('taxi')) {
      return 'Transporte';
    } else if (desc.contains('servicio') || desc.contains('luz') || desc.contains('agua') || desc.contains('internet')) {
      return 'Servicios';
    } else if (desc.contains('compra') || desc.contains('tienda') || desc.contains('shopping')) {
      return 'Compras';
    } else {
      return 'Otros';
    }
  }

  Map<int, double> _expensesByMonth() {
    final Map<int, double> map = {};
    for (final t in _filteredTxs) {
      if (t.type == 'income' || t.type == 'transfer_in') continue;
      final month = t.dateTime.month;
      map[month] = (map[month] ?? 0) + t.amount;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final expByMonth = _expensesByMonth();
    final expByCategory = _expensesByCategory();
    final monthNames = ['', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTx,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con selector de modo y período
                    Row(
                      children: [
                        const Text(
                          'Resumen Financiero',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        ChoiceChip(
                          label: const Text('Ind'),
                          selected: !_isDuoMode,
                          onSelected: (v) {
                            if (v) {
                              setState(() => _isDuoMode = false);
                              _loadTx();
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Duo'),
                          selected: _isDuoMode,
                          onSelected: (v) {
                            if (v) {
                              setState(() => _isDuoMode = true);
                              _loadTx();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Selector de período
                    Row(
                      children: [
                        _periodChip('Todo', 'all'),
                        const SizedBox(width: 8),
                        _periodChip('Mes', 'month'),
                        const SizedBox(width: 8),
                        _periodChip('Semana', 'week'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Balance neto
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: balance >= 0
                              ? [const Color(0xFF10B981), const Color(0xFF059669)]
                              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (balance >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Balance Neto',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatCurrency(balance),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Tarjetas de resumen
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            label: 'Ingresos',
                            amount: totalIncome,
                            color: Colors.green,
                            icon: Icons.trending_up_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCard(
                            label: 'Gastos',
                            amount: totalExpenses,
                            color: Colors.red,
                            icon: Icons.trending_down_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Promedio de gastos
                    if (averageExpense > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F8FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate_outlined, color: Color(0xFF2255FF)),
                                SizedBox(width: 8),
                                Text(
                                  'Promedio por gasto',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              _formatCurrency(averageExpense),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2255FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Gráfico de gastos por mes
                    if (expByMonth.isNotEmpty) ...[
                      const Text(
                        'Gastos por Mes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: expByMonth.values.isEmpty
                                ? 100
                                : (expByMonth.values.reduce((a, b) => a > b ? a : b) * 1.2),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.black87,
                                tooltipRoundedRadius: 8,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('');
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        '${(value / 1000).toStringAsFixed(0)}k',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final month = value.toInt();
                                    if (month < 1 || month > 12) return const Text('');
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        monthNames[month],
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: expByMonth.values.isEmpty
                                  ? 10000
                                  : (expByMonth.values.reduce((a, b) => a > b ? a : b) / 4),
                            ),
                            barGroups: expByMonth.entries
                                .map(
                                  (e) => BarChartGroupData(
                                    x: e.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: e.value,
                                        width: 20,
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4),
                                        ),
                                        color: const Color(0xFF2255FF),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Gastos por categoría
                    if (expByCategory.isNotEmpty) ...[
                      const Text(
                        'Gastos por Categoría',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...expByCategory.entries.map((entry) {
                        final total = expByCategory.values.reduce((a, b) => a + b);
                        final percentage = (entry.value / total * 100);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percentage / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getCategoryColor(entry.key),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatCurrency(entry.value),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    
                    // Mensaje si no hay datos
                    if (_filteredTxs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Center(
                          child: Text(
                            'No hay transacciones para mostrar.\nAgrega gastos o ingresos para ver estadísticas.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _periodChip(String label, String value) {
    final selected = _selectedPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) {
        if (v) {
          setState(() => _selectedPeriod = value);
        }
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Alimentos':
        return Colors.orange;
      case 'Transporte':
        return Colors.blue;
      case 'Servicios':
        return Colors.purple;
      case 'Compras':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(double value) {
    final intVal = value.toInt();
    final s = intVal.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final reversedIndex = s.length - i;
      buffer.write(s[i]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '\$${buffer.toString()}';
  }

  Widget _summaryCard({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
