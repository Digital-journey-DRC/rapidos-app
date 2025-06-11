import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:immo/widgets/cart_badge.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/auth_cubit.dart';

class CartScreen extends StatelessWidget {
  final bool backNavigaton;
  const CartScreen({Key? key, this.backNavigaton = true}) : super(key: key);

  void saveCart(BuildContext context, List<Map<String, dynamic>> cartItems, String ville, String commune, String quartier, String avenue, String numero, String pays) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      final user = authState.user!;
      final userId = user['id']?.toString() ?? '';
      final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      
      // Construire l'adresse complète
      final adresse = '$avenue, $numero, $quartier, $commune, $ville, $pays';

      // Enregistrer la commande
      DocumentReference commandeRef = await FirebaseFirestore.instance.collection('carts').add({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
        'phone': user['phone'] ?? '',
        'items': cartItems,
        'client': userName,
        'adresse': adresse, // ID du vendeur par défaut
        'idClient': userId,
        'ville': ville,
        'commune': commune,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numero,
        'pays': pays
      });

      print("✅ Commande enregistrée avec succès: ${commandeRef.id}");
    } else {
      print("❌ Utilisateur non connecté");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour passer une commande'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Liste des villes de la RDC
  static const List<String> villes = [
    'Kinshasa',
    'Lubumbashi',
    'Mbuji-Mayi',
    'Kananga',
    'Kisangani',
    'Bukavu',
    'Goma',
    'Kolwezi',
    'Likasi',
    'Matadi',
    'Kikwit',
    'Tshikapa',
    'Uvira',
    'Bunia',
    'Kalemie',
    'Kindu',
    'Mbandaka',
    'Mbanza-Ngungu',
    'Boma',
    'Kamina',
  ];

  // Liste des communes de Kinshasa
  static const List<String> communesKinshasa = [
    'Bandalungwa',
    'Barumbu',
    'Bumbu',
    'Gombe',
    'Kalamu',
    'Kasa-Vubu',
    'Kimbanseke',
    'Kinshasa',
    'Kintambo',
    'Kisenso',
    'Lemba',
    'Limete',
    'Lingwala',
    'Makala',
    'Maluku',
    'Masina',
    'Matete',
    'Mont Ngafula',
    'Ndjili',
    'Ngaba',
    'Ngaliema',
    'Ngiri-Ngiri',
    'Nsele',
    'Selembao',
  ];

  void _showAddressBottomSheet(BuildContext context, List<Map<String, dynamic>> cartItems) {
    final _villeController = TextEditingController();
    final _communeController = TextEditingController();
    final _quartierController = TextEditingController();
    final _avenueController = TextEditingController();
    final _codePostaleController = TextEditingController();
    final _numeroController = TextEditingController();
    final _paysController = TextEditingController(text: 'RDC');
    String? selectedVille;
    String? selectedCommune;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return BlocConsumer<OrderCubit, OrderState>(
              listener: (context, state) {
                if (state.success) {
                  Navigator.pop(context); // Fermer le bottom sheet
                  context.read<CartCubit>().clearCart(); // Vider le panier
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Commande créée avec succès!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else if (state.error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.error!),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
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
                        const Text(
                          'Adresse de livraison',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: selectedVille,
                          decoration: InputDecoration(
                            labelText: 'Ville',
                            prefixIcon: const Icon(Icons.location_city),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: villes.map((String ville) {
                            return DropdownMenuItem<String>(
                              value: ville,
                              child: Text(ville),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedVille = newValue;
                              _villeController.text = newValue ?? '';
                              // Réinitialiser la commune si la ville change
                              selectedCommune = null;
                              _communeController.text = '';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedCommune,
                          decoration: InputDecoration(
                            labelText: 'Commune',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          items: selectedVille == 'Kinshasa' 
                              ? communesKinshasa.map((String commune) {
                                  return DropdownMenuItem<String>(
                                    value: commune,
                                    child: Text(commune),
                                  );
                                }).toList()
                              : [], // Liste vide pour les autres villes
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedCommune = newValue;
                              _communeController.text = newValue ?? '';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quartierController,
                          decoration: InputDecoration(
                            labelText: 'Quartier',
                            prefixIcon: const Icon(Icons.map),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _avenueController,
                          decoration: InputDecoration(
                            labelText: 'Avenue',
                            prefixIcon: const Icon(Icons.streetview),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _numeroController,
                          decoration: InputDecoration(
                            labelText: 'Numéro',
                            prefixIcon: const Icon(Icons.home),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _paysController,
                          enabled: false,
                          decoration: InputDecoration(
                            labelText: 'Pays',
                            prefixIcon: const Icon(Icons.public),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: state.isLoading
                                ? null
                                : () {
                                    if (_villeController.text.isEmpty ||
                                        _communeController.text.isEmpty ||
                                        _quartierController.text.isEmpty ||
                                        _avenueController.text.isEmpty ||
                                        _numeroController.text.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Veuillez remplir tous les champs'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Vérification de la présence de l'id sur chaque produit
                                    if (cartItems.any((item) => item['id'] == null)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Un produit du panier est invalide (id manquant). Veuillez le retirer.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    // Convertir les items du panier au format attendu par l'API
                                    final produits = cartItems.map((item) {
                                      return {
                                        "id": int.parse(item['id'].toString()),
                                        "quantity": item['quantity'],
                                      };
                                    }).toList();

                                    // Utilise la méthode http classique
                                    context.read<OrderCubit>().createOrder(
                                          produits: produits,
                                          ville: _villeController.text,
                                          commune: _communeController.text,
                                          quartier: _quartierController.text,
                                          avenue: _avenueController.text,
                                          codePostale: _codePostaleController.text,
                                          numero: _numeroController.text,
                                          pays: _paysController.text,
                                        );
                                        
                                    // Enregistrer dans Firebase
                                    saveCart(
                                      context,
                                      cartItems,
                                      _villeController.text,
                                      _communeController.text,
                                      _quartierController.text,
                                      _avenueController.text,
                                      _numeroController.text,
                                      _paysController.text
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state.isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    'CONFIRMER LA COMMANDE',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final cartItems = state.items;
        final total = cartItems.fold<double>(0, (sum, item) {
          final price = double.tryParse(item['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          return sum + (price * (item['quantity'] as int));
        });
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Mon Panier',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: backNavigaton ? IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ) : null,
          ),
          body: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Votre panier est vide',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des articles pour commencer vos achats',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Image du produit
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item['imagePath'],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          color: Colors.grey.shade200,
                                          child: Icon(Icons.image, color: Colors.grey.shade400),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Détails du produit
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['category'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          item['price'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Contrôles de quantité
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          context.read<CartCubit>().removeFromCart(item['name']);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Article retiré du panier'),
                                              backgroundColor: AppColors.primary,
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        },
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 16),
                                              onPressed: () {
                                                final newQty = (item['quantity'] as int) - 1;
                                                if (newQty > 0) {
                                                  context.read<CartCubit>().updateQuantity(item['name'], newQty);
                                                }
                                              },
                                            ),
                                            Text(
                                              '${item['quantity']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 16),
                                              onPressed: () async {
                                                final newQty = (item['quantity'] as int) + 1;
                                                final stock = item['stock'] ?? 1;
                                                if (newQty > stock) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Stock insuffisant : il ne reste que $stock en stock.'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                  return;
                                                }
                                                final success = await context.read<CartCubit>().updateQuantity(item['name'], newQty);
                                                if (!success) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Stock insuffisant : il ne reste que $stock en stock.'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Résumé et bouton de paiement
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} FC',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                _showAddressBottomSheet(context, cartItems);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'PROCÉDER AU PAIEMENT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
} 