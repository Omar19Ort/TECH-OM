import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tech_om/database/database_helper.dart';

class HistorialPagos extends StatefulWidget {
  final int? repairId; // Si se proporciona, muestra solo los pagos de una reparación específica

  const HistorialPagos({Key? key, this.repairId}) : super(key: key);

  @override
  _HistorialPagosState createState() => _HistorialPagosState();
}

class _HistorialPagosState extends State<HistorialPagos> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> payments;
      
      if (widget.repairId != null) {
        // Cargar pagos de una reparación específica
        payments = await DatabaseHelper.instance.getPaymentsByRepairId(widget.repairId!);
      } else {
        // Cargar todos los pagos
        payments = await DatabaseHelper.instance.getAllPayments();
      }
      
      // Calcular el monto total
      double total = 0.0;
      for (var payment in payments) {
        if (payment['amount'] != null) {
          total += payment['amount'] is num ? 
              (payment['amount'] as num).toDouble() : 
              double.tryParse(payment['amount'].toString()) ?? 0.0;
        }
      }
      
      setState(() {
        _payments = payments;
        _totalAmount = total;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar pagos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar pagos: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repairId != null ? 'Pagos de la Reparación' : 'Historial de Pagos'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Resumen de pagos
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total de pagos: ${_payments.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Monto total: \$${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de pagos
                Expanded(
                  child: _payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payment_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay pagos registrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Icon(
                                    _getPaymentMethodIcon(payment['payment_method']),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      payment['payment_method'] ?? 'Método desconocido',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '\$${payment['amount'] is num ? (payment['amount'] as num).toStringAsFixed(2) : '0.00'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Fecha: ${_formatDate(payment['payment_date'] ?? '')}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (payment['notes'] != null && payment['notes'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Notas: ${payment['notes']}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  IconData _getPaymentMethodIcon(String? method) {
    switch (method) {
      case 'Efectivo':
        return Icons.money;
      case 'Tarjeta de crédito':
        return Icons.credit_card;
      case 'Tarjeta de débito':
        return Icons.credit_card;
      case 'Transferencia bancaria':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}
