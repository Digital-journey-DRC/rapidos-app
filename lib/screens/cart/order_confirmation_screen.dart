import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../order_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic> address;

  const OrderConfirmationScreen({
    Key? key,
    required this.cartItems,
    required this.address,
  }) : super(key: key);

  double _calculateTotal() {
    double total = 0.0;
    for (var item in cartItems) {
      final price = (item['price'] ?? 0.0) is double
          ? item['price'] as double
          : (item['price'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 1) is int
          ? item['quantity'] as int
          : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      total += price * quantity;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirmation de commande',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message de succès
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Commande initialisée avec succès!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Votre commande a été enregistrée et est en attente de paiement.',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section adresse
                  const Text(
                    'Adresse de livraison',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address is Map<String, String>
                                    ? '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}'
                                    : '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address is Map<String, String>
                                    ? '${address['quartier'] ?? ''}, ${address['commune'] ?? ''}'
                                    : '${address['quartier'] ?? ''}, ${address['commune'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              Text(
                                address is Map<String, String>
                                    ? '${address['ville'] ?? ''}, ${address['pays'] ?? 'RDC'}'
                                    : '${address['ville'] ?? ''}, ${address['pays'] ?? 'RDC'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section produits commandés
                  const Text(
                    'Produits commandés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...cartItems.map((item) {
                    final price = (item['price'] ?? 0.0) is double
                        ? item['price'] as double
                        : (item['price'] ?? 0).toDouble();
                    final quantity = (item['quantity'] ?? 1) is int
                        ? item['quantity'] as int
                        : int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
                    final itemTotal = price * quantity;
                    final imageUrl = item['image']?.toString() ?? '';
                    final productName = item['name']?.toString() ?? 'Produit';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Image du produit
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image_not_supported),
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Détails du produit
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quantité: $quantity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${price.toStringAsFixed(0)} FC × $quantity',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Prix total
                          Text(
                            '${itemTotal.toStringAsFixed(0)} FC',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 16),

                  // Résumé total
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bouton pour voir les commandes
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // Vider le panier
                  context.read<CartCubit>().clearCart();
                  // Rafraîchir les commandes
                  context.read<OrderCubit>().fetchOrders();
                  // Naviguer vers l'écran des commandes
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderScreen(
                        backNavigation: true,
                        initialStatusFilter: 'pending_payment',
                      ),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'VOIR MES COMMANDES',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

