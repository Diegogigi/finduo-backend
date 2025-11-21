import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/auth_service.dart';
import 'invite_partner_screen.dart';
import 'add_expense_screen.dart';
import 'add_income_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = TransactionService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isDuoMode = false; // false = Individual, true = Duo
  String _error = '';

  @override
  void initState() {
    super.initState();
    // Limpiar estado completamente al inicializar
    _transactions = [];
    _isLoading = false;
    _isDuoMode = false;
    _error = '';
    // Cargar transacciones después de un delay más largo para asegurar que el token esté completamente guardado
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _loadTransactions();
      }
    });
  }

  Future<void> _loadTransactions() async {
    // Verificar que el token esté disponible antes de intentar cargar
    final authService = AuthService();
    final token = await authService.getToken();
    
    if (token == null || token.isEmpty) {
      // Si no hay token, no mostrar error, solo esperar
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '';
          _transactions = [];
        });
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
      _error = ''; // Limpiar error antes de intentar
    });
    
    try {
      final mode = _isDuoMode ? 'duo' : 'individual';
      final txs = await _service.fetchTransactions(mode: mode);
      
      // Éxito: actualizar estado con las transacciones (puede estar vacío para usuarios nuevos)
      setState(() {
        _transactions = txs;
        _error = ''; // Asegurar que no haya error
        _isLoading = false;
      });
    } catch (e) {
      // Solo mostrar error si realmente hubo un problema
      String errorMessage = e.toString();
      
      // Ignorar errores de parseo si la lista está vacía
      if (errorMessage.contains('map') && errorMessage.contains('null')) {
        // Si el error es por parseo pero la respuesta fue exitosa, solo usar lista vacía
        setState(() {
          _transactions = [];
          _error = '';
          _isLoading = false;
        });
        return;
      }
      
      // Extraer mensaje de error más claro solo para errores reales
      if (errorMessage.contains('401') || errorMessage.contains('Sesión expirada')) {
        errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
      } else if (errorMessage.contains('Timeout')) {
        errorMessage = 'La conexión está tomando demasiado tiempo. Verifica tu conexión a internet.';
      } else if (errorMessage.contains('No hay token')) {
        errorMessage = 'No hay sesión activa. Por favor, inicia sesión nuevamente.';
      } else {
        // Para otros errores, no mostrar mensaje de error visible si es un usuario nuevo
        // Solo loguear el error pero no mostrarlo en la UI
        print('Error al cargar transacciones: $errorMessage');
        setState(() {
          _transactions = [];
          _error = '';
          _isLoading = false;
        });
        return;
      }
      
      // Solo mostrar error para errores críticos de autenticación
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
      
      // Mostrar snackbar solo para errores críticos
      if (!mounted) return;
      if (errorMessage.contains('Sesión expirada') || errorMessage.contains('No hay sesión')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncNow() async {
    try {
      final mode = _isDuoMode ? 'duo' : 'individual';
      final imported = await _service.syncEmail(mode: mode);
      await _loadTransactions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Sincronizado: $imported correo(s) importado(s)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al sincronizar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  double get _balance {
    double total = 0;
    for (final t in _transactions) {
      if (t.type == 'income' || t.type == 'transfer_in') {
        total += t.amount;
      } else {
        total -= t.amount;
      }
    }
    return total;
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

  @override
  Widget build(BuildContext context) {
    final modeText = _isDuoMode ? 'Modo FinDuo (pareja)' : 'Modo Individual';

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildModeToggle(),
                    const SizedBox(height: 16),
                    _buildBalanceCard(modeText),
                    const SizedBox(height: 16),
                    _buildQuickActions(),
                    const SizedBox(height: 24),
                    Text(
                      'Movimientos recientes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_transactions.isEmpty && _error.isEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay movimientos aún',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer gasto o ingreso para comenzar',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_error.isNotEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final tx = _transactions[index];
                  return _buildTransactionTile(tx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFE3ECFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'F',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Color(0xFF2255FF),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'FinDuo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Hola, Diego 👋',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isDuoMode) {
                  setState(() => _isDuoMode = false);
                  _loadTransactions();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: !_isDuoMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    'Individual',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          !_isDuoMode ? const Color(0xFF2255FF) : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isDuoMode) {
                  setState(() => _isDuoMode = true);
                  _loadTransactions();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isDuoMode ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Center(
                  child: Text(
                    'Pareja',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          _isDuoMode ? const Color(0xFF2255FF) : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String modeText) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2255FF),
            Color(0xFF4C7DFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 8),
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modeText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Saldo disponible',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatCurrency(_balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _syncNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2255FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Sincronizar correo'),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const InvitePartnerScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    minimumSize: const Size(0, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Invitar a tu pareja',
                    style: TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _quickAction(
          icon: Icons.add_circle_outline_rounded,
          label: 'Agregar gasto',
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddExpenseScreen(
                  isDuoMode: _isDuoMode,
                ),
              ),
            );
            // Si se agregó un gasto, recargar las transacciones
            if (result == true) {
              _loadTransactions();
            }
          },
        ),
        _quickAction(
          icon: Icons.payments_outlined,
          label: 'Agregar ingreso',
          onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AddIncomeScreen(
                  isDuoMode: _isDuoMode,
                ),
              ),
            );
            // Si se agregó un ingreso, recargar las transacciones
            if (result == true) {
              _loadTransactions();
            }
          },
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4FF),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF2255FF)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isPositive =
        tx.type == 'income' || tx.type == 'transfer_in' || tx.amount < 0;
    final sign = isPositive ? '+' : '-';
    final amount = _formatCurrency(tx.amount.toDouble());

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          tx.type == 'purchase'
              ? Icons.shopping_bag_outlined
              : Icons.swap_horiz_rounded,
          color: const Color(0xFF2255FF),
        ),
      ),
      title: Text(
        tx.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${tx.dateTime.day}/${tx.dateTime.month}/${tx.dateTime.year}   ${tx.dateTime.hour.toString().padLeft(2, '0')}:${tx.dateTime.minute.toString().padLeft(2, '0')}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        '$sign$amount',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
