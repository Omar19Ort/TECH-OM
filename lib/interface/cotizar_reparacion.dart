import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tech_om/database/spare_parts_db.dart';
import 'package:tech_om/database/database_helper.dart';

class CotizarReparacion extends StatefulWidget {
  const CotizarReparacion({Key? key}) : super(key: key);

  @override
  _CotizarReparacionState createState() => _CotizarReparacionState();
}

class _CotizarReparacionState extends State<CotizarReparacion> {
  // Datos principales
  String _selectedDeviceType = 'Celular';
  String? _selectedRepairType;
  Map<String, dynamic>? _selectedSparePart;
  double _laborCost = 0.0;
  double _totalCost = 0.0;
  
  // Listas de datos
  List<Map<String, dynamic>> _repairTypes = [];
  List<Map<String, dynamic>> _spareParts = [];
  
  // Controladores
  final TextEditingController _laborCostController = TextEditingController(text: '0.00');
  final TextEditingController _deviceBrandController = TextEditingController();
  final TextEditingController _deviceModelController = TextEditingController();
  
  // Estados
  bool _isLoading = true;
  bool _showRepairTypes = true; // Para controlar qué panel se muestra
  
  // Colores y tema - usando la paleta de menu_reparacion.dart
  late Color primaryColor;
  late Color secondaryColor;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Configurar colores basados en el tema actual
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = isDarkMode ? Colors.blue[700]! : Colors.blue;
    secondaryColor = const Color(0xFF9DC0B0); // Verde azulado del proyecto
  }

  // Cargar datos iniciales
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _loadRepairTypes();
      await _loadSpareParts();
    } catch (e) {
      _showErrorSnackBar('Error al cargar datos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Cargar tipos de reparación
  Future<void> _loadRepairTypes() async {
    try {
      // Tipos de reparación predeterminados
      List<Map<String, dynamic>> defaultRepairs = [];
      if (_selectedDeviceType == 'Celular') {
        defaultRepairs = [
          {'id': 'default-1', 'name': 'Pantalla', 'icon': Icons.phone_android},
          {'id': 'default-2', 'name': 'Batería', 'icon': Icons.battery_full},
          {'id': 'default-3', 'name': 'Cámara', 'icon': Icons.camera_alt},
          {'id': 'default-4', 'name': 'Bocina', 'icon': Icons.volume_up},
          {'id': 'default-5', 'name': 'Botón de volumen/encendido', 'icon': Icons.power_settings_new},
          {'id': 'default-6', 'name': 'Altavoz', 'icon': Icons.speaker},
          {'id': 'default-7', 'name': 'Centro de carga', 'icon': Icons.charging_station},
        ];
      } else {
        defaultRepairs = [
          {'id': 'default-1', 'name': 'Pantalla', 'icon': Icons.desktop_windows},
          {'id': 'default-2', 'name': 'Memoria RAM', 'icon': Icons.memory},
          {'id': 'default-3', 'name': 'Disco HDD/SSD', 'icon': Icons.storage},
          {'id': 'default-4', 'name': 'Batería', 'icon': Icons.battery_full},
          {'id': 'default-5', 'name': 'Instalación de software', 'icon': Icons.get_app},
          {'id': 'default-6', 'name': 'Formateo', 'icon': Icons.refresh},
          {'id': 'default-7', 'name': 'Sistema Operativo', 'icon': Icons.settings_applications},
        ];
      }

      // Cargar tipos de reparación personalizados
      final customTypes = await DatabaseHelper.instance.getCustomRepairTypes(_selectedDeviceType);
      
      // Combinar tipos predeterminados y personalizados
      List<Map<String, dynamic>> allRepairs = [...defaultRepairs];
      for (var customType in customTypes) {
        allRepairs.add({
          'id': 'custom-${customType['id']}',
          'name': customType['repairType'],
          'icon': Icons.build,
          'isCustom': true,
        });
      }

      setState(() {
        _repairTypes = allRepairs;
        // Resetear selección si el tipo de reparación ya no existe
        if (_selectedRepairType != null && 
            !allRepairs.any((repair) => repair['name'] == _selectedRepairType)) {
          _selectedRepairType = null;
          _selectedSparePart = null;
        }
      });
    } catch (e) {
      print('Error al cargar tipos de reparación: $e');
      rethrow;
    }
  }

  // Cargar refacciones
  Future<void> _loadSpareParts() async {
    try {
      final spareParts = await SparePartsDB.instance.getSparePartsByDeviceType(_selectedDeviceType);
      setState(() {
        _spareParts = spareParts;
        // Resetear selección si la refacción ya no existe
        if (_selectedSparePart != null && 
            !spareParts.any((part) => part['id'] == _selectedSparePart!['id'])) {
          _selectedSparePart = null;
        }
      });
    } catch (e) {
      print('Error al cargar refacciones: $e');
      rethrow;
    }
  }

  // Filtrar refacciones por tipo de reparación
  List<Map<String, dynamic>> _getFilteredSpareParts() {
    if (_selectedRepairType == null) return [];
    
    return _spareParts.where((part) {
      // Filtrar por tipo de parte que coincida con el tipo de reparación seleccionado
      return part['partType'].toString().toLowerCase().contains(_selectedRepairType!.toLowerCase()) ||
             _selectedRepairType!.toLowerCase().contains(part['partType'].toString().toLowerCase());
    }).toList();
  }

  // Calcular costo total
  _calculateTotal() {
    double partsCost = 0.0;
    if (_selectedSparePart != null && _selectedSparePart!['price'] != null) {
      if (_selectedSparePart!['price'] is num) {
        partsCost = (_selectedSparePart!['price'] as num).toDouble();
      } else if (_selectedSparePart!['price'] is String) {
        partsCost = double.tryParse(_selectedSparePart!['price']) ?? 0.0;
      }
    }
    
    setState(() {
      _totalCost = partsCost + _laborCost;
    });
  }

  // Mostrar mensaje de error
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Cambiar tipo de dispositivo
  void _changeDeviceType(String newType) {
    if (_selectedDeviceType != newType) {
      setState(() {
        _selectedDeviceType = newType;
        _selectedRepairType = null;
        _selectedSparePart = null;
        _laborCost = 0.0;
        _laborCostController.text = '0.00';
        _totalCost = 0.0;
        _showRepairTypes = true; // Volver a mostrar tipos de reparación
      });
      _loadData();
    }
  }

  // Seleccionar tipo de reparación
  void _selectRepairType(String repairType) {
    setState(() {
      _selectedRepairType = repairType;
      _selectedSparePart = null; // Resetear la refacción seleccionada
      _showRepairTypes = false; // Cambiar a la vista de refacciones
    });
    _calculateTotal();
  }

  // Seleccionar refacción
  void _selectSparePart(Map<String, dynamic> sparePart) {
    setState(() {
      _selectedSparePart = sparePart;
    });
    _calculateTotal();
  }

  // Actualizar costo de mano de obra
  void _updateLaborCost(String value) {
    setState(() {
      _laborCost = double.tryParse(value) ?? 0.0;
    });
    _calculateTotal();
  }

  // Formatear moneda
  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    final isVerySmallScreen = screenSize.width < 300;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cotizar Reparación',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.white,
            fontSize: isSmallScreen ? 18 : 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (!_showRepairTypes && _selectedRepairType != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _showRepairTypes = true;
                });
              },
              tooltip: 'Volver a tipos de reparación',
              // Ajustar tamaño para pantallas pequeñas
              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
              constraints: BoxConstraints(
                minWidth: isSmallScreen ? 40 : 48,
                minHeight: isSmallScreen ? 40 : 48,
              ),
            ),
        ],
      ),
      body: SafeArea(
        // Usar SingleChildScrollView para evitar desbordamientos en pantallas pequeñas
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: secondaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Cargando datos...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  _buildDeviceTypeSelector(isSmallScreen, isVerySmallScreen),
                  Expanded(
                    child: _showRepairTypes
                        ? _buildRepairTypesList(isSmallScreen, isVerySmallScreen)
                        : _buildSparePartsList(isSmallScreen, isVerySmallScreen),
                  ),
                  if (_selectedSparePart != null && !_showRepairTypes)
                    _buildQuoteSummary(isSmallScreen, isVerySmallScreen),
                ],
              ),
      ),
    );
  }

  // Selector de tipo de dispositivo
  Widget _buildDeviceTypeSelector(bool isSmallScreen, bool isVerySmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
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
          Text(
            'Dispositivo:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (isVerySmallScreen) {
                // Para pantallas muy pequeñas
                return Column(
                  children: [
                    _buildDeviceButton('Celular', Icons.smartphone, isSmallScreen),
                    const SizedBox(height: 8),
                    _buildDeviceButton('Computadora', Icons.computer, isSmallScreen),
                  ],
                );
              } else {
                // Para pantallas normales
                return SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'Celular',
                      label: Text('Celular', 
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: Icon(Icons.smartphone, size: isSmallScreen ? 18 : 20),
                    ),
                    ButtonSegment<String>(
                      value: 'Computadora',
                      label: Text('Computadora', 
                        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      icon: Icon(Icons.computer, size: isSmallScreen ? 18 : 20),
                    ),
                  ],
                  selected: {_selectedDeviceType},
                  onSelectionChanged: (Set<String> newSelection) {
                    _changeDeviceType(newSelection.first);
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
                    // Ajustar padding para pantallas pequeñas
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                      EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 6 : 8,
                      ),
                    ),
                  ),
                );
              }
            }
          ),
          if (_selectedRepairType != null && !_showRepairTypes)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.build, color: secondaryColor, size: isSmallScreen ? 18 : 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Reparación: $_selectedRepairType',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Botón de dispositivo para pantallas pequeñas
  Widget _buildDeviceButton(String deviceType, IconData icon, bool isSmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedDeviceType == deviceType;
    
    return InkWell(
      onTap: () {
        _changeDeviceType(deviceType);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: isSmallScreen ? 10 : 12, 
          horizontal: isSmallScreen ? 12 : 16
        ),
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
              size: isSmallScreen ? 18 : 20,
            ),
            const SizedBox(width: 8),
            Text(
              deviceType,
              style: TextStyle(
                color: isSelected ? secondaryColor : isDarkMode ? Colors.grey[400] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Lista de tipos de reparación
  Widget _buildRepairTypesList(bool isSmallScreen, bool isVerySmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Text(
            'Selecciona el tipo de reparación',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Ajustar el número de columnas según el ancho disponible
              final crossAxisCount = isVerySmallScreen ? 1 : 
                                    (constraints.maxWidth < 400 ? 2 : 3);
              
              // Ajustar la relación de aspecto según el número de columnas
              final childAspectRatio = crossAxisCount == 1 ? 3.0 : 
                                      (crossAxisCount == 2 ? 1.5 : 1.2);
              
              return GridView.builder(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: childAspectRatio,
                  crossAxisSpacing: isSmallScreen ? 12 : 16,
                  mainAxisSpacing: isSmallScreen ? 12 : 16,
                ),
                itemCount: _repairTypes.length,
                itemBuilder: (context, index) {
                  final repair = _repairTypes[index];
                  
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _selectRepairType(repair['name']),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        child: crossAxisCount == 1
                            ? Row(
                                children: [
                                  Icon(
                                    repair['icon'] ?? Icons.build,
                                    size: isSmallScreen ? 28 : 36,
                                    color: repair['isCustom'] == true
                                        ? primaryColor
                                        : secondaryColor,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          repair['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: isSmallScreen ? 13 : 14,
                                            color: isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                        if (repair['isCustom'] == true)
                                          Text(
                                            'Personalizado',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 9 : 10,
                                              fontStyle: FontStyle.italic,
                                              color: primaryColor,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    repair['icon'] ?? Icons.build,
                                    size: isSmallScreen ? 28 : 36,
                                    color: repair['isCustom'] == true
                                        ? primaryColor
                                        : secondaryColor,
                                  ),
                                  SizedBox(height: isSmallScreen ? 6 : 10),
                                  Flexible(
                                    child: Text(
                                      repair['name'],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSmallScreen ? 12 : 13,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                    ),
                                  ),
                                  if (repair['isCustom'] == true)
                                    Text(
                                      'Personalizado',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 9 : 10,
                                        fontStyle: FontStyle.italic,
                                        color: primaryColor,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }

  // Lista de refacciones
  Widget _buildSparePartsList(bool isSmallScreen, bool isVerySmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final filteredParts = _getFilteredSpareParts();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          child: Text(
            'Selecciona una refacción',
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ),
        Expanded(
          child: filteredParts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: isSmallScreen ? 48 : 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay refacciones disponibles',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Agrega refacciones en el catálogo',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 16),
                  itemCount: filteredParts.length,
                  itemBuilder: (context, index) {
                    final part = filteredParts[index];
                    final bool isSelected = _selectedSparePart != null && 
                                           _selectedSparePart!['id'] == part['id'];
                    
                    return Card(
                      margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 12),
                      elevation: isSelected ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? secondaryColor : Colors.transparent,
                          width: isSelected ? 2 : 0,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _selectSparePart(part),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 14),
                          child: Row(
                            children: [
                              // Indicador de selección
                              Container(
                                width: isSmallScreen ? 20 : 24,
                                height: isSmallScreen ? 20 : 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? secondaryColor : Colors.grey[300],
                                  border: Border.all(
                                    color: isSelected ? secondaryColor : Colors.grey[400]!,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        size: isSmallScreen ? 14 : 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              SizedBox(width: isSmallScreen ? 10 : 14),
                              
                              // Información de la refacción
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${part['partType']}',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${part['brand']} - ${part['model']}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: isSmallScreen ? 12 : 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: isVerySmallScreen ? 1 : 2,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Precio
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isSmallScreen ? 8 : 12, 
                                  vertical: isSmallScreen ? 4 : 8
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected ? secondaryColor : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatCurrency(part['price'] is num ? part['price'].toDouble() : 0.0),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: isSelected ? Colors.white : secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_selectedSparePart != null)
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mano de Obra',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _laborCostController,
                  decoration: InputDecoration(
                    labelText: 'Costo de mano de obra',
                    prefixIcon: Icon(Icons.engineering, color: secondaryColor, size: isSmallScreen ? 18 : 20),
                    prefixText: '\$ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
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
                  onChanged: _updateLaborCost,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Resumen de la cotización
  Widget _buildQuoteSummary(bool isSmallScreen, bool isVerySmallScreen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return Container(
      padding: EdgeInsets.only(
        left: isSmallScreen ? 12 : 16,
        right: isSmallScreen ? 12 : 16,
        top: isSmallScreen ? 12 : 16,
        bottom: isSmallScreen ? 12 : 16 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Resumen de costos
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Refacción:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    Text(
                      _formatCurrency(_selectedSparePart != null ? 
                          (_selectedSparePart!['price'] is num ? 
                              _selectedSparePart!['price'].toDouble() : 0.0) : 0.0),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mano de Obra:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                    Text(
                      _formatCurrency(_laborCost),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 13 : 14,
                      ),
                    ),
                  ],
                ),
                Divider(height: isSmallScreen ? 20 : 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      _formatCurrency(_totalCost),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 18 : 22,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        SizedBox(height: isSmallScreen ? 12 : 16),
        
        // Botón de finalizar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Aquí podrías implementar la lógica para finalizar la cotización
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Cotización finalizada'),
                  backgroundColor: secondaryColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.check_circle, size: isSmallScreen ? 18 : 20),
            label: Text(
              'Finalizar Cotización',
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDarkMode ? secondaryColor : secondaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  @override
  void dispose() {
    _laborCostController.dispose();
    _deviceBrandController.dispose();
    _deviceModelController.dispose();
    super.dispose();
  }
}
