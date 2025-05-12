import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:immo/screens/auth/otp_screen.dart';
import '../../constants.dart';
import '../../cubit/auth_cubit.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  // final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'locataire';
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    // _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Inscription réussie'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              } else if (state is AuthError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                //   Image.asset(
                //   AppAssets.backgroundImage,
                //   height: 100,
                //   width: 200,
                //   fit: BoxFit.contain,
                // ),
                Text(
                  'Rapidos',
                  style: AppStyles.heading1.copyWith(color: AppColors.primary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),      
                  Text(
                    'Commencez votre expérience immobilière',
                    style: AppStyles.body.copyWith(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 16),
                  // TextFormField(
                  //   controller: _emailController,
                  //   keyboardType: TextInputType.emailAddress,
                  //   decoration: InputDecoration(
                  //     labelText: 'Email',
                  //     prefixIcon: const Icon(Icons.email_outlined),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(12),
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 16),
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
                              showPhoneCode: true,
                              favorite: ['CD', 'RW', 'BI', 'UG', 'KE', 'TZ'],
                              countryListTheme: CountryListThemeData(
                                borderRadius: BorderRadius.circular(12),
                                inputDecoration: InputDecoration(
                                  labelText: 'Rechercher un pays',
                                  prefixIcon: const Icon(Icons.search),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rôle',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'locataire', child: Text('Locataire')),
                      DropdownMenuItem(value: 'proprietaire', child: Text('Propriétaire'))
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword 
                              ? Icons.visibility_off 
                              : Icons.visibility,
                          color: AppColors.textLight,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.secondary, width: 1.0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: state is AuthLoading
                        ? null
                        : () {
                            // Validation des champs
                            if (_firstNameController.text.isEmpty ||
                                _lastNameController.text.isEmpty ||
                                // _emailController.text.isEmpty ||
                                _phoneController.text.isEmpty ||
                                _passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tous les champs sont requis pour finaliser votre inscription'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validation de l'email
                            // if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            //     .hasMatch(_emailController.text)) {
                            //   ScaffoldMessenger.of(context).showSnackBar(
                            //     const SnackBar(
                            //       content: Text('L\'adresse email saisie n\'est pas valide'),
                            //       backgroundColor: Colors.red,
                            //     ),
                            //   );
                            //   return;
                            // }

                            // Validation du mot de passe
                            if (_passwordController.text.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Le mot de passe doit contenir au moins 6 caractères'),
                                ),
                              );
                              return;
                            }

                            // Validation du numéro de téléphone
                            if (_phoneController.text.length < 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Le numéro de téléphone doit contenir au moins 9 chiffres'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final phoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text}';
                            // context.read<AuthCubit>().register(
                            //       email: _emailController.text.trim(),
                            //       phone: phoneNumber,
                            //       password: _passwordController.text,
                            //       firstName: _firstNameController.text.trim(),
                            //       lastName: _lastNameController.text.trim(),
                            //       role: _selectedRole,
                            //     );
                                  context.read<AuthCubit>().sendOTP(
                                  phone: phoneNumber,

                                );

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => OTPScreen(user: {
                                  
                                  'phone': phoneNumber,
                                  'password': _passwordController.text,
                                  'firstName': _firstNameController.text.trim(),
                                  'lastName': _lastNameController.text.trim(),
                                  'role': _selectedRole,
                                  'resetPassword': false,
                                } ),
                                ));
                          },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: state is AuthLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Suivant'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Déjà un compte ? Connectez-vous'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
