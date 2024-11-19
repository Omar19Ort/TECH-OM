import 'package:flutter/material.dart';
import 'acerca_de.dart';

class PantallaAjustes extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const PantallaAjustes({
    Key? key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  }) : super(key: key);

  @override
  _PantallaAjustesState createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  late bool _isDarkMode;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.currentThemeMode == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildThemeSwitch(),
                _buildListTile(
                  'Historial de reparaciones',
                  Icons.build_outlined,
                  onTap: () {
                    // Implementar navegación al historial de reparaciones
                  },
                ),
                _buildListTile(
                  'Historial de pagos',
                  Icons.payment_outlined,
                  onTap: () {
                    // Implementar navegación al historial de pagos
                  },
                ),
                _buildListTile(
                  'Cerrar sesión',
                  Icons.logout_outlined,
                  onTap: () {
                    // Implementar lógica para cerrar sesión
                  },
                ),
                _buildListTile(
                  'Acerca de la aplicación',
                  Icons.info_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AcercaDe(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Image.asset(
              'assets/logo.png',
              height: 100,
              width: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tema',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Text(
                _isDarkMode ? 'Oscuro' : 'Claro',
                style: TextStyle(
                  color: _isDarkMode ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  widget.onThemeChanged(
                    _isDarkMode ? ThemeMode.dark : ThemeMode.light,
                  );
                },
                activeColor: Colors.blue,
                activeTrackColor: Colors.blue.withOpacity(0.5),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withOpacity(0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, {required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}