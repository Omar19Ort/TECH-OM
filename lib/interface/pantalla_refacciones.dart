import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tech_om/database/spare_parts_db.dart';
import 'registrar_compra_refaccion.dart';

class PantallaRefacciones extends StatefulWidget {
  const PantallaRefacciones({Key? key}) : super(key: key);

  @override
  _PantallaRefaccionesState createState() => _PantallaRefaccionesState();
}

class _PantallaRefaccionesState extends State<PantallaRefacciones> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _spareParts = [];
  String _selectedDeviceType = 'Celular';
  List<String> _partTypes = [];
  
  // Controladores para el formulario
  final TextEditingController _partTypeController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  
  // Controlador para la búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Colores del tema - usando la paleta de menu_reparacion.dart
  late Color primaryColor;
  late Color secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadSpareParts();
    _loadPartTypes();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Configurar colores basados en el tema actual
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = isDarkMode ? Colors.blue[700]! : Colors.blue;
    secondaryColor = const Color(0xFF9DC0B0); // Verde azulado del proyecto
  }

  Future<void> _loadSpareParts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final spareParts = await SparePartsDB.instance.getSparePartsByDeviceType(_selectedDeviceType);
      setState(() {
        _spareParts = spareParts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar refacciones: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar refacciones: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPartTypes() async {
    try {
      final partTypes = await SparePartsDB.instance.getDistinctPartTypes();
      setState(() {
        _partTypes = partTypes;
      });
    } catch (e) {
      print('Error al cargar tipos de refacciones: $e');
    }
  }

  void _showAddSparePartDialog({Map<String, dynamic>? existingSparePart}) {
    // Si estamos editando, llenamos los controladores con los valores existentes
    if (existingSparePart != null) {
      _partTypeController.text = existingSparePart['partType'];
      _brandController.text = existingSparePart['brand'];
      _modelController.text = existingSparePart['model'];
      _priceController.text = existingSparePart['price'].toString();
    } else {
      // Si estamos creando, limpiamos los controladores
      _partTypeController.clear();
      _brandController.clear();
      _modelController.clear();
      _priceController.clear();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * (isSmallScreen ? 0.9 : 0.85),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Barra superior con título y botón de cerrar
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16, 
                      vertical: isSmallScreen ? 10 : 12
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          existingSparePart != null ? Icons.edit : Icons.add_circle_outline,
                          color: Colors.white,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Expanded(
                          child: Text(
                            existingSparePart != null ? 'Editar Refacción' : 'Agregar Nueva Refacción',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 16 : 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          iconSize: isSmallScreen ? 20 : 24,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido del formulario
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tipo de dispositivo
                          Text(
                            'Tipo de Dispositivo',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth < 280) {
                                  // Para pantallas muy pequeñas
                                  return Column(
                                    children: [
                                      _buildDeviceTypeOption(
                                        'Celular', 
                                        Icons.smartphone, 
                                        existingSparePart != null ? existingSparePart['deviceType'] : _selectedDeviceType, 
                                        setState,
                                        isFullWidth: true,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDeviceTypeOption(
                                        'Computadora', 
                                        Icons.computer, 
                                        existingSparePart != null ? existingSparePart['deviceType'] : _selectedDeviceType, 
                                        setState,
                                        isFullWidth: true,
                                      ),
                                    ],
                                  );
                                } else {
                                  // Para pantallas normales
                                  return SegmentedButton<String>(
                                    segments: const [
                                      ButtonSegment<String>(
                                        value: 'Celular',
                                        label: Text('Celular'),
                                        icon: Icon(Icons.smartphone),
                                      ),
                                      ButtonSegment<String>(
                                        value: 'Computadora',
                                        label: Text('Computadora'),
                                        icon: Icon(Icons.computer),
                                      ),
                                    ],
                                    selected: {existingSparePart != null ? existingSparePart['deviceType'] : _selectedDeviceType},
                                    onSelectionChanged: (Set<String> newSelection) {
                                      setState(() {
                                        _selectedDeviceType = newSelection.first;
                                      });
                                    },
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                          if (states.contains(MaterialState.selected)) {
                                            return secondaryColor.withOpacity(0.2);
                                          }
                                          return Colors.transparent;
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 16 : 24),
                          
                          // Resto del formulario...
                          // (Mantener el resto del formulario igual, solo ajustando los tamaños según isSmallScreen)
                          
                          // Tipo de refacción
                          Text(
                            'Tipo de Refacción',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<String>.empty();
                              }
                              return _partTypes.where((String option) {
                                return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            onSelected: (String selection) {
                              _partTypeController.text = selection;
                            },
                            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                              // Asignamos el controlador del autocomplete a nuestro controlador
                              if (controller.text.isEmpty && _partTypeController.text.isNotEmpty) {
                                controller.text = _partTypeController.text;
                              }
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                onChanged: (value) => _partTypeController.text = value,
                                decoration: InputDecoration(
                                  labelText: 'Tipo de Refacción',
                                  hintText: 'Ej: Pantalla, Batería',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  prefixIcon: Icon(Icons.category, color: secondaryColor),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: secondaryColor, width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isSmallScreen ? 12 : 16,
                                    vertical: isSmallScreen ? 12 : 16,
                                  ),
                                ),
                                textCapitalization: TextCapitalization.sentences,
                                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                              );
                            },
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // Marca
                          Text(
                            'Marca',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _brandController,
                            decoration: InputDecoration(
                              labelText: 'Marca',
                              hintText: 'Ej: Samsung, Apple',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.business, color: secondaryColor),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // Modelo
                          Text(
                            'Modelo Compatible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          TextField(
                            controller: _modelController,
                            decoration: InputDecoration(
                              labelText: 'Modelo Compatible',
                              hintText: 'Ej: Galaxy S21, MacBook Pro 2021',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.phone_android, color: secondaryColor),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          
                          // Precio
                          Text(
                            'Precio',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 14 : 16,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Precio',
                              hintText: 'Ej: 1500.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(Icons.attach_money, color: secondaryColor),
                              prefixText: '\$ ',
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: secondaryColor, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isSmallScreen ? 12 : 16,
                                vertical: isSmallScreen ? 12 : 16,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Botones de acción
                  Container(
                    padding: EdgeInsets.only(
                      left: isSmallScreen ? 12 : 16,
                      right: isSmallScreen ? 12 : 16,
                      top: isSmallScreen ? 12 : 16,
                      bottom: isSmallScreen ? 12 : 16 + bottomInset,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 280) {
                          // Para pantallas muy pequeñas
                          return Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Validación y guardado (mantener igual)
                                    // Validar campos
                                    if (_partTypeController.text.trim().isEmpty ||
                                        _brandController.text.trim().isEmpty ||
                                        _modelController.text.trim().isEmpty ||
                                        _priceController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Por favor complete todos los campos'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Validar precio
                                    double price;
                                    try {
                                      price = double.parse(_priceController.text);
                                      if (price <= 0) throw Exception('El precio debe ser mayor a 0');
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Por favor ingrese un precio válido'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final sparePart = {
                                        'partType': _partTypeController.text.trim(),
                                        'brand': _brandController.text.trim(),
                                        'model': _modelController.text.trim(),
                                        'price': price,
                                        'deviceType': _selectedDeviceType,
                                      };

                                      if (existingSparePart != null) {
                                        // Actualizar refacción existente
                                        sparePart['id'] = existingSparePart['id'];
                                        await SparePartsDB.instance.updateSparePart(sparePart);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Refacción actualizada con éxito'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        // Insertar nueva refacción
                                        await SparePartsDB.instance.insertSparePart(sparePart);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Refacción agregada con éxito'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }

                                      Navigator.of(context).pop();
                                      await _loadSpareParts();
                                      await _loadPartTypes();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    existingSparePart != null ? 'Actualizar' : 'Guardar',
                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Para pantallas normales
                          return Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                      fontSize: isSmallScreen ? 14 : 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    // Validación y guardado (mantener igual)
                                    // Validar campos
                                    if (_partTypeController.text.trim().isEmpty ||
                                        _brandController.text.trim().isEmpty ||
                                        _modelController.text.trim().isEmpty ||
                                        _priceController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Por favor complete todos los campos'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Validar precio
                                    double price;
                                    try {
                                      price = double.parse(_priceController.text);
                                      if (price <= 0) throw Exception('El precio debe ser mayor a 0');
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Por favor ingrese un precio válido'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    try {
                                      final sparePart = {
                                        'partType': _partTypeController.text.trim(),
                                        'brand': _brandController.text.trim(),
                                        'model': _modelController.text.trim(),
                                        'price': price,
                                        'deviceType': _selectedDeviceType,
                                      };

                                      if (existingSparePart != null) {
                                        // Actualizar refacción existente
                                        sparePart['id'] = existingSparePart['id'];
                                        await SparePartsDB.instance.updateSparePart(sparePart);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Refacción actualizada con éxito'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        // Insertar nueva refacción
                                        await SparePartsDB.instance.insertSparePart(sparePart);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Refacción agregada con éxito'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }

                                      Navigator.of(context).pop();
                                      await _loadSpareParts();
                                      await _loadPartTypes();
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: ${e.toString()}'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    existingSparePart != null ? 'Actualizar' : 'Guardar',
                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      }
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Añadir este método auxiliar para el selector de tipo de dispositivo
  Widget _buildDeviceTypeOption(
    String deviceType, 
    IconData icon, 
    String selectedType, 
    StateSetter setState, 
    {bool isFullWidth = false}
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedType == deviceType;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDeviceType = deviceType;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? secondaryColor.withOpacity(0.2) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? secondaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? secondaryColor : isDarkMode ? Colors.grey[400] : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              deviceType,
              style: TextStyle(
                color: isSelected ? secondaryColor : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSparePart(int id, String partType) async {
    try {
      await SparePartsDB.instance.deleteSparePart(id);
      await _loadSpareParts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refacción "$partType" eliminada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la refacción: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredSpareParts() {
    if (_searchQuery.isEmpty) {
      return _spareParts;
    }
    
    return _spareParts.where((part) {
      return part['partType'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             part['brand'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             part['model'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Modificar el método build para usar LayoutBuilder
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredParts = _getFilteredSpareParts();
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Catálogo de Refacciones',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda y selector de dispositivo
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barra de búsqueda
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar refacciones...',
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 1),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Selector de tipo de dispositivo
                  Text(
                    'Dispositivo:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return constraints.maxWidth < 300
                        ? Column(
                            children: [
                              _buildDeviceButton('Celular', Icons.smartphone),
                              const SizedBox(height: 8),
                              _buildDeviceButton('Computadora', Icons.computer),
                            ],
                          )
                        : SegmentedButton<String>(
                            segments: const [
                              ButtonSegment<String>(
                                value: 'Celular',
                                label: Text('Celular'),
                                icon: Icon(Icons.smartphone),
                              ),
                              ButtonSegment<String>(
                                value: 'Computadora',
                                label: Text('Computadora'),
                                icon: Icon(Icons.computer),
                              ),
                            ],
                            selected: {_selectedDeviceType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedDeviceType = newSelection.first;
                              });
                              _loadSpareParts();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return secondaryColor.withOpacity(0.2);
                                  }
                                  return Colors.transparent;
                                },
                              ),
                            ),
                          );
                    }
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Contador de refacciones
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mostrando ${filteredParts.length} refacciones',
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        TextButton.icon(
                          icon: const Icon(Icons.clear, size: 18),
                          label: const Text('Limpiar', style: TextStyle(fontSize: 13)),
                          style: TextButton.styleFrom(
                            foregroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Lista de refacciones
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: secondaryColor))
                  : filteredParts.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                          itemCount: filteredParts.length,
                          itemBuilder: (context, index) {
                            final part = filteredParts[index];
                            return _buildSparePartCard(part);
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: () => _showAddSparePartDialog(),
          backgroundColor: secondaryColor,
          heroTag: 'addPart',
          child: const Icon(Icons.add),
          tooltip: 'Agregar refacción',
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const RegistrarCompraRefaccion(),
              ),
            );
          },
          backgroundColor: primaryColor,
          heroTag: 'registerPurchase',
          child: const Icon(Icons.shopping_cart),
          tooltip: 'Registrar compra',
        ),
      ],
    ),
    );
  }

  // Añadir este método para pantallas pequeñas
  Widget _buildDeviceButton(String deviceType, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedDeviceType == deviceType;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedDeviceType = deviceType;
        });
        _loadSpareParts();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? secondaryColor.withOpacity(0.2) 
              : isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? secondaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? secondaryColor : isDarkMode ? Colors.grey[400] : Colors.grey[700],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              deviceType,
              style: TextStyle(
                color: isSelected ? secondaryColor : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Estado vacío
  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: isSmallScreen ? 60 : 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No hay refacciones registradas'
                : 'No se encontraron refacciones',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Agregar refacción'),
            onPressed: () => _showAddSparePartDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mostrar opciones de refacción
  void _showSparePartOptions(Map<String, dynamic> part) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[850] : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicador de arrastre
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Título
              Text(
                'Detalles de la Refacción',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              
              // Detalles de la refacción
              _buildDetailItem('Tipo', part['partType'], Icons.category, isDarkMode, isSmallScreen),
              _buildDetailItem('Marca', part['brand'], Icons.business, isDarkMode, isSmallScreen),
              _buildDetailItem('Modelo', part['model'], Icons.phone_android, isDarkMode, isSmallScreen),
              _buildDetailItem('Precio', '\$${part['price'].toStringAsFixed(2)}', Icons.attach_money, isDarkMode, isSmallScreen),
              _buildDetailItem('Dispositivo', part['deviceType'], part['deviceType'] == 'Celular' ? Icons.smartphone : Icons.computer, isDarkMode, isSmallScreen),
              
              const SizedBox(height: 24),
              
              // Botones de acción
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 280) {
                    // Para pantallas muy pequeñas
                    return Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddSparePartDialog(existingSparePart: part);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmationDialog(part['id'], part['partType']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Para pantallas normales
                    return Row(
                      children: [
                        // Botón de editar
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Editar'),
                            onPressed: () {
                              Navigator.pop(context);
                              _showAddSparePartDialog(existingSparePart: part);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Botón de eliminar
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.delete),
                            label: const Text('Eliminar'),
                            onPressed: () {
                              Navigator.pop(context);
                              _showDeleteConfirmationDialog(part['id'], part['partType']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                }
              ),
              const SizedBox(height: 8),
              
              // Botón de cerrar
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cerrar',
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, bool isDarkMode, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: secondaryColor,
              size: isSmallScreen ? 18 : 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación de eliminación
  void _showDeleteConfirmationDialog(int id, String partType) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: isSmallScreen ? 24 : 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirmar eliminación',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás seguro de que quieres eliminar esta refacción?',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.build, color: secondaryColor, size: isSmallScreen ? 18 : 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        partType,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: Icon(Icons.delete, size: isSmallScreen ? 18 : 20),
              label: Text('Eliminar', style: TextStyle(fontSize: isSmallScreen ? 14 : 16)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSparePart(id, partType);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

Widget _buildSparePartCard(Map<String, dynamic> part) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final isSmallScreen = MediaQuery.of(context).size.width < 360;
  
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: () => _showSparePartOptions(part),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del tipo de dispositivo
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    part['deviceType'] == 'Celular' ? Icons.smartphone : Icons.computer,
                    color: secondaryColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part['partType'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${part['brand']} - ${part['model']}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Precio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '\$${part['price'].toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}