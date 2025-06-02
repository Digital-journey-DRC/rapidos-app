import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/favorites_cubit.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({Key? key}) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}
class _OrderScreenState extends State<OrderScreen> {
  late AuthState authState;
  late bool isLivreur;
  bool _hasFetchedOrders = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authState = context.watch<AuthCubit>().state;
    isLivreur = authState is AuthSuccess && 
        (authState as AuthSuccess).user != null &&
        (authState as AuthSuccess).user!['role'] == 'livreur';
    if (!_hasFetchedOrders && authState is AuthSuccess) {
      context.read<OrderCubit>().fetchOrders();
      _hasFetchedOrders = true;
    }
  }

  @override
  void initState() {
    super.initState();
    // Ne rien faire ici pour fetchOrders
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'en attente':
        return AppColors.buttonColor;
      case 'livrée':
        return Colors.green;
      case 'annulée':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderCubit = context.watch<OrderCubit>();
    final orderListState = orderCubit.orderListState;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(isLivreur == true? 'Livraisons' : 'Mes Commandes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: orderListState.isLoading
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline shimmer
                          Container(
                            width: 6,
                            height: 110,
                            margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.buttonColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          // Image shimmer
                          Padding(
                            padding: const EdgeInsets.only(top: 16, left: 0, right: 10),
                            child: ShimmerLoading(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          // Détails shimmer
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      ShimmerLoading(
                                        width: 90,
                                        height: 16,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      const SizedBox(width: 8),
                                      ShimmerLoading(
                                        width: 60,
                                        height: 16,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ShimmerLoading(
                                    width: 120,
                                    height: 12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ShimmerLoading(
                                        width: 60,
                                        height: 12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      const SizedBox(width: 12),
                                      ShimmerLoading(
                                        width: 50,
                                        height: 14,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ShimmerLoading(
                                        width: 80,
                                        height: 12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      const SizedBox(width: 8),
                                      ShimmerLoading(
                                        width: 60,
                                        height: 12,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          : orderListState.error != null
              ? Center(child: Text(orderListState.error!, style: const TextStyle(color: Colors.red)))
              : orderListState.commandes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox, size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                          const SizedBox(height: 18),
                          const Text('Aucune commande trouvée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemCount: orderListState.commandes.length,
                      itemBuilder: (context, index) {
                        final commande = orderListState.commandes[index];
                        final commandeData = commande['commande'];
                        final user = commandeData != null ? commandeData['user'] : null;
                        final status = commandeData != null ? (commandeData['status'] ?? '') : '';
                        final date = commande['createdAt']?.toString().substring(0, 10) ?? '';
                        final product = commande['product'] ?? {};
                        final imageUrl = product['media'] != null && product['media']['mediaUrl'] != null
                            ? 'http://24.144.87.127:3333/${product['media']['mediaUrl']}'
                            : 'https://via.placeholder.com/80';
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {},
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.06),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Timeline
                                    Container(
                                      width: 6,
                                      height: 110,
                                      margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                                      decoration: BoxDecoration(
                                        color: _statusColor(status),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    // Image produit
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16, left: 0, right: 10),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.network(
                                          imageUrl,
                                          width: 70,
                                          height: 70,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Container(
                                              width: 70,
                                              height: 70,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.image, color: Colors.grey),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    // Détails commande
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    product['name'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                      color: AppColors.primary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _statusColor(status).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    status.isNotEmpty ? status.toUpperCase() : 'N/A',
                                                    style: TextStyle(
                                                      color: _statusColor(status),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product['description'] ?? '',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                // Text(
                                                //   // 'Quantité : ${commande['quantity']}',
                                                //   "Prix: ${commandeData['totalPrice']} FC",
                                                //   style: const TextStyle(fontSize: 13),
                                                // ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  "Prix: ${commandeData['totalPrice']} FC",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: AppColors.buttonColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            if (user != null)
                                              Row(
                                                children: [
                                                  const Icon(Icons.person, size: 14, color: AppColors.primary),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                                                    style: const TextStyle(fontSize: 13),
                                                  ),
                                                ],
                                              ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.calendar_today, size: 13, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.buttonColor.withOpacity(0.13),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    date,
                                                    style: const TextStyle(fontSize: 12, color: AppColors.buttonColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isLivreur)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 12.0),
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      // TODO: Action pour prendre la commande
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: AppColors.buttonColor,
                                                      foregroundColor: Colors.white,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                                      elevation: 0,
                                                    ),
                                                    child: const Text(
                                                      'Prendre la commande',
                                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
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
                    ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonColor,
        onPressed: () => context.read<OrderCubit>().fetchOrders(),
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }
}