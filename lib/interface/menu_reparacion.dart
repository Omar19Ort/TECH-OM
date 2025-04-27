import 'package:flutter/material.dart';
import 'formulario_reparacion.dart';
import 'package:tech_om/database/database_helper.dart';

class MenuReparacion extends StatefulWidget {
  final String tipoDispositivo;

  const MenuReparacion({Key? key, required this.tipoDispositivo}) : super(key: key);

  @override
  _MenuReparacionState createState() => _MenuReparacionState();
}

class _MenuReparacionState extends State<MenuReparacion> {
  String? _selectedRepair;
  final TextEditingController _customRepairController = TextEditingController();
  List<Map<String, dynamic>> _customRepairTypes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomRepairTypes();
  }

  Future<void> _loadCustomRepairTypes() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final customTypes = await DatabaseHelper.instance.getCustomRepairTypes(widget.tipoDispositivo);
      print('Loaded ${customTypes.length} custom repair types for ${widget.tipoDispositivo}');
      setState(() {
        _customRepairTypes = customTypes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar tipos de reparación personalizados: $e');
      setState(() {
        _isLoading = false;
        _customRepairTypes = []; // Ensure it's initialized even on error
      });
    }
  }

  List<Map<String, dynamic>> getRepairOptions() {
    List<Map<String, dynamic>> baseOptions = [];
    
    if (widget.tipoDispositivo == 'Celular') {
      baseOptions = [
        {'title': 'Pantalla', 'icon': Icons.phone_android},
        {'title': 'Batería', 'icon': Icons.battery_full},
        {'title': 'Cámara', 'icon': Icons.camera_alt},
        {'title': 'Bocina', 'icon': Icons.volume_up},
        {'title': 'Botón de volumen/encendido', 'icon': Icons.power_settings_new},
        {'title': 'Altavoz', 'icon': Icons.speaker},
        {'title': 'Centro de carga', 'icon': Icons.charging_station},
      ];
    } else if (widget.tipoDispositivo == 'Computadora') {
      baseOptions = [
        {'title': 'Pantalla', 'icon': Icons.desktop_windows},
        {'title': 'Memoria RAM', 'icon': Icons.memory},
        {'title': 'Disco HDD/SSD', 'icon': Icons.storage},
        {'title': 'Batería', 'icon': Icons.battery_full},
        {'title': 'Instalación de software', 'icon': Icons.get_app},
        {'title': 'Formateo', 'icon': Icons.refresh},
        {'title': 'Instalación de Sistema Operativo', 'icon': Icons.settings_applications},
      ];
    }
    
    // Añadir tipos de reparación personalizados
    for (var customType in _customRepairTypes) {
      baseOptions.add({
        'title': customType['repairType'],
        'icon': Icons.build,
        'isCustom': true,
      });
    }
    
    // Añadir la opción para agregar un nuevo tipo
    baseOptions.add({'title': 'Otro tipo de reparación', 'icon': Icons.add_circle_outline});
    
    return baseOptions;
  }

  Future<void> _saveCustomRepairType(String repairType) async {
    try {
      // Check if the repair type already exists in base options
      final baseOptions = getRepairOptions();
      final alreadyExists = baseOptions.any((option) => 
        option['title'].toString().toLowerCase() == repairType.toLowerCase() &&
        option['title'] != 'Otro tipo de reparación'
      );
      
      if (alreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El tipo de reparación "$repairType" ya existe'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      // Save to database
      await DatabaseHelper.instance.saveCustomRepairType(widget.tipoDispositivo, repairType);
      
      // Reload custom repair types
      await _loadCustomRepairTypes();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tipo de reparación guardado: $repairType'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el tipo de reparación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCustomRepairDialog() {
    _customRepairController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Especificar tipo de reparación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _customRepairController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Reparación de teclado',
                  labelText: 'Tipo de reparación',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.build),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 10),
              const Text(
                'Este tipo de reparación se guardará para futuras selecciones.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_customRepairController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingrese un tipo de reparación'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                final newRepairType = _customRepairController.text.trim();
                setState(() {
                  _selectedRepair = newRepairType;
                });
                _saveCustomRepairType(newRepairType);
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final repairOptions = getRepairOptions();

    return Scaffold(
      appBar: AppBar(
        title: Text('Reparaciones para ${widget.tipoDispositivo}'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: repairOptions.length,
                    itemBuilder: (context, index) {
                      final option = repairOptions[index];
                      return _buildRepairOption(
                        option['title'], 
                        option['icon'],
                        option['isCustom'] == true,
                      );
                    },
                  ),
                ),
                if (_selectedRepair != null && _selectedRepair != 'Otro tipo de reparación')
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.blue[700] : const Color(0xFF9DC0B0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Seleccionado: $_selectedRepair',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedRepair = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedRepair != null && _selectedRepair != 'Otro tipo de reparación'
                          ? () => _navigateToForm(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue[700] : const Color(0xFF9DC0B0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continuar a la cotización',
                        style: TextStyle(
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRepairOption(String title, IconData icon, [bool isCustom = false]) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedRepair == title;

    return GestureDetector(
      onTap: () {
        if (title == 'Otro tipo de reparación') {
          _showCustomRepairDialog();
        } else {
          setState(() {
            _selectedRepair = title;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seleccionado: $title'),
              duration: const Duration(seconds: 1),
              backgroundColor: isDarkMode ? Colors.blue[700] : const Color(0xFF9DC0B0),
            ),
          );
        }
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected
            ? (isDarkMode ? Colors.blue[700] : const Color(0xFF9DC0B0))
            : Theme.of(context).cardColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon, 
              size: 50, 
              color: isSelected 
                ? Colors.white 
                : (isCustom ? Colors.orange : Colors.blue)
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : null,
              ),
              textAlign: TextAlign.center,
            ),
            if (isCustom)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Personalizado',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _navigateToForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioReparacion(
          tipoReparacion: _selectedRepair!,
          tipoDispositivo: widget.tipoDispositivo,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _customRepairController.dispose();
    super.dispose();
  }
}