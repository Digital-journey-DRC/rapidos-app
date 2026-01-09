import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/ecommerce_loading.dart';
import 'package:immo/services/payment_method_service.dart';

class PendingPaymentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const PendingPaymentDetailScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<PendingPaymentDetailScreen> createState() => _PendingPaymentDetailScreenState();
}

class _PendingPaymentDetailScreenState extends State<PendingPaymentDetailScreen> {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  Map<int, List<Map<String, dynamic>>> _vendeurPaymentMethods = {};
  Map<int, Map<String, dynamic>> _selectedPaymentMethods = {};

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    _initializeSelectedPaymentMethods();
  }

  void _initializeSelectedPaymentMethods() {
    final order = widget.order;
    final vendeurId = order['vendeurId'] as int? ?? 0;
    final paymentMethod = order['paymentMethod'] as Map<String, dynamic>?;
    if (vendeurId > 0 && paymentMethod != null) {
      _selectedPaymentMethods[vendeurId] = paymentMethod;
    }
    
    // Initialiser aussi pour les autres marchands si la commande contient des produits de plusieurs marchands
    final products = order['products'] as List? ?? [];
    for (var product in products) {
      final productVendeurId = product['idVendeur'] as int? ?? 0;
      if (productVendeurId > 0 && productVendeurId != vendeurId) {
        // Si le produit appartient à un autre marchand, on initialise avec le moyen de paiement par défaut
        if (!_selectedPaymentMethods.containsKey(productVendeurId) && paymentMethod != null) {
          _selectedPaymentMethods[productVendeurId] = Map<String, dynamic>.from(paymentMethod);
        }
      }
    }
  }

  Future<void> _loadPaymentMethods() async {
    final order = widget.order;
    final products = order['products'] as List? ?? [];
    
    // Extraire les IDs des vendeurs uniques (vendeur principal + marchands des produits)
    final vendeurIds = <int>{};
    final vendeurId = order['vendeurId'] as int? ?? 0;
    if (vendeurId > 0) {
      vendeurIds.add(vendeurId);
    }
    
    for (var product in products) {
      final productVendeurId = product['idVendeur'] as int? ?? 0;
      if (productVendeurId > 0) {
        vendeurIds.add(productVendeurId);
      }
    }

    // Charger les moyens de paiement pour chaque vendeur
    final paymentMethodsMap = <int, List<Map<String, dynamic>>>{};
    for (final vid in vendeurIds) {
      try {
        final result = await _paymentMethodService.getVendeurPaymentMethodsForClient(vid);
        if (result['success'] == true) {
          paymentMethodsMap[vid] = List<Map<String, dynamic>>.from(result['paymentMethods'] ?? []);
        }
      } catch (e) {
        print('Erreur lors du chargement des moyens de paiement pour vendeur $vid: $e');
      }
    }
    
    setState(() {
      _vendeurPaymentMethods = paymentMethodsMap;
    });
  }

  // Grouper les produits par marchand (idVendeur)
  Map<int, List<Map<String, dynamic>>> _groupProductsByVendeur() {
    final order = widget.order;
    final products = order['products'] as List? ?? [];
    final grouped = <int, List<Map<String, dynamic>>>{};
    
    for (var product in products) {
      final productVendeurId = product['idVendeur'] as int? ?? 0;
      if (productVendeurId > 0) {
        if (!grouped.containsKey(productVendeurId)) {
          grouped[productVendeurId] = [];
        }
        grouped[productVendeurId]!.add(product as Map<String, dynamic>);
      }
    }
    
    return grouped;
  }
  
  // Obtenir les informations du vendeur/marchand
  Map<String, dynamic>? _getVendeurInfo(int vendeurId) {
    final order = widget.order;
    final mainVendeurId = order['vendeurId'] as int? ?? 0;
    
    // Si c'est le vendeur principal, utiliser les infos de la commande
    if (vendeurId == mainVendeurId) {
      return order['vendeur'] as Map<String, dynamic>?;
    }
    
    // Sinon, chercher dans les produits (on pourrait avoir besoin d'une API pour ça)
    // Pour l'instant, on retourne null et on utilisera juste l'ID
    return null;
  }
  

  double _parseAmount(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showPaymentMethodSelection(int vendeurId, Map<String, dynamic> currentPaymentMethod) {
    final paymentMethods = _vendeurPaymentMethods[vendeurId];
    if (paymentMethods == null || paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun moyen de paiement disponible'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir un moyen de paiement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: paymentMethods.length,
                itemBuilder: (context, index) {
                  final method = paymentMethods[index];
                  final isSelected = method['id'] == currentPaymentMethod['id'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: method['imageUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: method['imageUrl'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.payment),
                            ),
                      title: Text(
                        method['name'] ?? 'Moyen de paiement',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        method['numeroCompte'] ?? '',
                        style: TextStyle(
                          color: isSelected ? AppColors.primary : Colors.grey.shade600,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethods[vendeurId] = method;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Calculer les totaux pour un marchand (basé sur ses produits)
  Map<String, double> _calculateVendeurTotals(List<Map<String, dynamic>> products) {
    double totalProducts = 0.0;

    for (var product in products) {
      final price = _parseAmount(product['price']);
      final quantity = product['quantity'] as int? ?? 1;
      totalProducts += price * quantity;
    }

    return {
      'products': totalProducts,
    };
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final products = order['products'] as List? ?? [];
    final groupedProducts = _groupProductsByVendeur();
    final orderId = order['orderId']?.toString() ?? '';
    final address = order['address'] as Map<String, dynamic>? ?? {};
    final distanceKm = order['distanceKm']?.toString() ?? '';
    final total = _parseAmount(order['total']);
    final deliveryFee = _parseAmount(order['deliveryFee']);
    final totalWithDelivery = _parseAmount(order['totalAvecLivraison']);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Détails de la commande',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement confirmé avec succès!'),
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
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête de la commande
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.primary.withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.shopping_bag,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Commande #${orderId.length > 8 ? orderId.substring(0, 8) : orderId}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${products.length} ${products.length > 1 ? 'produits' : 'produit'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${totalWithDelivery.toStringAsFixed(0)} FC',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Adresse de livraison
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
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
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Adresse de livraison',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(left: 44),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${address['avenue'] ?? ''}, ${address['numero'] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${address['quartier'] ?? ''}, ${address['commune'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Text(
                                    '${address['ville'] ?? ''}, ${address['pays'] ?? 'RDC'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (distanceKm.isNotEmpty && distanceKm != '0')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.straighten, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Distance: $distanceKm km',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Afficher chaque marchand dans son container
                      ...groupedProducts.entries.map((entry) {
                        final vendeurId = entry.key;
                        final vendeurProducts = entry.value;
                        final vendeurInfo = _getVendeurInfo(vendeurId);
                        final vendeurName = vendeurInfo != null
                            ? '${vendeurInfo['firstName'] ?? ''} ${vendeurInfo['lastName'] ?? ''}'.trim()
                            : 'Marchand #$vendeurId';
                        final vendeurTotals = _calculateVendeurTotals(vendeurProducts);
                        final selectedPaymentMethod = _selectedPaymentMethods[vendeurId] ?? order['paymentMethod'] as Map<String, dynamic>?;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // En-tête vendeur
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.store,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            vendeurName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          if (vendeurInfo != null && vendeurInfo['phone'] != null)
                                            Text(
                                              vendeurInfo['phone'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Liste des produits de ce marchand
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...vendeurProducts.map((product) {
                                    final productName = product['name']?.toString() ?? 'Produit';
                                    final quantity = product['quantity'] as int? ?? 1;
                                    final price = _parseAmount(product['price']);
                                    final productTotal = price * quantity;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  productName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Quantité: $quantity × ${price.toStringAsFixed(0)} FC',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '${productTotal.toStringAsFixed(0)} FC',
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
                                ],
                              ),
                            ),

                              const SizedBox(height: 16),

                              // Moyen de paiement pour ce vendeur
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.payment, size: 18, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Moyen de paiement',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.edit, size: 18),
                                          onPressed: selectedPaymentMethod != null
                                              ? () => _showPaymentMethodSelection(vendeurId, selectedPaymentMethod)
                                              : null,
                                          color: AppColors.primary,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    if (selectedPaymentMethod != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          if (selectedPaymentMethod['imageUrl'] != null)
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(6),
                                              child: CachedNetworkImage(
                                                imageUrl: selectedPaymentMethod['imageUrl'],
                                                width: 32,
                                                height: 32,
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          else
                                            Icon(Icons.payment, size: 20, color: Colors.grey.shade600),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedPaymentMethod['name'] ?? 'Cash',
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (selectedPaymentMethod['numeroCompte'] != null)
                                                  Text(
                                                    selectedPaymentMethod['numeroCompte'],
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Récap pour ce vendeur
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Total produits',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        Text(
                                          '${vendeurTotals['products']!.toStringAsFixed(0)} FC',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 16),

                      // Récap global
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sous-total produits',
                                  style: TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${total.toStringAsFixed(0)} FC',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (deliveryFee > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Frais de livraison',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    '${deliveryFee.toStringAsFixed(0)} FC',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total à payer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${totalWithDelivery.toStringAsFixed(0)} FC',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () async {
                        // Vérifier que le moyen de paiement est sélectionné
                        final order = widget.order;
                        final vendeurId = order['vendeurId'] as int? ?? 0;
                        final selectedPaymentMethod = _selectedPaymentMethods[vendeurId] ?? order['paymentMethod'] as Map<String, dynamic>?;
                        
                        if (selectedPaymentMethod == null || selectedPaymentMethod['id'] == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez sélectionner un moyen de paiement'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                          return;
                        }

                        // Mettre à jour le moyen de paiement pour cette commande
                        await context.read<OrderCubit>().updatePaymentMethod(
                              orderId: order['id'] as int,
                              paymentMethodId: selectedPaymentMethod['id'] as int,
                            );

                        await Future.delayed(const Duration(milliseconds: 500));
                        await context.read<OrderCubit>().fetchOrders(status: 'pending_payment');

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Paiement confirmé avec succès!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          Navigator.pop(context);
                        }
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
                child: state.isLoading
                    ? const EcommerceLoading.inline(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'PASSER À LA COMMANDE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

