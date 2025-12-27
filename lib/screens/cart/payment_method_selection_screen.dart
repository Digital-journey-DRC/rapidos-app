import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/app_logo.dart';
import '../../services/payment_method_service.dart';
import '../../widgets/ecommerce_loading.dart';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final int vendeurId;
  final String vendeurName;

  const PaymentMethodSelectionScreen({
    Key? key,
    required this.vendeurId,
    required this.vendeurName,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _paymentMethodService.getVendeurPaymentMethodsForClient(widget.vendeurId);

      if (result['success'] == true) {
        setState(() {
          _paymentMethods = List<Map<String, dynamic>>.from(result['paymentMethods'] ?? []);
          // Sélectionner le moyen de paiement par défaut s'il existe
          if (_paymentMethods.isNotEmpty) {
            final defaultMethod = _paymentMethods.firstWhere(
              (method) => method['isDefault'] == true,
              orElse: () => _paymentMethods.first,
            );
            _selectedPaymentMethod = defaultMethod;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Erreur lors du chargement';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  String _getPaymentMethodName(String type) {
    final names = {
      'cash': 'Cash',
      'mpesa': 'Mpesa',
      'orange_money': 'Orange Money',
      'airtel_money': 'Airtel Money',
      'afrimoney': 'Afrimoney',
      'visa': 'Visa',
      'mastercard': 'Mastercard',
    };
    return names[type] ?? type;
  }

  IconData _getPaymentMethodIcon(String type) {
    final icons = {
      'cash': Icons.money,
      'mpesa': Icons.phone_android,
      'orange_money': Icons.phone_android,
      'airtel_money': Icons.phone_android,
      'afrimoney': Icons.phone_android,
      'visa': Icons.credit_card,
      'mastercard': Icons.credit_card,
    };
    return icons[type] ?? Icons.payment;
  }

  void _confirmSelection() {
    if (_selectedPaymentMethod != null) {
      Navigator.of(context).pop(_selectedPaymentMethod);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBarWithLogo(
        title: 'Moyen de paiement',
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: EcommerceLoading.simple(size: 150),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadPaymentMethods,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : _paymentMethods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.payment_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun moyen de paiement disponible',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Le vendeur n\'a pas configuré de moyens de paiement',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Info sur le vendeur - Design compact et élégant
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary.withOpacity(0.06),
                                AppColors.primary.withOpacity(0.02),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Icône compacte
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primary.withOpacity(0.85),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Informations du vendeur compactes
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Label compact
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'VENDEUR',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      // Nom du vendeur
                                      Text(
                                        widget.vendeurName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade900,
                                          letterSpacing: 0.1,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // Nom du titulaire si disponible
                                      if (_paymentMethods.isNotEmpty &&
                                          _paymentMethods.first['nomTitulaire'] != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.person_outline_rounded,
                                              size: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _paymentMethods.first['nomTitulaire'],
                                                style: TextStyle(
                                                  fontSize: 11,
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
                                const SizedBox(width: 8),
                                // Badge de vérification compact
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade200,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    color: Colors.green.shade600,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Liste des moyens de paiement
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _paymentMethods.length,
                            itemBuilder: (context, index) {
                              final paymentMethod = _paymentMethods[index];
                              final isSelected = _selectedPaymentMethod?['id'] == paymentMethod['id'];
                              final type = paymentMethod['type']?.toString() ?? '';
                              final name = _getPaymentMethodName(type);
                              final icon = _getPaymentMethodIcon(type);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey.shade200,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.03),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedPaymentMethod = paymentMethod;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        // Icône du moyen de paiement
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primary.withOpacity(0.1)
                                                : Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary.withOpacity(0.3)
                                                  : Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.grey.shade600,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        // Détails du moyen de paiement
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey.shade800,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (paymentMethod['isDefault'] == true) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.primary.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Défaut',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              if (paymentMethod['nomTitulaire'] != null)
                                                Text(
                                                  paymentMethod['nomTitulaire'],
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              if (paymentMethod['numeroCompte'] != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  paymentMethod['numeroCompte'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade500,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Indicateur de sélection
                                        Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.shade300,
                                              width: 2,
                                            ),
                                            color: isSelected
                                                ? AppColors.primary
                                                : Colors.transparent,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 16,
                                                  color: Colors.white,
                                                )
                                              : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Bouton de confirmation
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _selectedPaymentMethod != null
                                    ? _confirmSelection
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shadowColor: AppColors.primary.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'CONFIRMER',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

