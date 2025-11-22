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
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'acheteur';
  
  // Variables pour les validations du mot de passe
  bool _hasMinLength = false;
  bool _hasNumber = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasSpecialChar = false;
  
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
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 12;
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool _isPasswordValid() {
    return _hasMinLength && _hasNumber && _hasUppercase && _hasLowercase && _hasSpecialChar;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey.shade800),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: BlocConsumer<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is AuthSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
                final phoneNumber = '+${_selectedCountry.phoneCode}${_phoneController.text}';
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => OTPScreen(user: {
                    'phone': phoneNumber,
                    'password': _passwordController.text,
                    'firstName': _firstNameController.text.trim(),
                    'lastName': _lastNameController.text.trim(),
                    'role': _selectedRole,
                    'resetPassword': false,
                    'otp': state.user?['otp'],
                    'userId': state.user?['id'],
                    'expiresAt': state.user?['expiresAt'],
                  }),
                ));
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
                  // Header avec logo et titre
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    child: Column(
                      children: [
                        Image.asset(AppAssets.logo, width: 100, height: 100),
                        const SizedBox(height: 20),
                        Text(
                          'Créer un compte',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rejoignez-nous pour commencer',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Formulaire dans une carte
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            labelText: 'Prénom',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            labelText: 'Nom',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Numéro de téléphone',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            hintText: '826016607',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              margin: const EdgeInsets.only(right: 8),
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
                                    const SizedBox(width: 6),
                                    Text(
                                      '+${_selectedCountry.phoneCode}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Rôle',
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          dropdownColor: Colors.white,
                          style: TextStyle(color: Colors.grey.shade800, fontSize: 15),
                          items: const [
                            DropdownMenuItem(
                                value: 'acheteur', child: Text('Acheteur')),
                            DropdownMenuItem(
                                value: 'vendeur', child: Text('Vendeur')),
                            DropdownMenuItem(
                                value: 'livreur', child: Text('Livreur')),
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
                            labelStyle: TextStyle(color: Colors.grey.shade600),
                            prefixIcon: Icon(Icons.lock_outline, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.grey.shade600,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: AppColors.primary, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Indicateurs de validation du mot de passe
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.security, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Critères de sécurité',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildValidationRow(
                                'Au moins 12 caractères',
                                _hasMinLength,
                              ),
                              const SizedBox(height: 6),
                              _buildValidationRow(
                                'Au moins un chiffre',
                                _hasNumber,
                              ),
                              const SizedBox(height: 6),
                              _buildValidationRow(
                                'Au moins une majuscule',
                                _hasUppercase,
                              ),
                              const SizedBox(height: 6),
                              _buildValidationRow(
                                'Au moins une minuscule',
                                _hasLowercase,
                              ),
                              const SizedBox(height: 6),
                              _buildValidationRow(
                                'Au moins un caractère spécial',
                                _hasSpecialChar,
                              ),
                            ],
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
                                  content: Text(
                                      'Tous les champs sont requis pour finaliser votre inscription'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validation de l'email
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(_emailController.text)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'L\'adresse email saisie n\'est pas valide'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Validation du mot de passe
                            if (!_isPasswordValid()) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Le mot de passe doit contenir au moins 12 caractères, inclure au moins une lettre majuscule, une lettre minuscule, un chiffre et un caractère spécial'),
                                ),
                              );
                              return;
                            }

                            // Validation du numéro de téléphone
                            if (_phoneController.text.length < 9) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Le numéro de téléphone doit contenir au moins 9 chiffres'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final phoneNumber =
                                '+${_selectedCountry.phoneCode}${_phoneController.text}';
                            context.read<AuthCubit>().register(
                                  context: context,
                                  email: _emailController.text.trim(),
                                  phone: phoneNumber,
                                  password: _passwordController.text,
                                  firstName: _firstNameController.text.trim(),
                                  lastName: _lastNameController.text.trim(),
                                  role: _selectedRole,
                                );
                            // context.read<AuthCubit>().sendOTP(
                            //       phone: phoneNumber,
                            //     );
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            shadowColor: AppColors.buttonColor.withOpacity(0.4),
                            backgroundColor: AppColors.buttonColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Créer mon compte',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Vous avez déjà un compte ? ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildValidationRow(String text, bool isValid) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isValid ? Colors.green.shade50 : Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isValid ? Colors.green : Colors.red.shade400,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green.shade700 : Colors.grey.shade600,
              fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
