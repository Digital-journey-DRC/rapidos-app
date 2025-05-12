import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:country_picker/country_picker.dart';
import 'package:immo/services/payment_storage_service.dart';
import '../services/payment_service.dart';

class MobilePaymentScreen extends StatefulWidget {
  final String rentBookId;
  final int amount;
  final String devise;

  const MobilePaymentScreen({
    super.key,
    required this.rentBookId,
    required this.amount,
    required this.devise,
  });

  @override
  State<MobilePaymentScreen> createState() => _MobilePaymentScreenState();
}

class _MobilePaymentScreenState extends State<MobilePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _paymentService = PaymentService();
  bool _isLoading = false;
  String? _errorMessage;
  Country _selectedCountry = Country(
    phoneCode: "243",
    countryCode: "CD",
    e164Sc: 0,
    geographic: true,
    level: 1,
    name: "DR Congo",
    example: "DR Congo",
    displayName: "DR Congo",
    displayNameNoCountryCode: "CD",
    e164Key: "",
  );

  @override
  void initState() {
    super.initState();
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final phoneNumber = _phoneController.text;
        
        await _paymentService.initiatePayment(
          rentBookId: widget.rentBookId,
          type: 'loyer',
          amount: widget.amount,
          phone: phoneNumber,
          devise: widget.devise,
        );

        if (mounted) {
          Navigator.pop(context);
          
          // Récupérer l'historique des paiements existant
          List<Map<String, dynamic>> paymentHistory = PaymentStorageService.getPaymentHistory(widget.rentBookId);
          
          // Créer un nouvel enregistrement de paiement
          final DateTime now = DateTime.now();
          final Map<String, dynamic> newPayment = {
            'amount': widget.amount,
            'date': now.toIso8601String(),
            'month': PaymentStorageService.getMonthName(now),
            'status': 'Payé',
          };
          
          // Ajouter le paiement actuel à l'historique
          paymentHistory.add(newPayment);
          
          // Sauvegarder l'historique mis à jour
          await PaymentStorageService.savePaymentHistory(widget.rentBookId, paymentHistory);
          
          // Générer la prochaine échéance en tenant compte du nombre de paiements (incluant celui qu'on vient de faire)
          final nextPayment = PaymentStorageService.generateNextPayment(
            widget.amount.toDouble(),
            now,
            numberOfPaymentsMade: paymentHistory.length
          );
          
          // Sauvegarder la prochaine échéance
          await PaymentStorageService.saveNextPayment(widget.rentBookId, nextPayment);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement initié avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Mobile'),
        backgroundColor: AppColors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Montant à payer',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.amount} ${widget.devise}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Numéro de téléphone',
                    hintText: '826016607',
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: context,
                            countryListTheme: const CountryListThemeData(
                              bottomSheetHeight: 500,
                            ),
                            onSelect: (value) {
                              setState(() {
                                _selectedCountry = value;
                              });
                            },
                          );
                        },
                        child: Text(
                          "${_selectedCountry.flagEmoji} +${_selectedCountry.phoneCode}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer votre numéro de téléphone';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Payer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}