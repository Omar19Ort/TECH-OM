import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tech_om/database/database_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HistorialReparaciones extends StatefulWidget {
  const HistorialReparaciones({Key? key}) : super(key: key);

  @override
  _HistorialReparacionesState createState() => _HistorialReparacionesState();
}

class _HistorialReparacionesState extends State<HistorialReparaciones> {
  List<Map<String, dynamic>> _repairs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRepairs();
  }

  Future<void> _loadRepairs() async {
    try {
      // Obtener el ID del usuario actual
      final userId = DatabaseHelper.getCurrentUserId();
      
      List<Map<String, dynamic>> repairs;
      if (userId != null) {
        // Si hay un usuario logueado, obtener solo sus reparaciones
        repairs = await DatabaseHelper.instance.getRepairsByUserId(userId);
      } else {
        // Si no hay usuario logueado, obtener todas las reparaciones (o ninguna)
        repairs = await DatabaseHelper.instance.getRepairs();
      }
      
      setState(() {
        _repairs = repairs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las reparaciones: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteRepair(int id) async {
    try {
      await DatabaseHelper.instance.deleteRepair(id);
      await _loadRepairs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reparación eliminada con éxito')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar la reparación: ${e.toString()}')),
      );
    }
  }

  Future<void> _editRepair(Map<String, dynamic> repair) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => RepairEditDialog(repair: repair),
    );

    if (result != null) {
      try {
        await DatabaseHelper.instance.updateRepair(result);
        await _loadRepairs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reparación actualizada con éxito')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar la reparación: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historial de Reparaciones',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRepairs,
              child: _repairs.isEmpty
                  ? Center(
                      child: Text(
                        'No hay reparaciones registradas',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _repairs.length,
                      itemBuilder: (context, index) {
                        final repair = _repairs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (repair['imageUrl'] != null && repair['imageUrl'].isNotEmpty)
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: _buildImage(repair['imageUrl']),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${repair['repairType']}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '\$${repair['cost']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Dispositivo: ${repair['deviceType']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Marca: ${repair['brand']} - Modelo: ${repair['model']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (repair['description'] != null &&
                                        repair['description'].toString().isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          repair['description'],
                                          style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          label: const Text('Editar', style: TextStyle(color: Colors.blue)),
                                          onPressed: () => _editRepair(repair),
                                        ),
                                        const SizedBox(width: 16),
                                        TextButton.icon(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          onPressed: () => _showDeleteConfirmationDialog(repair['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(int id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que quieres eliminar esta reparación?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRepair(id);
              },
            ),
          ],
        );
      },
    );
  }
}

class RepairEditDialog extends StatefulWidget {
  final Map<String, dynamic> repair;

  const RepairEditDialog({Key? key, required this.repair}) : super(key: key);

  @override
  _RepairEditDialogState createState() => _RepairEditDialogState();
}

class _RepairEditDialogState extends State<RepairEditDialog> {
  late TextEditingController _repairTypeController;
  late TextEditingController _deviceTypeController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _descriptionController;
  late TextEditingController _costController;

  @override
  void initState() {
    super.initState();
    _repairTypeController = TextEditingController(text: widget.repair['repairType']);
    _deviceTypeController = TextEditingController(text: widget.repair['deviceType']);
    _brandController = TextEditingController(text: widget.repair['brand']);
    _modelController = TextEditingController(text: widget.repair['model']);
    _descriptionController = TextEditingController(text: widget.repair['description']);
    _costController = TextEditingController(text: widget.repair['cost'].toString());
  }

  @override
  void dispose() {
    _repairTypeController.dispose();
    _deviceTypeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Reparación'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _repairTypeController,
              decoration: const InputDecoration(labelText: 'Tipo de Reparación'),
            ),
            TextField(
              controller: _deviceTypeController,
              decoration: const InputDecoration(labelText: 'Tipo de Dispositivo'),
            ),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Marca'),
            ),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Modelo'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 3,
            ),
            TextField(
              controller: _costController,
              decoration: const InputDecoration(labelText: 'Costo'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedRepair = {
              ...widget.repair,
              'repairType': _repairTypeController.text,
              'deviceType': _deviceTypeController.text,
              'brand': _brandController.text,
              'model': _modelController.text,
              'description': _descriptionController.text,
              'cost': double.tryParse(_costController.text) ?? widget.repair['cost'],
            };
            Navigator.of(context).pop(updatedRepair);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}