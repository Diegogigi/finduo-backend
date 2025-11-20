import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import 'edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _service = TransactionService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isDuoMode = false;
  String _filterType = 'all';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTx();
  }

  Future<void> _loadTx() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final mode = _isDuoMode ? 'duo' : 'individual';
      final txs = await _service.fetchTransactions(mode: mode);
      setState(() => _transactions = txs);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<TransactionModel> get _filteredTx {
    return _transactions.where((t) {
      if (_filterType == 'income') {
        return t.type == 'income' || t.type == 'transfer_in';
      } else if (_filterType == 'expense') {
        return !(t.type == 'income' || t.type == 'transfer_in');
      }
      return true;
    }).toList();
  }

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final r = s.length - i;
      buffer.write(s[i]);
      if (r > 1 && r % 3 == 1) {
        buffer.write('.');
      }
    }
    return '\$${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTx,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Text(
                    'Movimientos',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _loadTx,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Individual'),
                    selected: !_isDuoMode,
                    onSelected: (v) {
                      if (v) {
                        setState(() => _isDuoMode = false);
                        _loadTx();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Pareja'),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _filterChip('Todos', 'all'),
                  const SizedBox(width: 8),
                  _filterChip('Ingresos', 'income'),
                  const SizedBox(width: 8),
                  _filterChip('Gastos', 'expense'),
                ],
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _filteredTx.length,
                      itemBuilder: (context, index) {
                        final tx = _filteredTx[index];
                        final isPositive =
                            tx.type == 'income' || tx.type == 'transfer_in';
                        return _buildSwipeableTransaction(tx, isPositive, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _filterType = value);
      },
    );
  }

  Widget _buildSwipeableTransaction(TransactionModel tx, bool isPositive, int index) {
    return Dismissible(
      key: Key('transaction_${tx.id}_$index'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2255FF),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_outlined, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(width: 20),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 20),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 28),
                SizedBox(height: 4),
                Text(
                  'Eliminar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Deslizar hacia la derecha = Editar (no necesita confirmación)
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => EditTransactionScreen(transaction: tx),
            ),
          ).then((result) {
            if (result == true) {
              _loadTx();
            }
          });
          return false; // No eliminar el item, solo abrir edición
        } else if (direction == DismissDirection.endToStart) {
          // Deslizar hacia la izquierda = Eliminar (necesita confirmación)
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Eliminar movimiento'),
              content: const Text('¿Estás seguro de que quieres eliminar este movimiento?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Eliminar'),
                ),
              ],
            ),
          );
          return confirmed ?? false;
        }
        return false;
      },
      onDismissed: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Eliminar transacción
          await _deleteTransaction(tx);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            // Al tocar, editar
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => EditTransactionScreen(transaction: tx),
              ),
            );
            if (result == true) {
              _loadTx();
            }
          },
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                tx.type == 'purchase'
                    ? Icons.shopping_bag_outlined
                    : tx.type == 'income' || tx.type == 'transfer_in'
                        ? Icons.payments_outlined
                        : Icons.swap_horiz_rounded,
                color: const Color(0xFF2255FF),
                size: 20,
              ),
            ),
            title: Text(
              tx.description,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year}   ${tx.dateTime.hour.toString().padLeft(2, '0')}:${tx.dateTime.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isPositive ? '+' : '-'}${_formatCurrency(tx.amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.grey,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(TransactionModel tx) async {
    try {
      await _service.deleteTransaction(id: tx.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Movimiento eliminado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Recargar transacciones
      _loadTx();
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar movimiento: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}
