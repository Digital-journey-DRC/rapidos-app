import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:flutter/services.dart';
import 'package:immo/services/product_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/product_cubit.dart';

class DetailProduitMarchantScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final String productPrice;
  final String productStock;
  final String productBadge;
  final String productImageUrl;
  final bool isPromo;

  const DetailProduitMarchantScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productStock,
    required this.productBadge,
    required this.productImageUrl,
    required this.isPromo,
  }) : super(key: key);

  @override
  State<DetailProduitMarchantScreen> createState() => _DetailProduitMarchantScreenState();
}

class _DetailProduitMarchantScreenState extends State<DetailProduitMarchantScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _badgeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ProductService _productService = ProductService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs actuelles
    _nameController.text = widget.productName;
    _priceController.text = widget.productPrice;
    _stockController.text = widget.productStock;
    _badgeController.text = widget.productBadge;
    _descriptionController.text = widget.productBadge; // Utiliser le badge comme description par défaut
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _badgeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_stockController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir le nouveau stock'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _productService.updateProductStock(
        productId: widget.productId,
        newStock: int.parse(_stockController.text),
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Navigator.of(context).pop(); // Fermer le modal
        Navigator.of(context).pop(); // Retour à la page précédente
        
        // Rafraîchir la liste des produits
        context.read<ProductCubit>().fetchProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text('Modifier le stock',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Nouveau stock',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Ex: 50',
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Mise à jour du stock...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : const Text(
                                'Mettre à jour le stock',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text('Êtes-vous sûr de vouloir supprimer "${widget.productName}" ?\n\nCette action est irréversible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _deleteProduct(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Supprimer', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _productService.deleteProduct(
        productId: widget.productId,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        Navigator.of(context).pop(); // Fermer le dialogue de confirmation
        Navigator.of(context).pop(); // Retour à la page précédente
        
        // Rafraîchir la liste des produits
        context.read<ProductCubit>().fetchProducts();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        Navigator.of(context).pop(); // Fermer le dialogue de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Navigator.of(context).pop(); // Fermer le dialogue de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayImageUrl = (widget.productImageUrl.isEmpty || widget.productImageUrl == 'null')
        ? 'https://via.placeholder.com/300x200'
        : widget.productImageUrl.startsWith('http')
            ? widget.productImageUrl
            : 'http://24.144.87.127:3333/${widget.productImageUrl}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails du produit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditDialog,
            tooltip: 'Modifier le stock',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Supprimer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                child: Image.network(
                  displayImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey, size: 80),
                  ),

                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge/Catégorie
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isPromo ? Colors.redAccent : AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.productBadge,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nom du produit
                  Text(
                    widget.productName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Prix
                  Text(
                    '${widget.productPrice} FC',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: widget.isPromo ? Colors.red : Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Informations détaillées
                  _buildInfoCard(
                    icon: Icons.inventory_2,
                    title: 'Stock disponible',
                    value: '${widget.productStock} unités',
                    color: Colors.blue,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    icon: Icons.category,
                    title: 'Catégorie',
                    value: widget.productBadge,
                    color: Colors.orange,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  _buildInfoCard(
                    icon: Icons.local_offer,
                    title: 'Statut',
                    value: widget.isPromo ? 'En promotion' : 'Prix normal',
                    color: widget.isPromo ? Colors.red : Colors.green,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Boutons d'action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showEditDialog,
                          icon: const Icon(Icons.edit, color: Colors.white),
                          label: const Text(
                            'Modifier le stock',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showDeleteConfirmation,
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            'Supprimer',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 