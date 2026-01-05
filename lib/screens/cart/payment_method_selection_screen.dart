import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';

class PaymentMethodSelectionScreen extends StatefulWidget {
  final int vendeurId;
  final List<Map<String, dynamic>> paymentMethods;
  final Map<String, dynamic>? currentPaymentMethod;
  final List<int> orderIds; // IDs des commandes à mettre à jour

  const PaymentMethodSelectionScreen({
    Key? key,
    required this.vendeurId,
    required this.paymentMethods,
    this.currentPaymentMethod,
    required this.orderIds,
  }) : super(key: key);

  @override
  State<PaymentMethodSelectionScreen> createState() => _PaymentMethodSelectionScreenState();
}

class _PaymentMethodSelectionScreenState extends State<PaymentMethodSelectionScreen> {
  Map<String, dynamic>? _selectedPaymentMethod;
  final TextEditingController _numeroController = TextEditingController();
  String? _numeroError;

  // Préfixes de validation par type de moyen de paiement
  final Map<String, List<String>> _paymentPrefixes = {
    'orange money': ['089', '080', '087', '084'],
    'orange': ['089', '080', '087', '084'],
    'airtel money': ['099', '097', '098'],
    'airtel': ['099', '097', '098'],
    'mpesa': ['081', '082', '083'],
    'afrimoney': ['090', '0900'],
    'afri money': ['090', '0900'],
  };

  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = widget.currentPaymentMethod;
  }

  @override
  void dispose() {
    _numeroController.dispose();
    super.dispose();
  }

  bool _requiresNumero(String? paymentMethodName) {
    if (paymentMethodName == null) return false;
    final name = paymentMethodName.toLowerCase();
    return name.contains('cash') == false && 
           (name.contains('orange') || 
            name.contains('airtel') || 
            name.contains('mpesa') || 
            name.contains('afrimoney') ||
            name.contains('mobile money'));
  }

  List<String>? _getValidPrefixes(String? paymentMethodName) {
    if (paymentMethodName == null) return null;
    final name = paymentMethodName.toLowerCase().trim();
    
    print('🔍 [Prefixes] Recherche de préfixes pour: "$name"');
    
    // Chercher une correspondance exacte d'abord
    if (_paymentPrefixes.containsKey(name)) {
      print('✅ [Prefixes] Correspondance exacte trouvée: ${_paymentPrefixes[name]}');
      return _paymentPrefixes[name];
    }
    
    // Chercher une correspondance partielle
    for (var entry in _paymentPrefixes.entries) {
      if (name.contains(entry.key) || entry.key.contains(name)) {
        print('✅ [Prefixes] Correspondance partielle trouvée: ${entry.key} -> ${entry.value}');
        return entry.value;
      }
    }
    
    print('❌ [Prefixes] Aucun préfixe trouvé pour: "$name"');
    return null;
  }

  bool _validateNumero(String numero, String? paymentMethodName) {
    if (!_requiresNumero(paymentMethodName)) {
      return true; // Pas de validation nécessaire pour Cash
    }

    if (numero.isEmpty) {
      return false;
    }

    final prefixes = _getValidPrefixes(paymentMethodName);
    if (prefixes == null) {
      return true; // Pas de préfixe spécifique, accepter
    }

    print('🔍 [Validation] Numéro à valider: "$numero" (longueur: ${numero.length})');
    print('🔍 [Validation] Préfixes valides: $prefixes');
    print('🔍 [Validation] Moyen de paiement: $paymentMethodName');

    // Vérifier si le numéro commence par un des préfixes valides
    String? matchedPrefix;
    
    for (var prefix in prefixes) {
      if (numero.startsWith(prefix)) {
        matchedPrefix = prefix;
        print('✅ [Validation] Préfixe trouvé: $prefix');
        break;
      }
    }

    if (matchedPrefix != null) {
      // Le numéro commence par un préfixe valide
      // Tous les numéros doivent avoir 10 chiffres au total
      final totalLength = numero.length;
      final expectedLength = 10;
      
      print('🔍 [Validation] Longueur: $totalLength, attendue: $expectedLength');
      
      if (totalLength == expectedLength) {
        print('✅ [Validation] Numéro valide!');
        return true;
      } else {
        print('❌ [Validation] Longueur incorrecte: $totalLength au lieu de $expectedLength');
        return false;
      }
    }

    // Le numéro ne commence pas par un préfixe valide
    print('❌ [Validation] Le numéro ne commence pas par un préfixe valide');
    return false;
  }

  String? _getValidationMessage(String? paymentMethodName) {
    final prefixes = _getValidPrefixes(paymentMethodName);
    if (prefixes == null) return 'Numéro invalide';
    
    final expectedLength = 10;
    return 'Le numéro doit commencer par ${prefixes.join(', ')} et avoir $expectedLength chiffres au total (ex: ${prefixes.first}1234567)';
  }

  void _onPaymentMethodSelected(Map<String, dynamic> method) {
    setState(() {
      _selectedPaymentMethod = method;
      _numeroController.clear();
      _numeroError = null;
    });
  }

  void _validateAndSave() async {
    print('🔘 [PaymentMethodSelection] BOUTON CONFIRMER CLIQUÉ');
    
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un moyen de paiement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final paymentMethodName = _selectedPaymentMethod!['name']?.toString() ?? '';
    final requiresNumero = _requiresNumero(paymentMethodName);
    // Nettoyer le numéro : enlever les espaces et garder seulement les chiffres
    var numero = _numeroController.text.trim().replaceAll(RegExp(r'[^\d]'), '');

    if (requiresNumero) {
      if (numero.isEmpty) {
        setState(() {
          _numeroError = 'Veuillez renseigner votre numéro';
        });
        return;
      }

      print('📱 [Validation] Numéro saisi: "$numero" (longueur: ${numero.length})');
      print('📱 [Validation] Moyen de paiement: $paymentMethodName');

      // Vérifier si le numéro est valide tel quel (l'utilisateur doit saisir le préfixe)
      bool isValid = _validateNumero(numero, paymentMethodName);

      if (!isValid) {
        final message = _getValidationMessage(paymentMethodName);
        setState(() {
          _numeroError = message ?? 'Numéro invalide. Le numéro doit avoir 10 chiffres (ex: 0991234567)';
        });
        print('❌ [Validation] Erreur de validation: $_numeroError');
        return;
      }
      
      print('✅ [Validation] Numéro validé avec succès: $numero');
    }
    
    // Préparer le body AVANT l'envoi
    final paymentMethodId = _selectedPaymentMethod!['id'] as int;
    final body = <String, dynamic>{
      'paymentMethodId': paymentMethodId,
    };
    
    if (requiresNumero && numero.isNotEmpty) {
      body['numeroPayment'] = numero;
    }
    
    print('');
    print('═══════════════════════════════════════════════════════════');
    print('📦 [PaymentMethodSelection] BODY QUI SERA ENVOYÉ:');
    print('═══════════════════════════════════════════════════════════');
    print('${jsonEncode(body)}');
    print('');
    print('Structure détaillée:');
    print('{');
    print('  "paymentMethodId": $paymentMethodId,');
    if (requiresNumero && numero.isNotEmpty) {
      print('  "numeroPayment": "$numero"');
    }
    print('}');
    print('═══════════════════════════════════════════════════════════');
    print('');

    // Retourner les données sans exécuter l'endpoint
    // Les données seront stockées dans le state et validées plus tard
    print('🔄 [PaymentMethodSelection] Retour des données (sans exécution de l\'endpoint)');
    print('📋 [PaymentMethodSelection] Nombre de commandes: ${widget.orderIds.length}');
    print('💳 [PaymentMethodSelection] Moyen de paiement sélectionné: ID=$paymentMethodId, Nom=${_selectedPaymentMethod!['name']}');
    print('📱 [PaymentMethodSelection] Numéro de paiement: ${requiresNumero && numero.isNotEmpty ? numero : 'Non requis'}');
    
    // Préparer les données à retourner
    final result = <String, dynamic>{
      'paymentMethod': _selectedPaymentMethod!,
    };
    
    if (requiresNumero && numero.isNotEmpty) {
      result['numeroPayment'] = numero;
    }

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentMethodName = _selectedPaymentMethod?['name']?.toString() ?? '';
    final requiresNumero = _requiresNumero(paymentMethodName);
    final validPrefixes = _getValidPrefixes(paymentMethodName);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Moyen de paiement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<OrderCubit, OrderState>(
        listener: (context, state) {
          if (state.error != null && mounted) {
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Liste des moyens de paiement
                      ...widget.paymentMethods.map((method) {
                        final isSelected = _selectedPaymentMethod != null &&
                            method['id'] == _selectedPaymentMethod!['id'];

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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _onPaymentMethodSelected(method),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    if (method['imageUrl'] != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                          imageUrl: method['imageUrl'],
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.payment),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            method['name'] ?? 'Moyen de paiement',
                                            style: TextStyle(
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              fontSize: 14,
                                              color: isSelected ? AppColors.primary : Colors.black87,
                                            ),
                                          ),
                                          if (method['numeroCompte'] != null)
                                            Text(
                                              method['numeroCompte'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isSelected ? AppColors.primary : Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, color: AppColors.primary, size: 24),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      // Champ de saisie du numéro si nécessaire
                      if (_selectedPaymentMethod != null && requiresNumero) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _numeroController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10), // Max 10 chiffres
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Numéro à débiter',
                                  labelStyle: TextStyle(color: Colors.grey.shade600),
                                  hintText: validPrefixes != null && validPrefixes.isNotEmpty
                                      ? 'Ex: ${validPrefixes.first}1234567'
                                      : 'Entrez votre numéro',
                                  errorText: _numeroError,
                                  prefixIcon: Icon(Icons.phone, color: AppColors.primary),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red.shade300),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.red, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                onChanged: (value) {
                                  if (_numeroError != null) {
                                    setState(() {
                                      _numeroError = null;
                                    });
                                  }
                                },
                              ),
                              if (validPrefixes != null && validPrefixes.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _getValidationMessage(paymentMethodName) ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bouton de confirmation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _validateAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Valider',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
