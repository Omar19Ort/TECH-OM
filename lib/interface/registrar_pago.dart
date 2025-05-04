import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tech_om/database/database_helper.dart';

class RegistrarPago extends StatefulWidget {
  final Map<String, dynamic> repair;

  const RegistrarPago({Key? key, required this.repair}) : super(key: key);

  @override
  _RegistrarPagoState createState() => _RegistrarPagoState();
}

class _RegistrarPagoState extends State<RegistrarPago> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _amountController;
  String _paymentMethod = 'Efectivo';
  final TextEditingController _notesController = TextEditingController();
  
  double _totalCost = 0.0;
  double _totalPaid = 0.0;
  double _remainingBalance = 0.0;
  bool _isLoading = true;
  bool _isProcessing = false;

  final List<String> _paymentMethods = [
    'Efectivo',
    'Tarjeta de crédito',
    'Tarjeta de débito',
    'Transferencia bancaria',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el costo total de la reparación
      _totalCost = widget.repair['cost'] is num ? 
          (widget.repair['cost'] as num).toDouble() : 
          double.tryParse(widget.repair['cost'].toString()) ?? 0.0;
      
      // Obtener los pagos realizados para esta reparación
      final payments = await DatabaseHelper.instance.getPaymentsByRepairId(widget.repair['id']);
      
      // Calcular el total pagado
      _totalPaid = 0.0;
      for (var payment in payments) {
        if (payment['amount'] != null) {
          _totalPaid += payment['amount'] is num ? 
              (payment['amount'] as num).toDouble() : 
              double.tryParse(payment['amount'].toString()) ?? 0.0;
        }
      }
      
      // Calcular el saldo pendiente
      _remainingBalance = _totalCost - _totalPaid;
      
      // Inicializar el controlador con el saldo pendiente
      _amountController = TextEditingController(text: _remainingBalance.toStringAsFixed(2));
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar datos de pago: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos de pago: $e')),
      );
      setState(() {
        _isLoading = false;
        // Inicializar con valores por defecto en caso de error
        _amountController = TextEditingController(text: '0.00');
      });
    }
  }

  Future<void> _registerPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    try {
      // Obtener el monto del pago
      final amount = double.parse(_amountController.text);
      
      // Preparar los datos del pago
      final payment = {
        'repair_id': widget.repair['id'],
        'amount': amount,
        'payment_method': _paymentMethod,
        'payment_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        'notes': _notesController.text,
      };
      
      // Insertar el pago
      final paymentId = await DatabaseHelper.instance.insertPayment(payment);
      
      if (paymentId > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // Retornar true para indicar que se realizó un pago
      } else {
        throw Exception('No se pudo registrar el pago');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar el pago: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Pago'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detalles de la reparación
                    Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detalles de la Reparación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Tipo de reparación', widget.repair['repairType']),
                            _buildDetailRow('Dispositivo', widget.repair['deviceType']),
                            _buildDetailRow('Marca/Modelo', '${widget.repair['brand']} ${widget.repair['model']}'),
                            const Divider(height: 24),
                            const Text(
                              'Información de Pago',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildDetailRow('Costo total', '\$${_totalCost.toStringAsFixed(2)}'),
                            _buildDetailRow('Total pagado', '\$${_totalPaid.toStringAsFixed(2)}'),
                            _buildDetailRow(
                              'Saldo pendiente', 
                              '\$${_remainingBalance.toStringAsFixed(2)}',
                              valueColor: _remainingBalance > 0 ? Colors.red : Colors.green,
                              valueFontWeight: FontWeight.bold,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Formulario de pago
                    const Text(
                      'Registrar Nuevo Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Monto a pagar
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Monto a pagar (\$)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.attach_money, color: Colors.blue),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un monto';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null) {
                          return 'Por favor ingrese un número válido';
                        }
                        if (amount <= 0) {
                          return 'El monto debe ser mayor a cero';
                        }
                        if (amount > _remainingBalance) {
                          return 'El monto no puede ser mayor al saldo pendiente';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Método de pago
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Método de pago',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.payment, color: Colors.blue),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      items: _paymentMethods.map((method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _paymentMethod = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Notas
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: const Icon(Icons.note, color: Colors.blue),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    // Botón de registro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _registerPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Registrar Pago',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, FontWeight? valueFontWeight}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: valueFontWeight ?? FontWeight.normal,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
