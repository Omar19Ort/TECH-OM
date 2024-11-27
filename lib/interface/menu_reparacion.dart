import 'package:flutter/material.dart';
import 'formulario_reparacion.dart';

class MenuReparacion extends StatefulWidget {
  final String tipoDispositivo;

  const MenuReparacion({Key? key, required this.tipoDispositivo}) : super(key: key);

  @override
  _MenuReparacionState createState() => _MenuReparacionState();
}

class _MenuReparacionState extends State<MenuReparacion> {
  String? _selectedRepair;

  List<Map<String, dynamic>> getRepairOptions() {
    if (widget.tipoDispositivo == 'Celular') {
      return [
        {'title': 'Pantalla', 'icon': Icons.phone_android},
        {'title': 'Batería', 'icon': Icons.battery_full},
        {'title': 'Cámara', 'icon': Icons.camera_alt},
        {'title': 'Bocina', 'icon': Icons.volume_up},
        {'title': 'Botón de volumen/encendido', 'icon': Icons.power_settings_new},
        {'title': 'Altavoz', 'icon': Icons.speaker},
        {'title': 'Centro de carga', 'icon': Icons.charging_station},
      ];
    } else if (widget.tipoDispositivo == 'Computadora') {
      return [
        {'title': 'Pantalla', 'icon': Icons.desktop_windows},
        {'title': 'Memoria RAM', 'icon': Icons.memory},
        {'title': 'Disco HDD/SSD', 'icon': Icons.storage},
        {'title': 'Batería', 'icon': Icons.battery_full},
        {'title': 'Instalación de software', 'icon': Icons.get_app},
        {'title': 'Formateo', 'icon': Icons.refresh},
        {'title': 'Instalación de Sistema Operativo', 'icon': Icons.settings_applications},
      ];
    }
    return [];
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
      body: Column(
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
                return _buildRepairOption(option['title'], option['icon']);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedRepair != null
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

  Widget _buildRepairOption(String title, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedRepair == title;

    return GestureDetector(
      onTap: () {
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
      },
      child: Card(
        elevation: isSelected ? 8 : 2,
        color: isSelected
            ? (isDarkMode ? Colors.blue[700] : const Color(0xFF9DC0B0))
            : Theme.of(context).cardColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: isSelected ? Colors.white : Colors.blue),
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
}

