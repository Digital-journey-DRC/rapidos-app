import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../widgets/app_logo.dart';
import '../../services/payment_method_service.dart';
import '../../widgets/ecommerce_loading.dart';
import 'payment_method_templates_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  
  // Moyens de paiement sélectionnés par le marchand (sa liste personnelle)
  List<Map<String, dynamic>> _selectedPaymentMethods = [];
  List<Map<String, dynamic>> _paymentTemplates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Charger les templates pour avoir les images et noms
    final templatesResult = await _paymentMethodService.getPaymentMethodTemplates();
    if (templatesResult['success'] == true) {
      _paymentTemplates = List<Map<String, dynamic>>.from(templatesResult['paymentMethods'] ?? []);
    }

    // Charger les moyens de paiement du vendeur
    await _loadSelectedPaymentMethods();
  }

  Future<void> _loadSelectedPaymentMethods() async {
    try {
      final result = await _paymentMethodService.getVendeurPaymentMethods();
      
      if (result['success'] == true) {
        final vendeurMethods = List<Map<String, dynamic>>.from(result['paymentMethods'] ?? []);
        
        // Enrichir les données avec les templates (images, noms complets)
        final enrichedMethods = vendeurMethods.map((method) {
          final type = method['type']?.toString() ?? '';
          final template = _paymentTemplates.firstWhere(
            (t) => t['type']?.toString().toLowerCase() == type.toLowerCase(),
            orElse: () => <String, dynamic>{},
          );
          
          return {
            ...method,
            'name': template['name'] ?? type,
            'description': template['description'] ?? '',
            'imageUrl': template['imageUrl'],
          };
        }).toList();

        // Trier : actifs en premier, puis désactivés
        // Dans chaque groupe, trier par isDefault (défaut en premier), puis par date de création
        enrichedMethods.sort((a, b) {
          final aActive = a['isActive'] == true;
          final bActive = b['isActive'] == true;
          
          // D'abord trier par statut actif/inactif
          if (aActive != bActive) {
            return aActive ? -1 : 1; // Actifs en premier
          }
          
          // Si même statut, trier par isDefault (défaut en premier)
          final aDefault = a['isDefault'] == true;
          final bDefault = b['isDefault'] == true;
          if (aDefault != bDefault) {
            return aDefault ? -1 : 1; // Défaut en premier
          }
          
          // Enfin, trier par date de création (plus récents en premier)
          final aDate = a['createdAt']?.toString() ?? '';
          final bDate = b['createdAt']?.toString() ?? '';
          return bDate.compareTo(aDate);
        });

        setState(() {
          _selectedPaymentMethods = enrichedMethods;
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

  Future<void> _navigateToTemplatesScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodTemplatesScreen(),
      ),
    );

    // Si un moyen de paiement a été activé avec succès (result == true)
    // ou si un moyen de paiement a été sélectionné (ancien format Map)
    if (result == true || (result != null && result is Map<String, dynamic>)) {
      // Recharger les moyens de paiement du vendeur après activation
      await _loadSelectedPaymentMethods();
      
      if (mounted && result is Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['name']} ajouté avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }


  // Future<void> _deletePaymentMethod(int index) async {
  //   // TODO: Appeler l'API pour supprimer le moyen de paiement
  //   // Pour l'instant, on supprime juste de la liste locale
  //   setState(() {
  //     _selectedPaymentMethods.removeAt(index);
  //   });
  //   
  //   if (mounted) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Moyen de paiement supprimé'),
  //         backgroundColor: AppColors.success,
  //       ),
  //     );
  //   }
  // }

  Future<void> _togglePaymentMethodStatus(int index) async {
    final method = _selectedPaymentMethods[index];
    final id = method['id'] as int;
    final isActive = method['isActive'] == true;

    // Ne pas permettre de désactiver le moyen de paiement par défaut
    if (method['isDefault'] == true && isActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de désactiver le moyen de paiement par défaut'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    final result = isActive
        ? await _paymentMethodService.deactivatePaymentMethod(id)
        : await _paymentMethodService.activatePaymentMethod(id);

    if (result['success'] == true) {
      // Recharger la liste
      await _loadSelectedPaymentMethods();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Statut modifié avec succès'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la modification'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editPaymentMethod(int index) {
    final method = _selectedPaymentMethods[index];
    final formKey = GlobalKey<FormState>();
    final numeroCompteController = TextEditingController(
      text: method['numeroCompte']?.toString() ?? '',
    );
    final nomTitulaireController = TextEditingController(
      text: method['nomTitulaire']?.toString() ?? '',
    );
    bool isDefault = method['isDefault'] == true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.edit,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Modifier ${method['name'] ?? 'le moyen de paiement'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Numéro de compte
                      TextFormField(
                        controller: numeroCompteController,
                        decoration: InputDecoration(
                          labelText: 'Numéro de compte',
                          hintText: 'Ex: 0651234567',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer le numéro de compte';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Nom du titulaire
                      TextFormField(
                        controller: nomTitulaireController,
                        decoration: InputDecoration(
                          labelText: 'Nom du titulaire',
                          hintText: 'Ex: Jean Dupont',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer le nom du titulaire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Checkbox pour moyen de paiement par défaut
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: CheckboxListTile(
                          title: const Text(
                            'Définir comme moyen de paiement par défaut',
                            style: TextStyle(fontSize: 14),
                          ),
                          value: isDefault,
                          onChanged: (value) {
                            setState(() {
                              isDefault = value ?? false;
                            });
                          },
                          activeColor: AppColors.primary,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isSubmitting = true;
                            });

                            final result = await _paymentMethodService.updatePaymentMethod(
                              id: method['id'] as int,
                              numeroCompte: numeroCompteController.text.trim(),
                              nomTitulaire: nomTitulaireController.text.trim(),
                              isDefault: isDefault,
                            );

                            if (!context.mounted) return;

                            setState(() {
                              isSubmitting = false;
                            });

                            if (result['success'] == true) {
                              Navigator.of(context).pop();
                              // Recharger la liste
                              await _loadSelectedPaymentMethods();
                              
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message'] ?? 'Moyen de paiement modifié avec succès',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    result['message'] ?? 'Erreur lors de la modification',
                                  ),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Modifier',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBarWithLogo(
        title: 'Moyens de paiement',
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: EcommerceLoading.simple(size: 150),
            )
          : Column(
                  children: [
                    // Section des moyens de paiement sélectionnés par le marchand ou message d'erreur
                    Expanded(
                      child: _errorMessage != null
                          ? Center(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(32),
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
                                        onPressed: _loadData,
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
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: SingleChildScrollView(
                                child: Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
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
                                            child: Icon(
                                              Icons.payment,
                                              color: AppColors.primary,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Expanded(
                                            child: Text(
                                              'Mes moyens de paiement',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (_selectedPaymentMethods.isNotEmpty)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${_selectedPaymentMethods.length}',
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (_selectedPaymentMethods.isEmpty)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.grey.shade200,
                                              width: 1,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.payment_outlined,
                                                size: 48,
                                                color: Colors.grey.shade400,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Moyens de paiements non trouvés',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Utilisez le bouton ci-dessous pour ajouter un moyen de paiement',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        )
                                      else
                                        ..._selectedPaymentMethods.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final method = entry.value;
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12),
                                            child: _buildSelectedPaymentCard(method, index),
                                          );
                                        }),
                                      // Espace supplémentaire en bas pour éviter que le contenu soit caché par le bouton fixe
                                      if (_selectedPaymentMethods.isNotEmpty)
                                        const SizedBox(height: 80),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    // Bouton d'ajout - Toujours visible en bas
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          child: ElevatedButton.icon(
                            onPressed: _navigateToTemplatesScreen,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text(
                              'Ajouter un moyen de paiement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSelectedPaymentCard(Map<String, dynamic> method, int index) {
    final isActive = method['isActive'] == true;
    final isDefault = method['isDefault'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Opacity(
        opacity: isActive ? 1.0 : 0.7,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: method['imageUrl'] != null && method['imageUrl'].toString().isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: method['imageUrl'].toString(),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.payment,
                              color: Colors.grey.shade400,
                              size: 28,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.payment,
                            color: Colors.grey.shade400,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Nom et informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            method['name']?.toString() ?? method['type']?.toString() ?? 'Sans nom',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Défaut',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (!isActive)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Inactif',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (method['nomTitulaire'] != null && method['nomTitulaire'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              method['nomTitulaire'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (method['numeroCompte'] != null && method['numeroCompte'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              method['numeroCompte'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if ((method['nomTitulaire'] == null || method['nomTitulaire'].toString().isEmpty) &&
                        (method['numeroCompte'] == null || method['numeroCompte'].toString().isEmpty))
                      const SizedBox(height: 4),
                  ],
                ),
              ),
              // Boutons d'action
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton toggle activer/désactiver
                  Switch(
                    value: isActive,
                    onChanged: (isDefault && isActive)
                        ? null // Désactiver le switch si c'est le moyen par défaut et actif
                        : (value) {
                            _togglePaymentMethodStatus(index);
                          },
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey.shade400,
                    inactiveTrackColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 8),
                  // Bouton modifier
                  IconButton(
                    onPressed: () => _editPaymentMethod(index),
                    icon: Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    tooltip: 'Modifier',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
