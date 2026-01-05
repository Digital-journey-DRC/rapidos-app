import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:immo/constants.dart';
import 'package:immo/services/order_service.dart';
import 'package:immo/screens/order_details_screen.dart';

class CommandeClientScreen extends StatefulWidget {
  final bool backNavigation;

  const CommandeClientScreen({
    Key? key,
    this.backNavigation = false,
  }) : super(key: key);

  @override
  State<CommandeClientScreen> createState() => _CommandeClientScreenState();
}

class _CommandeClientScreenState extends State<CommandeClientScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatusFilter = 'Tous';
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _filteredOrders = [];
  String? _error;
  Map<String, bool> _isCancelling = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _searchController.addListener(_filterOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterOrders() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredOrders = _orders;
      } else {
        _filteredOrders = _orders.where((order) {
          final orderId = order['orderId']?.toString().toLowerCase() ?? '';
          final orderIdNum = order['id']?.toString().toLowerCase() ?? '';
          final products = order['products'] as List? ?? [];
          final productNames = products.map((p) => p['name']?.toString().toLowerCase() ?? '').join(' ');
          final vendeur = order['vendeur'] as Map<String, dynamic>? ?? {};
          final vendeurName = '${vendeur['firstName'] ?? ''} ${vendeur['lastName'] ?? ''}'.toLowerCase();
          
          return orderId.contains(query) ||
              orderIdNum.contains(query) ||
              productNames.contains(query) ||
              vendeurName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadOrders({String? status}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _orderService.getAcheteurOrders(status: status);
      
      if (result['success'] == true) {
        setState(() {
          _orders = List<Map<String, dynamic>>.from(result['orders'] ?? []);
          _filteredOrders = _orders;
          _isLoading = false;
        });
        _filterOrders();
      } else {
        setState(() {
          _error = result['message'] ?? 'Erreur lors du chargement des commandes';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 'Paiement en attente';
      case 'pending':
        return 'En attente';
      case 'en_preparation':
      case 'in_preparation':
        return 'En préparation';
      case 'pret_a_expedier':
      case 'ready_to_ship':
        return 'Prêt à expédier';
      case 'en_route':
      case 'in_delivery':
        return 'En route';
      case 'delivered':
        return 'Livré';
      case 'cancelled':
        return 'Annulé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return Icons.payment;
      case 'pending':
        return Icons.hourglass_empty;
      case 'en_preparation':
      case 'in_preparation':
        return Icons.restaurant;
      case 'pret_a_expedier':
      case 'ready_to_ship':
        return Icons.local_shipping;
      case 'en_route':
      case 'in_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      case 'rejected':
        return Icons.block;
      default:
        return Icons.receipt;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return Colors.orange.shade700;
      case 'pending':
        return Colors.blue.shade700;
      case 'en_preparation':
      case 'in_preparation':
        return Colors.orange.shade700;
      case 'pret_a_expedier':
      case 'ready_to_ship':
        return Colors.blue.shade700;
      case 'en_route':
      case 'in_delivery':
        return Colors.green.shade700;
      case 'delivered':
        return Colors.teal.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      case 'rejected':
        return Colors.pink.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Affiche le popup pour annuler une commande
  Future<void> _showCancelOrderDialog(Map<String, dynamic> order) async {
    final TextEditingController reasonController = TextEditingController();
    final orderId = order['id']?.toString() ?? '';
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Annuler',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voulez-vous vraiment annuler cette commande ?',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Raison *',
                    hintText: 'Ex: Changement d\'avis...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.edit, size: 16),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Non', style: TextStyle(fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez renseigner la raison'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Valider', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      },
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      await _cancelOrder(orderId, reasonController.text.trim());
    }
  }

  // Annule une commande
  Future<void> _cancelOrder(String orderId, String reason) async {
    if (orderId.isEmpty) return;

    setState(() {
      _isCancelling[orderId] = true;
    });

    try {
      final result = await _orderService.updateOrderStatus(
        orderId: orderId,
        status: 'cancelled',
        reason: reason,
      );

      setState(() {
        _isCancelling[orderId] = false;
      });

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande annulée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          await _loadOrders(
            status: _selectedStatusFilter == 'Tous' ? null : _selectedStatusFilter,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erreur lors de l\'annulation'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isCancelling[orderId] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () => _loadOrders(
          status: _selectedStatusFilter == 'Tous' ? null : _selectedStatusFilter,
        ),
        child: CustomScrollView(
          slivers: [
          // AppBar avec gradient
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppColors.primary,
            automaticallyImplyLeading: widget.backNavigation,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Mes Commandes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Barre de recherche
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher une commande...',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade600),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),

          // Filtres avec chips
          SliverToBoxAdapter(
            child: Container(
              height: 42,
              margin: const EdgeInsets.only(bottom: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildFilterChip('Tous', Icons.list_alt),
                  _buildFilterChip('pending_payment', Icons.payment),
                  _buildFilterChip('pending', Icons.hourglass_empty),
                  _buildFilterChip('en_preparation', Icons.restaurant),
                  _buildFilterChip('ready_to_ship', Icons.local_shipping),
                  _buildFilterChip('in_delivery', Icons.delivery_dining),
                  _buildFilterChip('delivered', Icons.check_circle),
                  _buildFilterChip('cancelled', Icons.cancel),
                ],
              ),
            ),
          ),

          // Contenu principal
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _buildErrorState(),
            )
          else if (_orders.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else if (_filteredOrders.isEmpty && _searchController.text.isNotEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun résultat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final order = _filteredOrders[index];
                    return _buildOrderCard(order, index);
                  },
                  childCount: _filteredOrders.length,
                ),
              ),
            ),
          
          // Espace en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterChip(String status, IconData icon) {
    final isSelected = _selectedStatusFilter == status;
    final label = status == 'Tous' ? 'Tous' : _translateStatus(status);
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: isSelected ? Colors.white : Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10)),
          ],
        ),
        onSelected: (selected) {
          setState(() {
            _selectedStatusFilter = status;
          });
          _loadOrders(status: status == 'Tous' ? null : status);
        },
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, int index) {
    try {
      final orderId = order['orderId']?.toString() ?? '';
      final orderIdNum = order['id']?.toString() ?? '';
      final status = order['status']?.toString() ?? 'pending';
      final products = order['products'] as List? ?? [];
      
      final totalValue = order['total'];
      final total = totalValue is double 
          ? totalValue 
          : (totalValue is String 
              ? double.tryParse(totalValue) ?? 0.0 
              : (totalValue is int 
                  ? totalValue.toDouble() 
                  : 0.0));
      
      final deliveryFeeValue = order['deliveryFee'];
      final deliveryFee = deliveryFeeValue is double 
          ? deliveryFeeValue 
          : (deliveryFeeValue is String 
              ? double.tryParse(deliveryFeeValue) ?? 0.0 
              : (deliveryFeeValue is int 
                  ? deliveryFeeValue.toDouble() 
                  : 0.0));
      
      final totalAvecLivraisonValue = order['totalAvecLivraison'];
      final totalAvecLivraison = totalAvecLivraisonValue is double 
          ? totalAvecLivraisonValue 
          : (totalAvecLivraisonValue is String 
              ? double.tryParse(totalAvecLivraisonValue) ?? (total + deliveryFee)
              : (totalAvecLivraisonValue is int 
                  ? totalAvecLivraisonValue.toDouble() 
                  : (total + deliveryFee)));
      
      final vendeur = order['vendeur'] as Map<String, dynamic>? ?? {};
      final vendeurFirstName = vendeur['firstName']?.toString() ?? '';
      final vendeurLastName = vendeur['lastName']?.toString() ?? '';
      final vendeurId = order['vendeurId'] ?? vendeur['id'];
      final vendeurName = (vendeurFirstName.isNotEmpty || vendeurLastName.isNotEmpty)
          ? '$vendeurFirstName $vendeurLastName'.trim()
          : (vendeurId != null ? 'Vendeur #$vendeurId' : '');
      
      final paymentMethod = order['paymentMethod'] as Map<String, dynamic>?;
      final paymentMethodName = paymentMethod?['name']?.toString() ?? '';
      final codeColis = order['codeColis']?.toString();
      final createdAt = order['createdAt']?.toString() ?? '';
      
      String formattedDate = '';
      String formattedTime = '';
      if (createdAt.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(createdAt);
          formattedDate = DateFormat('dd MMM yyyy', 'fr').format(dateTime);
          formattedTime = DateFormat('HH:mm').format(dateTime);
        } catch (e) {
          formattedDate = createdAt;
        }
      }

      final statusColor = _statusColor(status);
      
      final canCancel = status.toLowerCase() != 'cancelled';
      
      return Container(
        margin: EdgeInsets.only(bottom: index == _filteredOrders.length - 1 ? 10 : 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(
                    orderData: order,
                    orderId: orderId,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec statut
                  Row(
                    children: [
                      // Badge de statut
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(status),
                              size: 11,
                              color: statusColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _translateStatus(status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Numéro de commande
                      Text(
                        '#${orderIdNum.isNotEmpty ? orderIdNum : (orderId.length > 8 ? orderId.substring(0, 8) : orderId)}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Informations principales
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 11,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  formattedDate,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                if (formattedTime.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '• $formattedTime',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            if (vendeurName.isNotEmpty)
                              Row(
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      vendeurName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            if (codeColis != null && codeColis.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.qr_code,
                                    size: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      'Code: $codeColis',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Nombre de produits
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2,
                              size: 11,
                              color: Colors.grey.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${products.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Divider
                  Container(
                    height: 0.5,
                    color: Colors.grey.shade200,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Footer avec total et actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${totalAvecLivraison.toStringAsFixed(0)} FC',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (canCancel)
                            Container(
                              margin: const EdgeInsets.only(right: 6),
                              child: _isCancelling[orderId] == true
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                                      ),
                                    )
                                  : IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(
                                        Icons.cancel_outlined,
                                        size: 16,
                                        color: Colors.red.shade700,
                                      ),
                                      onPressed: () => _showCancelOrderDialog(order),
                                      tooltip: 'Annuler',
                                    ),
                            ),
                          if (paymentMethodName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.payment,
                                    size: 10,
                                    color: Colors.grey.shade700,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    paymentMethodName,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      print('Erreur lors de l\'affichage de la commande: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Oups !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Une erreur est survenue',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _loadOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: AppColors.primary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucune commande',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous n\'avez pas encore de commandes.\nCommencez vos achats dès maintenant !',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
