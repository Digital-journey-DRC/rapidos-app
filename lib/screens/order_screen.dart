import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
    if (!_hasFetchedOrders && authState is AuthSuccess && !isLivreur) {
      _hasFetchedOrders = true;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.buttonColor2;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'en route pour livraison':
        return Colors.green;
      case 'a la recherche du livreur':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'EN ATTENTE';
      case 'delivered':
        return 'LIVRÉ';
      case 'cancelled':
        return 'ANNULÉ';
      case 'en route pour livraison':
        return 'EN ROUTE';
      case 'a la recherche du livreur':
        return 'RECHERCHE LIVREUR';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      return const Center(child: Text('Non authentifié'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Commandes'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (authState.user!['role'] == 'livreur')
              _buildLivreurOrders()
            else if (authState.user!['role'] == 'vendeur')
              _buildVendeurOrders()
            else
              _buildClientOrders(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientOrders() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return const Center(
        child: Text('Veuillez vous connecter pour voir vos commandes'),
      );
    }

    final userId = authState.user!['id']?.toString() ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .where('idClient', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erreur Firestore: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande trouvée',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          );
        }

        // Trier les documents côté client
        final sortedDocs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTimestamp = aData['timestamp'] as Timestamp?;
            final bTimestamp = bData['timestamp'] as Timestamp?;
            
            if (aTimestamp == null && bTimestamp == null) return 0;
            if (aTimestamp == null) return 1;
            if (bTimestamp == null) return -1;
            
            return bTimestamp.compareTo(aTimestamp); // Tri décroissant
          });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            try {
              final doc = sortedDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Vérification et conversion sécurisée des items
              List<Map<String, dynamic>> items = [];
              if (data['items'] != null) {
                if (data['items'] is List) {
                  items = List<Map<String, dynamic>>.from(
                    (data['items'] as List).map((item) {
                      if (item is Map) {
                        return Map<String, dynamic>.from(item);
                      }
                      return <String, dynamic>{};
                    }),
                  );
                }
              }
              
              final firstItem = items.isNotEmpty ? items[0] : null;
              final status = data['status']?.toString() ?? 'pending';
              final timestamp = data['timestamp'] as Timestamp?;
              final adresse = data['adresse']?.toString() ?? 'Adresse non spécifiée';
              
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  // TODO: Ajouter la navigation vers les détails de la commande
                },
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
                              child: firstItem != null && firstItem['imagePath'] != null
                                  ? Image.network(
                                      firstItem['imagePath'],
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Erreur de chargement image: $error');
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image, color: Colors.grey),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, color: Colors.grey),
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
                                      Expanded(
                                        child: Text(
                                          firstItem?['name'] ?? 'Produit',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _translateStatus(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    adresse,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(timestamp),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.shopping_cart, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${items.length} article${items.length > 1 ? 's' : ''}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Spacer(),
                                      if (status.toLowerCase() == 'pending')
                                        Container(
                                          margin: const EdgeInsets.only(right: 16),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text('Annuler la commande'),
                                                  content: const Text('Êtes-vous sûr de vouloir annuler cette commande ?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context),
                                                      child: const Text('NON'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () async {
                                                        try {
                                                          await FirebaseFirestore.instance
                                                              .collection('carts')
                                                              .doc(doc.id)
                                                              .update({'status': 'cancelled'});
                                                          if (mounted) {
                                                            Navigator.pop(context);
                                                            setState(() {}); // Force refresh
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('Commande annulée avec succès'),
                                                                backgroundColor: Colors.green,
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            Navigator.pop(context);
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('Erreur lors de l\'annulation: $e'),
                                                                backgroundColor: Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      child: const Text('OUI'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.cancel_outlined, size: 16, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Annuler',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (authState.user!['role'] == 'vendeur' && status.toLowerCase() == 'pending')
                                        Container(
                                          margin: const EdgeInsets.only(right: 16),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('carts')
                                                    .doc(doc.id)
                                                    .update({'status': 'en route pour livraison'});
                                                if (mounted) {
                                                  setState(() {}); // Force refresh
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Commande marquée comme prête pour livraison'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Erreur: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.buttonColor2,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.local_shipping_outlined, size: 16, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Prêt pour livraison',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      if (status.toLowerCase() == 'pending')
                                        Container(
                                          margin: const EdgeInsets.only(right: 16),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                // Mettre à jour le statut dans Firestore
                                                await FirebaseFirestore.instance
                                                    .collection('carts')
                                                    .doc(doc.id)
                                                    .update({'status': 'a la recherche du livreur'});
                                                
                                                if (mounted) {
                                                  // Forcer le rafraîchissement de l'interface
                                                  setState(() {
                                                    // Mettre à jour le statut localement
                                                    data['status'] = 'a la recherche du livreur';
                                                  });
                                                  
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Commande en attente de livreur'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Erreur: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.buttonColor2,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.local_shipping_outlined, size: 16, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Prêt pour livraison',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                ),
              );
            } catch (e) {
              print('Erreur lors de l\'affichage de la commande: $e');
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Erreur lors de l\'affichage de la commande',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLivreurOrders() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess) {
      return const Center(child: Text('Non authentifié'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .where('status', whereIn: ['a la recherche du livreur', 'en route pour livraison'])
          .where('livreurId', isEqualTo: authState.user!['id'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              const OrderCardShimmer(),
              const SizedBox(height: 10),
              const OrderCardShimmer(),
            ],
          );
        }

        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Center(child: Text('Aucune commande en attente de livreur'));
        }

        return Column(
          children: orders.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final items = data['items'] as List? ?? [];
            final status = data['status']?.toString() ?? 'pending';
            final timestamp = data['timestamp'] as Timestamp?;
            final date = timestamp?.toDate().toString().substring(0, 10) ?? '';
            final address = data['address']?.toString() ?? 'Adresse non spécifiée';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
              child: Column(
                children: [
                  Row(
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
                            items.isNotEmpty ? (items[0]['imagePath'] ?? 'https://via.placeholder.com/80') : 'https://via.placeholder.com/80',
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
                                      items.isNotEmpty ? (items[0]['name'] ?? 'Produit') : 'Produit',
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
                                      _translateStatus(status),
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
                                '${items.length} article${items.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 13, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Bouton pour accepter la livraison
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: status == 'a la recherche du livreur' ? () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('carts')
                              .doc(doc.id)
                              .update({
                            'status': 'en route pour livraison',
                            'livreurId': authState.user!['id'],
                            'livreurName': authState.user!['name'],
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Commande acceptée avec succès'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: status == 'a la recherche du livreur' 
                            ? AppColors.primary 
                            : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: Text(
                        status == 'a la recherche du livreur' 
                            ? 'Accepter la livraison'
                            : 'En cours de livraison',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVendeurOrders() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return const Center(
        child: Text('Veuillez vous connecter pour voir vos commandes'),
      );
    }

    final userId = authState.user!['id']?.toString() ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('carts')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Erreur Firestore: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 50, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingShimmer();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande reçue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          );
        }

        // Filtrer les commandes côté client
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['items'] == null) return false;
          
          final items = data['items'] as List;
          return items.any((item) {
            if (item is Map) {
              return item['idVendeur'] == userId;
            }
            return false;
          });
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: AppColors.buttonColor.withOpacity(0.3)),
                const SizedBox(height: 18),
                const Text(
                  'Aucune commande reçue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
          );
        }

        // Trier les commandes par date
        filteredDocs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTimestamp = aData['timestamp'] as Timestamp?;
          final bTimestamp = bData['timestamp'] as Timestamp?;
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          
          return bTimestamp.compareTo(aTimestamp); // Tri décroissant
        });

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            try {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // Filtrer les items pour ne montrer que ceux du vendeur
              List<Map<String, dynamic>> items = [];
              if (data['items'] != null) {
                if (data['items'] is List) {
                  items = List<Map<String, dynamic>>.from(
                    (data['items'] as List).where((item) {
                      if (item is Map) {
                        return item['idVendeur'] == userId;
                      }
                      return false;
                    }).map((item) => Map<String, dynamic>.from(item)),
                  );
                }
              }
              
              if (items.isEmpty) return const SizedBox.shrink();
              
              final firstItem = items.isNotEmpty ? items[0] : null;
              final status = data['status']?.toString() ?? 'pending';
              final timestamp = data['timestamp'] as Timestamp?;
              final adresse = data['adresse']?.toString() ?? 'Adresse non spécifiée';
              
              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  // TODO: Ajouter la navigation vers les détails de la commande
                },
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
                              child: firstItem != null && firstItem['imagePath'] != null
                                  ? Image.network(
                                      firstItem['imagePath'],
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Erreur de chargement image: $error');
                                        return Container(
                                          width: 70,
                                          height: 70,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image, color: Colors.grey),
                                        );
                                      },
                                    )
                                  : Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.image, color: Colors.grey),
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
                                      Expanded(
                                        child: Text(
                                          firstItem?['name'] ?? 'Produit',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _translateStatus(status),
                                          style: TextStyle(
                                            color: _statusColor(status),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    adresse,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(timestamp),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(Icons.shopping_cart, size: 14, color: AppColors.primary),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${items.length} article${items.length > 1 ? 's' : ''}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Spacer(),
                                      if (status.toLowerCase() == 'pending')
                                        Container(
                                          margin: const EdgeInsets.only(right: 16),
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('carts')
                                                    .doc(doc.id)
                                                    .update({'status': 'a la recherche du livreur'});
                                                if (mounted) {
                                                  setState(() {}); // Force refresh
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Commande en attente de livreur'),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Erreur: $e'),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              elevation: 2,
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.local_shipping_outlined, size: 16, color: Colors.white),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Prêt pour livraison',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
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
                ),
              );
            } catch (e) {
              print('Erreur lors de l\'affichage de la commande: $e');
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'Erreur lors de l\'affichage de la commande',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.separated(
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
    );
  }
}

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
    );
  }
}