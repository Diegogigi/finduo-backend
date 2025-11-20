import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/transaction_service.dart';

class AddIncomeScreen extends StatefulWidget {
  final bool isDuoMode;
  
  const AddIncomeScreen({
    super.key,
    this.isDuoMode = false,
  });

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _service = TransactionService();
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'income'; // 'income' o 'transfer_in'

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _formatCurrency(String value) {
    // Remover puntos y formatear
    final cleanValue = value.replaceAll('.', '');
    if (cleanValue.isEmpty) return '';
    
    final intValue = int.tryParse(cleanValue);
    if (intValue == null) return '';
    
    final formatted = intValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return formatted;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = int.parse(_amountController.text.replaceAll('.', ''));
      final description = _descriptionController.text.trim();
      
      await _service.createTransaction(
        type: _selectedType,
        description: description,
        amount: amount,
        dateTime: _selectedDate,
        mode: widget.isDuoMode ? 'duo' : 'individual',
      );

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Ingreso agregado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Regresar a la pantalla anterior
      Navigator.of(context).pop(true); // true indica que se agregó un ingreso
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al agregar ingreso: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Ingreso'),
        backgroundColor: const Color(0xFF2255FF),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              
              // Selector de tipo de ingreso
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Tipo de ingreso',
                  prefixIcon: const Icon(Icons.category_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'income',
                    child: Text('Ingreso'),
                  ),
                  DropdownMenuItem(
                    value: 'transfer_in',
                    child: Text('Transferencia recibida'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              
              const SizedBox(height: 20),
              
              // Campo de descripción
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: _selectedType == 'income' 
                      ? 'Ej: Salario, Venta, etc.'
                      : 'Ej: Transferencia de...',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Campo de monto
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Monto',
                  hintText: '0',
                  prefixIcon: const Icon(Icons.attach_money),
                  suffixText: 'CLP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    if (newValue.text.isEmpty) {
                      return newValue;
                    }
                    final formatted = _formatCurrency(newValue.text);
                    return TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa un monto';
                  }
                  final cleanValue = value.replaceAll('.', '');
                  final amount = int.tryParse(cleanValue);
                  if (amount == null || amount <= 0) {
                    return 'Por favor ingresa un monto válido';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 20),
              
              // Selector de fecha
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Fecha',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botón de guardar
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2255FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Agregar Ingreso',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

