import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/home/voir_plus_produits.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/services/storage_service.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class HomeMarchantScreen extends StatefulWidget {
  const HomeMarchantScreen({Key? key}) : super(key: key);

  @override
  State<HomeMarchantScreen> createState() => _HomeMarchantScreenState();
}

class _HomeMarchantScreenState extends State<HomeMarchantScreen> {
  final List<Map<String, String>> _products = [
    {
      'badge': 'Nouveau',
      'name': 'Produit 1',
      'stock': 'In Stock',
      'isPromo': 'false',
      'imageUrl':
          'https://images.unsplash.com/photo-1519125323398-675f0ddb6308?auto=format&fit=crop&w=400&q=80',
    },
    {
      'badge': 'Promo',
      'name': 'Produit 2',
      'stock': 'En rupture',
      'isPromo': 'true',
      'imageUrl':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=400&q=80',
    },
  ];

  String? _selectedCategory;
  final List<String> _categories = [
    'Alimentation',
    'Mode',
    'Électronique',
    'sports',
    'Autre',
  ];

  bool _isLoading = false;

  void _showAddProductSheet() {
    final _nameController = TextEditingController();
    final _stockController = TextEditingController();
    final _badgeController = TextEditingController();
    final _priceController = TextEditingController();
    final _categoryController = TextEditingController();
    File? _imageFile;

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
                    const Text('Ajouter un produit',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du produit',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _badgeController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+([.][0-9]{0,2})?')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Prix',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Stock',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        prefixIcon: const Icon(Icons.category_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: _categories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _showImageSourceDialog(context, setState, (file) {
                          _imageFile = file;
                        });
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Ajouter une image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_nameController.text.isNotEmpty &&
                                    _badgeController.text.isNotEmpty &&
                                    _priceController.text.isNotEmpty &&
                                    _stockController.text.isNotEmpty &&
                                    _selectedCategory != null &&
                                    _imageFile != null) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    var request = http.MultipartRequest(
                                      'POST',
                                      Uri.parse('http://24.144.87.127:3333/products/store'),
                                    );
                                    // Headers
                                    final token = await StorageService().getToken();
                                    request.headers.addAll({
                                      'Authorization': 'Bearer $token',
                                    });
                                    // Fields
                                    request.fields.addAll({
                                      'name': _nameController.text,
                                      'description': _badgeController.text,
                                      'price': _priceController.text,
                                      'stock': _stockController.text,
                                      'category': _selectedCategory!,
                                    });
                                    // File
                                    request.files.add(
                                      await http.MultipartFile.fromPath(
                                        'medias',
                                        _imageFile!.path,
                                      ),
                                    );
                                    var response = await request.send();
                                    var responseData = await response.stream.bytesToString();
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    if (response.statusCode == 201) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Produit ajouté avec succès !'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      throw Exception('Erreur lors de l\'ajout du produit : ' + responseData);
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Veuillez remplir tous les champs requis'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Ajouter', style: TextStyle(color: Colors.white)),
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

  void _showImageSourceDialog(BuildContext context, StateSetter setSheetState, Function(File) onImageSelected) {
    final ImagePicker _picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setSheetState(() {
                    onImageSelected(File(image.path));
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_library, size: 40, color: AppColors.buttonColor),
                  SizedBox(height: 8),
                  Text('Galerie'),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setSheetState(() {
                    onImageSelected(File(photo.path));
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.camera_alt, size: 40, color: AppColors.buttonColor),
                  SizedBox(height: 8),
                  Text('Caméra'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(AppAssets.logo, width: 80, height: 80),
          ],
        ),
        actions: const [
          Row(
            children: [
              CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person, color: Colors.white)),
              SizedBox(width: 10),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),
            // Navigation rapide
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QuickNavButton(
                    icon: Icons.local_shipping, label: 'Livraisons'),
                _QuickNavButton(icon: Icons.inventory_2, label: 'Produits'),
                _QuickNavButton(icon: Icons.person, label: 'Profil'),
              ],
            ),
            const SizedBox(height: 12),
            // Profil

            const SizedBox(height: 18),
            // Vos Produits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vos Produits',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VoirPlusProduitsScreen(products: _products),
                      ),
                    );
                  },
                  child: const Text('Voir plus',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _products.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return SizedBox(
                    width: 220,
                    child: _ProductCard(
                      badge: product['badge'] ?? '',
                      name: product['name'] ?? '',
                      stock: product['stock'] ?? '',
                      isPromo: product['isPromo'] == 'true',
                      imageUrl: product['imageUrl'] ?? '',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            // Avis Clients
            const Text('Avis Clients',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _ReviewCard(
                      client: 'Client A',
                      comment: 'Excellent service!',
                      rating: 5),
                  SizedBox(width: 10),
                  _ReviewCard(
                      client: 'Client B',
                      comment: 'Livraison rapide et efficace.',
                      rating: 4),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Livraisons en cours
            const Text('Livraisons en Cours',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            _DeliveryRow(
                title: 'Livraison 1',
                status: 'In Progress',
                livreur: 'Marc',
                icon: Icons.circle,
                iconColor: Colors.red),
            _DeliveryRow(
                title: 'Livraison 2',
                status: 'En attente',
                livreur: 'Sarah',
                icon: Icons.circle,
                iconColor: Colors.orange),
            const SizedBox(height: 18),
            // Carte de livraison
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('Carte de Livraison en Temps Réel',
                      style: TextStyle(color: Colors.black54))),
            ),
            const SizedBox(height: 12),
            // Adresse de livraison
            const Text('Adresse de Livraison',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(
                hintText: "Entrez l'adresse",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 10),
            // Livreurs
            Row(
              children: [
                _ChipButton(label: 'Marc'),
                const SizedBox(width: 8),
                _ChipButton(label: 'Sarah'),
                const SizedBox(width: 8),
                _ChipButton(label: 'Alice'),
              ],
            ),
            const SizedBox(height: 10),
            // Recherche produit
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Recherche de Produits',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                  padding: const EdgeInsets.all(10),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Catégories
            const Text('Catégories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                _CategoryCard(label: 'Alimentation', icon: Icons.fastfood),
                const SizedBox(width: 10),
                _CategoryCard(label: 'Mode', icon: Icons.checkroom),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Ajouter  une catégorie'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Statistiques'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () {},
                    child: const Text('Ajouter un produit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    onPressed: () {},
                    child: const Text('Commandes'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Produits recommandés (carousel placeholder)
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text(
                      'Produits Recommandés')), // Remplacer par un vrai carousel si besoin
            ),
            const SizedBox(height: 18),
            // Statistiques de vente
            const Text('Statistiques de Vente',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Row(
              children: [
                _StatCard(title: 'Ventes', value: '150', percent: '+10%'),
                const SizedBox(width: 10),
                _StatCard(title: 'Clients', value: '200', percent: '-5%'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un produit',
      ),

    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickNavButton({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          padding: const EdgeInsets.all(20),
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String badge;
  final String name;
  final String stock;
  final bool isPromo;
  final String imageUrl;
  const _ProductCard(
      {required this.badge,
      required this.name,
      required this.stock,
      required this.isPromo,
      required this.imageUrl});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: Image.network(
                    imageUrl,
                    width: 64,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 110,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPromo ? Colors.redAccent : AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('Nom du Produit',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      stock,
                      style: TextStyle(
                        color: isPromo ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String client;
  final String comment;
  final int rating;
  const _ReviewCard(
      {required this.client, required this.comment, required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(client,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(
                    rating,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final String title;
  final String status;
  final String livreur;
  final IconData icon;
  final Color iconColor;
  const _DeliveryRow(
      {required this.title,
      required this.status,
      required this.livreur,
      required this.icon,
      required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(status, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text('Livreur: $livreur',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.notifications_active, color: Colors.amber, size: 18),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  const _ChipButton({required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.13),
      labelStyle: const TextStyle(color: AppColors.primary),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CategoryCard({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percent;
  const _StatCard(
      {required this.title, required this.value, required this.percent});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 8),
                Text(percent,
                    style: TextStyle(
                        color:
                            percent.startsWith('+') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
