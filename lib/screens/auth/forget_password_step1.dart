import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import '../../constants.dart';
import 'package:immo/screens/auth/otp_screen.dart';

class ForgetPasswordStep1 extends StatefulWidget {
  const ForgetPasswordStep1({super.key});

  @override
  State<ForgetPasswordStep1> createState() => _ForgetPasswordStep1State();
}

class _ForgetPasswordStep1State extends State<ForgetPasswordStep1> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
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
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _requestPasswordReset() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre numéro de téléphone'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      final phoneNumber =
          '+${_selectedCountry.phoneCode}${_phoneController.text}';
      context.read<AuthCubit>().sendOTP(
            phone: phoneNumber,
          );

      // Navigate to OTP screen with user data
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OTPScreen(
                    user: {
                      'phone': phoneNumber,
                      'resetPassword': true,
                    },
                  )));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 40,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 50),
                    Image.asset(
                      AppAssets.backgroundImage,
                      height: 70,
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Mot de passe oublié',
                      style:
                          AppStyles.heading2.copyWith(color: AppColors.primary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Entrez votre numéro de téléphone pour réinitialiser votre mot de passe',
                      style:
                          AppStyles.body.copyWith(color: AppColors.textLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Numéro de téléphone',
                              hintText: '826016607',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                child: InkWell(
                                  onTap: () {
                                    showCountryPicker(
                                      context: context,
                                      showPhoneCode: true,
                                      favorite: <String>[
                                        'CD',
                                        'RW',
                                        'BI',
                                        'UG',
                                        'KE',
                                        'TZ'
                                      ],
                                      countryListTheme: CountryListThemeData(
                                        borderRadius: BorderRadius.circular(12),
                                        inputDecoration: InputDecoration(
                                          labelText: 'Rechercher un pays',
                                          prefixIcon: const Icon(Icons.search),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      onSelect: (Country country) {
                                        setState(() {
                                          _selectedCountry = country;
                                        });
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _selectedCountry.flagEmoji,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+${_selectedCountry.phoneCode}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down),
                                    ],
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.secondary, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 2.0),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _requestPasswordReset,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppColors.buttonColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadowColor:
                                    AppColors.buttonColor.withOpacity(0.3),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Continuer',
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
