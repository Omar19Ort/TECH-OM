import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tech_om/database/spare_parts_db.dart';
import 'registrar_compra_refaccion.dart';

class HistorialCompras extends StatefulWidget {
  const HistorialCompras({Key? key}) : super(key: key);

  @override
  _HistorialComprasState createState() => _HistorialComprasState();
}

class _HistorialComprasState extends State<HistorialCompras> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _purchases = [];
  String _filterOption = 'Todas';
  double _totalAmount = 0.0;

  // Colores del tema
  late Color primaryColor;
  late Color secondaryColor;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Configurar colores basados en el tema actual
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    primaryColor = isDarkMode ? Colors.blue[700]! : Colors.blue;
    secondaryColor = const Color(0xFF9DC0B0); // Verde azulado del proyecto
  }

  Future<void> _loadPurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> purchases;
      
      // Filtrar compras según la opción seleccionada
      switch (_filterOption) {
        case 'Hoy':
          final now = DateTime.now();
          final today = DateFormat('yyyy-MM-dd').format(now);
          purchases = await SparePartsDB.instance.getPurchasesByDateRange(today, today);
          break;
        case 'Esta semana':
          final now = DateTime.now();
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final startDate = DateFormat('yyyy-MM-dd').format(startOfWeek);
          final endDate = DateFormat('yyyy-MM-dd').format(now);
          purchases = await SparePartsDB.instance.getPurchasesByDateRange(startDate, endDate);
          break;
        case 'Este mes':
          final now = DateTime.now();
          final startOfMonth = DateTime(now.year, now.month, 1);
          final startDate = DateFormat('yyyy-MM-dd').format(startOfMonth);
          final endDate = DateFormat('yyyy-MM-dd').format(now);
          purchases = await SparePartsDB.instance.getPurchasesByDateRange(startDate, endDate);
          break;
        case 'Todas':
        default:
          purchases = await SparePartsDB.instance.getPurchasesWithDetails();
          break;
      }
      
      // Calcular el monto total
      double total = 0.0;
      for (var purchase in purchases) {
        if (purchase['precio'] != null) {
          total += purchase['precio'] is num ? 
              (purchase['precio'] as num).toDouble() : 
              (double.tryParse(purchase['precio'].toString()) ?? 0);
        }
      }
      
      setState(() {
        _purchases = purchases;
        _totalAmount = total;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar compras: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar compras: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePurchase(int id) async {
    try {
      await SparePartsDB.instance.deletePurchase(id);
      await _loadPurchases();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compra eliminada con éxito'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar la compra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(int id) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[400]),
              const SizedBox(width: 8),
              const Text('Confirmar eliminación'),
            ],
          ),
          content: const Text('¿Estás seguro de que quieres eliminar esta compra?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete),
              label: const Text('Eliminar'),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePurchase(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[400],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;
    
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Historial de Compras',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filtro y resumen
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
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
                // Filtro
                Text(
                  'Filtrar por:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todas'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hoy'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Esta semana'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Este mes'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Resumen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: secondaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: secondaryColor,
                        size: isSmallScreen ? 24 : 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total de compras',
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                fontSize: isSmallScreen ? 12 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '\$${_totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSmallScreen ? 18 : 22,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_purchases.length} compras',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de compras
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: secondaryColor))
                : _purchases.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                        itemCount: _purchases.length,
                        itemBuilder: (context, index) {
                          final purchase = _purchases[index];
                          return _buildPurchaseCard(purchase);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RegistrarCompraRefaccion(),
            ),
          ).then((_) => _loadPurchases());
        },
        backgroundColor: secondaryColor,
        child: const Icon(Icons.add_shopping_cart),
        tooltip: 'Registrar nueva compra',
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _filterOption == label;
    
    return InkWell(
      onTap: () {
        setState(() {
          _filterOption = label;
        });
        _loadPurchases();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? secondaryColor.withOpacity(0.2) 
              : isDarkMode ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? secondaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? secondaryColor : isDarkMode ? Colors.grey[400] : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay compras registradas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _filterOption != 'Todas' 
                ? 'Prueba con otro filtro o registra una nueva compra'
                : 'Registra tu primera compra de refacción',
            style: TextStyle(
              color: isDarkMode ? Colors.grey[500] : Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Registrar compra'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistrarCompraRefaccion(),
                ),
              ).then((_) => _loadPurchases());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseCard(Map<String, dynamic> purchase) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 360;
    
    // Formatear la fecha
    String formattedDate = 'Fecha no disponible';
    try {
      if (purchase['fecha'] != null) {
        final purchaseDate = DateTime.parse(purchase['fecha']);
        formattedDate = '${purchaseDate.day}/${purchaseDate.month}/${purchaseDate.year}';
      }
    } catch (e) {
      print('Error al formatear fecha: $e');
      formattedDate = purchase['fecha'] ?? 'Fecha no disponible';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.shopping_bag,
                    color: secondaryColor,
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        purchase['partType'] ?? 'Refacción',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${purchase['brand'] ?? 'Marca'} - ${purchase['model'] ?? 'Modelo'}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                          fontSize: isSmallScreen ? 13 : 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Precio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: secondaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '\$${purchase['precio'] is num ? (purchase['precio'] as num).toStringAsFixed(2) : '0.00'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: secondaryColor,
                      fontSize: isSmallScreen ? 13 : 14,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: Icon(
                    Icons.delete_outline,
                    size: isSmallScreen ? 18 : 20,
                    color: Colors.red[400],
                  ),
                  label: Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Colors.red[400],
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showDeleteConfirmationDialog(purchase['id']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}