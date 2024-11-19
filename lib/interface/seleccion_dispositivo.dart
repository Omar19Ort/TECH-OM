import 'package:flutter/material.dart';
import 'menu_reparacion.dart';
import 'pantalla_ajustes.dart';
import 'pantalla_perfil.dart';

class SeleccionDispositivo extends StatefulWidget {
  const SeleccionDispositivo({Key? key}) : super(key: key);

  @override
  _SeleccionDispositivoState createState() => _SeleccionDispositivoState();
}

class _SeleccionDispositivoState extends State<SeleccionDispositivo> {
  int _selectedIndex = 1;
  ThemeMode _currentThemeMode = ThemeMode.system;

  void _onThemeChanged(ThemeMode mode) {
    setState(() {
      _currentThemeMode = mode;
    });
    // Aquí se implementaría la lógica para cambiar el tema en toda la app
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaAjustes(
                    onThemeChanged: _onThemeChanged,
                    currentThemeMode: _currentThemeMode,
                  ),
                ),
              );
              break;
            case 1:
              // Ya estamos en la pantalla de selección de dispositivo
              break;
            case 2:
              // Implementar navegación a la pantalla de pagos
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaPerfil(),
                ),
              );
              break;
            case 4:
              // Implementar lógica para cerrar sesión
              break;
          }
        },
        selectedIndex: _selectedIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices),
            label: 'Dispositivos',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment),
            label: 'Pagos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout),
            label: 'Cerrar\nSesión',
          ),
        ],
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade200,
            Colors.blue.shade300,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Selecciona tu dispositivo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDeviceOption(
                  context,
                  'Computadora',
                  Icons.computer,
                  () => _navigateToRepairMenu(context, 'Computadora'),
                ),
                _buildDeviceOption(
                  context,
                  'Celular',
                  Icons.smartphone,
                  () => _navigateToRepairMenu(context, 'Celular'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToRepairMenu(BuildContext context, String deviceType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuReparacion(deviceType: deviceType),
      ),
    );
  }
}