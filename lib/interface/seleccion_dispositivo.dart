import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'menu_reparacion.dart';
import 'pantalla_ajustes.dart';
import 'pantalla_perfil.dart';
import 'WelcomeScreen.dart';
import 'cotizar_reparacion.dart';
import '../theme/theme_provider.dart';

class SeleccionDispositivo extends StatefulWidget {
  const SeleccionDispositivo({Key? key}) : super(key: key);

  @override
  _SeleccionDispositivoState createState() => _SeleccionDispositivoState();
}

class _SeleccionDispositivoState extends State<SeleccionDispositivo> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        _navigateToSettings();
        break;
      case 1:
        // Ya estamos en la pantalla de selección de dispositivo
        break;
      case 2:
        _navigateToCotizacion();
        break;
      case 3:
        _navigateToProfile();
        break;
      case 4:
        _showLogoutDialog();
        break;
    }
  }

  void _navigateToSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const PantallaAjustes(),
    ),
  );
}

  void _navigateToCotizacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CotizarReparacion(),
      ),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PantallaPerfil(),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cerrar sesión'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    // Aquí puedes agregar cualquier lógica adicional para cerrar sesión,
    // como limpiar datos de usuario, tokens, etc.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PantallaBienvenida()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      body: _buildBody(isDarkMode),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: _onItemTapped,
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
            icon: Icon(Icons.calculate),
            label: 'Cotizar\nReparación',
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

  Widget _buildBody(bool isDarkMode) {
    final primaryColor = isDarkMode ? Colors.blue[700] : Colors.blue;
    final secondaryColor = const Color(0xFF9DC0B0);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDarkMode ? Colors.blue[900]! : Colors.blue[100]!,
            isDarkMode ? Colors.blue[800]! : Colors.blue[200]!,
            isDarkMode ? Colors.blue[700]! : Colors.blue[300]!,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Selecciona tu dispositivo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.white,
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
                  isDarkMode,
                ),
                _buildDeviceOption(
                  context,
                  'Celular',
                  Icons.smartphone,
                  () => _navigateToRepairMenu(context, 'Celular'),
                  isDarkMode,
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
    bool isDarkMode,
  ) {
    final primaryColor = isDarkMode ? Colors.blue[700] : Colors.blue;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
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
        builder: (context) => MenuReparacion(tipoDispositivo: deviceType),
      ),
    );
  }
}
