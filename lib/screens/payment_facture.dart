import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:immo/constants.dart';
import 'package:immo/services/payment_service.dart';

class PayementFacture extends StatefulWidget {
  final Map billData;
  final String currency;
  const PayementFacture({super.key, required this.billData, required this.currency});

  @override
  State<PayementFacture> createState() => _PayementFactureState();
}

class _PayementFactureState extends State<PayementFacture> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _paymentService = PaymentService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = ['mobile_money'];

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
    _selectedPaymentMethod = _paymentMethods.first;
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final phoneNumber = _phoneController.text;
        
        await _paymentService.initiatePaymentFacture(
          utilityBillId: widget.billData['billId'],
          type: 'facture',
          amount: widget.billData["apartmentAmount"],
          phone: phoneNumber,
          devise: widget.currency,
        );

        if (mounted) {
          Navigator.pop(context);
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
        title: const Text('Paiement Facture'),
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
                      const Text(
                        'Montant à payer',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.billData["apartmentAmount"]} ${widget.currency}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.buttonColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Moyen de paiement',
                    border: OutlineInputBorder(),
                  ),
                  items: _paymentMethods.map((String method) {
                    return DropdownMenuItem<String>(
                      value: method,
                      child: Text(method == 'mobile_money' ? 'Mobile Money' : 'Espèces'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPaymentMethod = newValue;
                    });
                  },
                ),
                const SizedBox(height: 24),
                if (_selectedPaymentMethod == 'mobile_money') ...[                
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
                ],
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