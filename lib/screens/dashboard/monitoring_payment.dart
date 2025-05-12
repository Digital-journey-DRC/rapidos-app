import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import 'package:immo/widgets/custom_skeletons.dart';

class MonitoringPayment extends StatefulWidget {
  const MonitoringPayment({super.key, required this.rentbook, required this.currency});
  final List rentbook;
  final String currency;

  @override
  State<MonitoringPayment> createState() => _MonitoringPaymentState();
}

class _MonitoringPaymentState extends State<MonitoringPayment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Format date method
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  // Get payment method icon
  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'mobile_money':
        return Icons.phone_android;
      case 'cash':
        return Icons.money;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'payé':
      case 'paye':
      case 'paid':
        return Colors.green;
      case 'en attente':
      case 'pending':
        return Colors.orange;
      case 'annulé':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utilisons directement la liste des paiements passée au widget
    final List paymentHistory = widget.rentbook;
    
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        title: const Text(
          'Historique des paiements',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.buttonColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with total summary
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.buttonColor,
                  Color.fromARGB(255, 230, 98, 88),
                ],
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Récapitulatif',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total des paiements',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${paymentHistory.where((payment) => payment['status']?.toLowerCase() == 'payé' || payment['status']?.toLowerCase() == 'paye' || payment['status']?.toLowerCase() == 'paid').fold(0.0, (sum, payment) => sum + (payment['amount'] ?? 0.0)).toStringAsFixed(2)} ${widget.currency}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${paymentHistory.length} transactions',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          
          // Payment history list
          Expanded(
            child: paymentHistory.isEmpty
                ? _buildSkeletonPaymentCards() // Show skeletons when empty
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: paymentHistory.length,
                    itemBuilder: (context, index) {
                      final payment = paymentHistory[index];
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Réf: ${payment['reference'] ?? 'N/A'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(payment['status'] ?? ''),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      payment['status'] ?? 'N/A',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getPaymentMethodIcon(payment['paymentMethod'] ?? ''),
                                      color: AppColors.buttonColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${payment['amount']?.toStringAsFixed(2) ?? '0.00'} ${widget.currency}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        payment['paymentMethod'] != null
                                            ? 'Paiement par ${payment['paymentMethod']}'
                                            : 'Méthode non précisée',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Date: ${payment['date'] != null ? _formatDate(payment['date']) : 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (payment['comment'] != null && payment['comment'].toString().isNotEmpty)
                                    IconButton(
                                      icon: const Icon(Icons.remove_red_eye, color: AppColors.buttonColor),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text('Commentaire'),
                                              content: Text(payment['comment']),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Fermer'),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
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
        ],
      ),
    );
  }

  // Build skeleton payment cards for loading state
  Widget _buildSkeletonPaymentCards() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reference and status row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reference skeleton
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        width: 150,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Status tag skeleton
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SkeletonLine(
                        style: SkeletonLineStyle(
                          width: 60,
                          height: 12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Payment method and amount row
                Row(
                  children: [
                    // Payment method icon skeleton
                    SkeletonAvatar(
                      style: SkeletonAvatarStyle(
                        width: 44,
                        height: 44,
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.buttonColor.withOpacity(0.1),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Payment amount and method skeletons
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 120,
                            height: 18,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 5),
                        SkeletonLine(
                          style: SkeletonLineStyle(
                            width: 160,
                            height: 14,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                // Date and comment skeletons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        width: 180,
                        height: 13,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Comment icon skeleton (shown randomly on some cards)
                    if (index % 2 == 0) // Only show on some cards
                      SkeletonAvatar(
                        style: SkeletonAvatarStyle(
                          width: 24,
                          height: 24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}