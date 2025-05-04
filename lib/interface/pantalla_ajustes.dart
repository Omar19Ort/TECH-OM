import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'acerca_de.dart';
import 'historial_reparaciones.dart';
import 'Pantalla_usuarios.dart';
import 'pantalla_refacciones.dart';
import 'registrar_compra_refaccion.dart';
import 'historial_compras.dart';
import 'historial_pagos.dart';
import '../theme/theme_provider.dart';

class PantallaAjustes extends StatefulWidget {
  const PantallaAjustes({Key? key}) : super(key: key);

  @override
  _PantallaAjustesState createState() => _PantallaAjustesState();
}

class _PantallaAjustesState extends State<PantallaAjustes> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
                _buildThemeSwitch(themeProvider),
                _buildListTile(
                  'Catálogo de Refacciones',
                  Icons.inventory_2_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaRefacciones(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  'Registrar Compra de Refacción',
                  Icons.shopping_cart_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegistrarCompraRefaccion(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  'Historial de Compras',
                  Icons.history,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistorialCompras(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  'Historial de reparaciones',
                  Icons.build_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistorialReparaciones(),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  'Historial de pagos',
                  Icons.payment_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HistorialPagos(),
                      ),
                    );
                  },
                ),
                // _buildListTile(
                //   'Tipos de Reparación',
                //   Icons.category_outlined,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(
                //         builder: (context) => const PantallaTiposReparacion(),
                //       ),
                //     );
                //   },
                // ),
                _buildListTile(
                  'Usuarios',
                  Icons.people_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaUsuarios(),
                      ),
                    );
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
              'assets/Logo4.png',
              height: 100,
              width: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(ThemeProvider themeProvider) {
    final isDarkMode = themeProvider.isDarkMode;
    
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
                isDarkMode ? 'Oscuro' : 'Claro',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isDarkMode,
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
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