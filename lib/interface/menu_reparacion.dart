import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class MenuReparacion extends StatelessWidget {
  final String deviceType;

  const MenuReparacion({Key? key, required this.deviceType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> servicios = deviceType == 'Computadora'
        ? [
            {
              'titulo': 'Reemplazo de pantalla',
              'imagen': 'assets/screen_replacement.png',
              'descripcion': 'Reparación y reemplazo de pantallas dañadas'
            },
            {
              'titulo': 'Reemplazo de batería',
              'imagen': 'assets/battery_replacement.png',
              'descripcion': 'Cambio de batería agotada o dañada'
            },
            {
              'titulo': 'Cambio de disco',
              'imagen': 'assets/disk_replacement.png',
              'descripcion': 'Actualización o reemplazo de disco duro'
            },
            {
              'titulo': 'Instalación de RAM',
              'imagen': 'assets/ram_installation.png',
              'descripcion': 'Aumento de memoria RAM'
            },
            {
              'titulo': 'Instalación de SO',
              'imagen': 'assets/os_installation.png',
              'descripcion': 'Instalación de sistema operativo'
            },
            {
              'titulo': 'Instalación de programa',
              'imagen': 'assets/software_installation.png',
              'descripcion': 'Instalación de software específico'
            },
            {
              'titulo': 'Formateo del equipo',
              'imagen': 'assets/formatting.png',
              'descripcion': 'Formateo completo y restauración del sistema'
            },
          ]
        : [
            {
              'titulo': 'Reemplazo de pantalla',
              'imagen': 'assets/screen_replacement.png',
              'descripcion': 'Reparación y reemplazo de pantallas dañadas'
            },
            {
              'titulo': 'Reemplazo de centro de carga',
              'imagen': 'assets/charging_port.png',
              'descripcion': 'Cambio de puerto de carga'
            },
            {
              'titulo': 'Reemplazo de batería',
              'imagen': 'assets/battery_replacement.png',
              'descripcion': 'Cambio de batería agotada o dañada'
            },
            {
              'titulo': 'Reemplazo de bocina/cámara',
              'imagen': 'assets/speaker_camera.png',
              'descripcion': 'Instalación o reemplazo de bocina o cámara'
            },
            {
              'titulo': 'Quitar cuenta Google',
              'imagen': 'assets/google_account.png',
              'descripcion': 'Eliminación de cuenta Google'
            },
            {
              'titulo': 'Formateo de celular',
              'imagen': 'assets/formatting.png',
              'descripcion': 'Formateo completo y restauración del sistema'
            },
            {
              'titulo': 'Quitar patrón olvidado',
              'imagen': 'assets/pattern_unlock.png',
              'descripcion': 'Desbloqueo de patrón olvidado'
            },
          ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reparación de $deviceType',
          style: const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: CarouselSlider.builder(
              itemCount: servicios.length,
              options: CarouselOptions(
                height: double.infinity,
                enlargeCenterPage: true,
                enableInfiniteScroll: false,
                viewportFraction: 0.85,
              ),
              itemBuilder: (context, index, realIndex) {
                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Image.asset(
                            servicios[index]['imagen']!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                servicios[index]['titulo']!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                servicios[index]['descripcion']!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Solicitud de reparación para $deviceType enviada'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Solicitar reparación',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}