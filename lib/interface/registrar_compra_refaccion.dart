import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/spare_parts_db.dart';

class Purchase {
  final int? id;
  final int refaccionId;
  final double precio;
  final String fecha;

  Purchase({
    this.id,
    required this.refaccionId,
    required this.precio,
    required this.fecha,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'refaccionId': refaccionId,
      'precio': precio,
      'fecha': fecha,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      refaccionId: map['refaccionId'],
      precio: map['precio'],
      fecha: map['fecha'],
    );
  }
}

class RegistrarCompraRefaccion extends StatefulWidget {
  const RegistrarCompraRefaccion({Key? key}) : super(key: key);

  @override
  State<RegistrarCompraRefaccion> createState() => _RegistrarCompraRefaccionState();
}

class _RegistrarCompraRefaccionState extends State<RegistrarCompraRefaccion> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedRefaccionId;
  double? _precio;
  DateTime _fecha = DateTime.now();

  List<Map<String, dynamic>> _refacciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarRefacciones();
  }

  Future<void> _cargarRefacciones() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final refacciones = await SparePartsDB.instance.getAllSpareParts();
      setState(() {
        _refacciones = refacciones;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar refacciones: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar refacciones: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarCompra() async {
    if (_formKey.currentState!.validate() && _selectedRefaccionId != null) {
      _formKey.currentState!.save();

      try {
        final compra = Purchase(
          refaccionId: _selectedRefaccionId!,
          precio: _precio!,
          fecha: DateFormat('yyyy-MM-dd').format(_fecha),
        );

        await SparePartsDB.instance.insertPurchase(compra.toMap());

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compra registrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        print('Error al guardar compra: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar compra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar Compra de Refacción',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF9DC0B0),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _refacciones.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No hay refacciones disponibles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Agrega refacciones en el catálogo primero',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de la Compra',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF9DC0B0),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Selector de refacción
                        Text(
                          'Refacción',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<int>(
                            value: _selectedRefaccionId,
                            items: _refacciones.map((ref) {
                              return DropdownMenuItem<int>(
                                value: ref['id'],
                                child: Text(
                                  '${ref['partType']} - ${ref['brand']} ${ref['model']}',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              labelText: 'Selecciona una refacción',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _selectedRefaccionId = value;
                                
                                // Autocompletar el precio con el precio actual de la refacción
                                if (value != null) {
                                  final refaccion = _refacciones.firstWhere(
                                    (ref) => ref['id'] == value,
                                    orElse: () => {},
                                  );
                                  if (refaccion.isNotEmpty && refaccion['price'] != null) {
                                    _precio = refaccion['price'] is num ? 
                                        (refaccion['price'] as num).toDouble() : null;
                                  }
                                }
                              });
                            },
                            validator: (value) => value == null ? 'Selecciona una refacción' : null,
                            dropdownColor: isDarkMode ? Colors.grey[800] : Colors.white,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: const Color(0xFF9DC0B0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Campo de precio
                        Text(
                          'Precio de Compra',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _precio?.toString() ?? '',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Precio de compra',
                            hintText: 'Ej: 1500.00',
                            prefixIcon: Icon(Icons.attach_money, color: const Color(0xFF9DC0B0)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: const Color(0xFF9DC0B0), width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 12 : 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Ingresa un precio';
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed <= 0) return 'Precio inválido';
                            return null;
                          },
                          onSaved: (value) => _precio = double.parse(value!),
                          onChanged: (value) {
                            _precio = double.tryParse(value);
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Selector de fecha
                        Text(
                          'Fecha de Compra',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: const Color(0xFF9DC0B0),
                                size: isSmallScreen ? 20 : 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  DateFormat('dd/MM/yyyy').format(_fecha),
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 14 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: _fecha,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: const Color(0xFF9DC0B0),
                                            onPrimary: Colors.white,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _fecha = picked;
                                    });
                                  }
                                },
                                child: Text(
                                  'Cambiar',
                                  style: TextStyle(
                                    color: const Color(0xFF9DC0B0),
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Botón de guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardarCompra,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9DC0B0),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 14 : 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Guardar Compra',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
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