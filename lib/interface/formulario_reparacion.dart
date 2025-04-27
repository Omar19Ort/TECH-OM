import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tech_om/database/database_helper.dart';
import 'package:tech_om/database/spare_parts_db.dart';
// Corregir la importación para que coincida con la ubicación real del archivo
import 'seleccion_dispositivo.dart';

class FormularioReparacion extends StatefulWidget {
  final String tipoReparacion;
  final String tipoDispositivo;

  const FormularioReparacion({
    Key? key,
    required this.tipoReparacion,
    required this.tipoDispositivo,
  }) : super(key: key);

  @override
  _FormularioReparacionState createState() => _FormularioReparacionState();
}

class _FormularioReparacionState extends State<FormularioReparacion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _marcaController = TextEditingController();
  final TextEditingController _modeloController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _costoController = TextEditingController(text: '0.00');
  final TextEditingController _manodeObraController = TextEditingController(text: '0.00');
  
  File? _imagen;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isLoadingParts = true;
  
  // Variables para refacciones
  List<Map<String, dynamic>> _spareParts = [];
  Map<String, dynamic>? _selectedSparePart;
  double _laborCost = 0.0;
  double _partCost = 0.0;
  double _totalCost = 0.0;

  // Colores del tema
  late Color primaryColor;
  late Color secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Configurar colores basados en el tema actual
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = const Color(0xFF43A047);
    secondaryColor = const Color(0xFF1B5E20);
  }

  Future<void> _loadSpareParts() async {
    setState(() {
      _isLoadingParts = true;
    });

    try {
      // Cargar refacciones que coincidan con el tipo de dispositivo y tipo de reparación
      final spareParts = await SparePartsDB.instance.getSparePartsByDeviceType(widget.tipoDispositivo);
      
      // Filtrar por tipo de reparación si es necesario
      List<Map<String, dynamic>> filteredParts = spareParts;
      if (widget.tipoReparacion.isNotEmpty && widget.tipoReparacion != 'Todas') {
        filteredParts = spareParts.where((part) {
          return part['partType'].toString().toLowerCase().contains(widget.tipoReparacion.toLowerCase()) ||
                widget.tipoReparacion.toLowerCase().contains(part['partType'].toString().toLowerCase());
        }).toList();
      }
      
      setState(() {
        _spareParts = filteredParts;
        _isLoadingParts = false;
      });
    } catch (e) {
      print('Error al cargar refacciones: $e');
      setState(() {
        _isLoadingParts = false;
        _spareParts = []; // Asegurar que sea una lista vacía en caso de error
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    try {
      final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
      if (imagen != null) {
        setState(() {
          _imagen = File(imagen.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectSparePart(Map<String, dynamic> sparePart) {
    setState(() {
      _selectedSparePart = sparePart;
      // Actualizar los controladores con la información de la refacción
      _marcaController.text = sparePart['brand'] ?? '';
      _modeloController.text = sparePart['model'] ?? '';
      
      // Actualizar el costo
      if (sparePart['price'] is num) {
        _costoController.text = sparePart['price'].toString();
        _partCost = (sparePart['price'] as num).toDouble();
      } else if (sparePart['price'] is String) {
        _costoController.text = sparePart['price'];
        _partCost = double.tryParse(sparePart['price']) ?? 0.0;
      } else {
        _costoController.text = '0.00';
        _partCost = 0.0;
      }
    });
    _calculateTotal();
  }

  void _updateLaborCost(String value) {
    setState(() {
      _laborCost = double.tryParse(value) ?? 0.0;
    });
    _calculateTotal();
  }

  void _updatePartCost(String value) {
    setState(() {
      _partCost = double.tryParse(value) ?? 0.0;
    });
    _calculateTotal();
  }

  void _calculateTotal() {
    setState(() {
      _totalCost = _partCost + _laborCost;
    });
  }

  Future<void> _enviarCotizacion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Obtener el ID del usuario actual o usar 1 como valor predeterminado
      int userId;
      try {
        // Intentar obtener el ID del usuario actual
        userId = DatabaseHelper.getCurrentUserId() ?? 1;
      } catch (e) {
        // Si hay un error, usar 1 como valor predeterminado
        print('Error al obtener el ID del usuario: $e');
        userId = 1;
      }
      
      // Asegurar que los costos sean números válidos
      _partCost = double.tryParse(_costoController.text) ?? 0.0;
      _laborCost = double.tryParse(_manodeObraController.text) ?? 0.0;
      _totalCost = _partCost + _laborCost;
      
      final newRepair = {
        'userId': userId,
        'deviceType': widget.tipoDispositivo,
        'repairType': widget.tipoReparacion,
        'brand': _marcaController.text,
        'model': _modeloController.text,
        'description': _descripcionController.text,
        'cost': _totalCost,
        'laborCost': _laborCost,
        'partCost': _partCost,
        'sparePartId': _selectedSparePart != null ? _selectedSparePart!['id'] : null,
        'imageUrl': _imagen?.path ?? '',
        'paymentStatus': 'pendiente', // Estado de pago inicial: pendiente
        'createdAt': DateTime.now().toIso8601String(),
      };

      final id = await DatabaseHelper.instance.insertRepair(newRepair);

      if (id > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cotización enviada exitosamente'),
            backgroundColor: Color(0xFF43A047),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SeleccionDispositivo()),
          (Route<dynamic> route) => false,
        );
      } else {
        throw Exception('No se pudo insertar la reparación');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar la cotización: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cotización Rápida',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reparación: ${widget.tipoReparacion}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Sección de selección de refacción
                    _buildSectionTitle('Seleccionar Refacción'),
                    const SizedBox(height: 16),
                    
                    // Lista de refacciones disponibles
                    if (_isLoadingParts)
                      Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else if (_spareParts.isEmpty)
                      _buildEmptyPartsMessage()
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _spareParts.length,
                          itemBuilder: (context, index) {
                            final part = _spareParts[index];
                            final bool isSelected = _selectedSparePart != null && 
                                                   _selectedSparePart!['id'] == part['id'];
                            
                            return _buildSparePartItem(part, isSelected);
                          },
                        ),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Información del dispositivo
                    _buildSectionTitle('Información del Dispositivo'),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _marcaController,
                      label: 'Marca del dispositivo',
                      icon: Icons.devices,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _modeloController,
                      label: 'Modelo',
                      icon: Icons.phone_android,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _descripcionController,
                      label: 'Descripción de la reparación',
                      icon: Icons.description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    
                    // Costos
                    _buildSectionTitle('Costos'),
                    const SizedBox(height: 16),
                    
                    _buildTextField(
                      controller: _costoController,
                      label: 'Costo de la refacción',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        _updatePartCost(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _manodeObraController,
                      label: 'Costo de mano de obra',
                      icon: Icons.engineering,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        _updateLaborCost(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Resumen de costos
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Refacción:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_partCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Mano de Obra:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_laborCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'TOTAL:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                              Text(
                                '\$${_totalCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  color: Color(0xFF1B5E20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sección de imagen
                    _buildSectionTitle('Imagen (Opcional)'),
                    const SizedBox(height: 16),
                    
                    Center(
                      child: Column(
                        children: [
                          if (_imagen != null) ...[
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _imagen!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          ElevatedButton.icon(
                            onPressed: _seleccionarImagen,
                            icon: const Icon(Icons.image),
                            label: Text(_imagen == null ? 'Agregar imagen' : 'Cambiar imagen'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF1B5E20),
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _enviarCotizacion,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color(0xFF1B5E20),
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B5E20)),
                              )
                            : const Text(
                                'Enviar Cotización',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyPartsMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: Color(0xFF1B5E20),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay refacciones disponibles para este tipo de reparación',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Puedes continuar con la cotización ingresando los datos manualmente',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSparePartItem(Map<String, dynamic> part, bool isSelected) {
    return InkWell(
      onTap: () => _selectSparePart(part),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
        ),
        child: Row(
          children: [
            // Indicador de selección
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF43A047) : Colors.grey[300],
                border: Border.all(
                  color: isSelected ? const Color(0xFF43A047) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            
            // Información de la refacción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    part['partType'] ?? 'Sin tipo',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${part['brand'] ?? 'Sin marca'} - ${part['model'] ?? 'Sin modelo'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Precio
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '\$${part['price'] is num ? part['price'].toStringAsFixed(2) : (double.tryParse(part['price']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label == 'Descripción de la reparación' || label.contains('Imagen')) {
              return null; // Estos campos pueden ser opcionales
            }
            return 'Por favor complete este campo';
          }
          if (label == 'Costo de la refacción' || label == 'Costo de mano de obra') {
            try {
              double.parse(value);
            } catch (e) {
              return 'Ingrese un valor numérico válido';
            }
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _marcaController.dispose();
    _modeloController.dispose();
    _descripcionController.dispose();
    _costoController.dispose();
    _manodeObraController.dispose();
    super.dispose();
  }
}