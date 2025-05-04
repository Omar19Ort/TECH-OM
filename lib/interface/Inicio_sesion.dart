import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tech_om/database/database_helper.dart';
import 'package:tech_om/theme/theme_provider.dart';
import 'pantalla_registro.dart';
import 'seleccion_dispositivo.dart';

class PantallaInicioSesion extends StatefulWidget {
  final VoidCallback volverABienvenida;

  const PantallaInicioSesion({Key? key, required this.volverABienvenida}) : super(key: key);

  @override
  _PantallaInicioSesionState createState() => _PantallaInicioSesionState();
}

class _PantallaInicioSesionState extends State<PantallaInicioSesion> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final user = await DatabaseHelper.instance.getUserByEmail(_emailController.text);
        if (user != null && user['password'] == _passwordController.text) {
          // Establecer el ID del usuario actual
          int userId = user['id'] as int;
          print('Usuario encontrado con ID: $userId');
          DatabaseHelper.setCurrentUserId(userId);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const SeleccionDispositivo(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Credenciales inválidas')),
          );
        }
      } catch (e) {
        print('Error en inicio de sesión: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al iniciar sesión: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  Image.asset(
                    'assets/Logo3.png',
                    height: 180,
                    width: 180,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Bienvenido de nuevo',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Inicia sesión en tu cuenta',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined, 
                        color: isDarkMode ? Colors.blue[300] : Colors.blue),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su correo electrónico';
                      }
                      if (!value.contains('@')) {
                        return 'Por favor ingrese un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock_outline,
                        color: isDarkMode ? Colors.blue[300] : Colors.blue),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingrese su contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PantallaRegistro(
                            volverAInicioSesion: () => Navigator.pop(context),
                          ),
                        ),
                      );
                    },
                    child: Text(
                      '¿No tienes una cuenta? Regístrate',
                      style: TextStyle(
                        color: isDarkMode ? Colors.blue[300] : Theme.of(context).primaryColor,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: widget.volverABienvenida,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: isDarkMode ? Colors.blue[300]! : Theme.of(context).primaryColor,
                      ),
                    ),
                    child: const Text(
                      'Volver a Bienvenida',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}