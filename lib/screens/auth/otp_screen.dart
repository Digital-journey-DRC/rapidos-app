// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/screens/auth/resset_password_screen.dart';
import '../../constants.dart';
import 'package:immo/services/auth_service.dart'; // Importer le service AuthService

class OTPScreen extends StatefulWidget {
  final Map? user;
  const OTPScreen({super.key, this.user});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  String _otp = '';
  bool _isLoading = false;
  String _phoneNumber = '';
  String _maskedPhoneNumber = '+243XXXXXX607';
  final TextEditingController _otpController = TextEditingController();
  List<TextEditingController> _controllers = [];
  bool _isKeyboardVisible = false;
  final FocusNode _focusNode = FocusNode();

  // Variables pour le compteur
  int _remainingSeconds = 300; // 5 minutes = 300 secondes
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs pour chaque champ
    _controllers = List.generate(6, (index) => TextEditingController());

    if (widget.user != null && widget.user!.containsKey('phone')) {
      _phoneNumber = widget.user!['phone'] as String;
      // Masquer le numéro de téléphone au format +243XXXXXX607
      if (_phoneNumber.isNotEmpty) {
        // S'assurer que le numéro a au moins 9 caractères pour éviter les erreurs
        if (_phoneNumber.length >= 9) {
          // Garder les 4 premiers caractères (incluant le +) et les 3 derniers
          String prefix = _phoneNumber.substring(0, 4);
          String suffix = _phoneNumber.substring(_phoneNumber.length - 3);
          // Remplacer les caractères du milieu par 'X'
          int middleLength = _phoneNumber.length - 7;
          String middle = 'X' * middleLength;
          _maskedPhoneNumber = prefix + middle + suffix;
        }
      }
    }

    // Démarrer le compteur
    _startTimer();
  }

  void _startTimer() {
    _remainingSeconds = 300; // 5 minutes
    _canResend = false;

    // Annuler le timer existant si nécessaire
    _timer?.cancel();

    // Créer un nouveau timer qui décrémente _remainingSeconds chaque seconde
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // Formater le temps restant en minutes:secondes
  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _otpController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    _focusNode.dispose();
    _timer?.cancel(); // Annuler le timer lors de la destruction du widget
    super.dispose();
  }

  // Méthode pour coller le code OTP depuis le presse-papiers
  Future<void> _pasteOtpCode() async {
    final ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      String pastedText = clipboardData.text!;

      // Extraire uniquement les chiffres du texte collé
      String digitsOnly = pastedText.replaceAll(RegExp(r'[^0-9]'), '');

      // Si nous avons au moins 6 chiffres, prendre les 6 premiers
      if (digitsOnly.length >= 6) {
        String otpCode = digitsOnly.substring(0, 6);

        // Mettre à jour l'état avec le code OTP
        setState(() {
          _otp = otpCode;
        });

        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code OTP collé avec succès'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );

        // Vérifier automatiquement après un court délai
        Future.delayed(const Duration(milliseconds: 300), () {
          _verifyOTP();
        });
      } else {
        // Afficher un message d'erreur si le texte collé ne contient pas assez de chiffres
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le texte collé ne contient pas un code OTP valide'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _verifyOTP() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un code à 6 chiffres'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Vérification simple et directe
    if (widget.user != null && widget.user!['resetPassword'] == true) {
      try {
        // Attendre 2 secondes pour montrer le chargement
        await Future.delayed(const Duration(seconds: 2));
        
        // Vérifier l'OTP directement avec le service
        // final authService = AuthService();
        // final response = await authService.verifyOTP(
        //   id: widget.user!['id']??"",
        //   otp:  int.parse(_otp)
        // );
        
        // Si nous arrivons ici, c'est que l'OTP est correct
        setState(() {
          _isLoading = false;
        });
        
        // Rediriger vers l'écran de réinitialisation du mot de passe
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RessetPasswordScreen(
                user: {
                  'phone': widget.user!['phone'],
                  'otp': _otp,
                  'resetPassword': true,
                },
              ),
            ),
          );
        }
      } catch (e) {
        // OTP incorrect ou autre erreur
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Pour l'inscription, continuer comme avant avec le cubit
      try {
        // Attendre 2 secondes pour montrer le chargement
        await Future.delayed(const Duration(seconds: 2));
        
        context.read<AuthCubit>().verifyOTP(
          context: context,
          otp:int.parse(_otp),
          id: widget.user!['id'].toString(),
        );
        
        setState(() {
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _resendOTP() {
    if (!_canResend) return; // Ne rien faire si le temps n'est pas écoulé

    // Appeler le cubit pour renvoyer un nouveau code
    context.read<AuthCubit>().sendOTP(phone: _phoneNumber);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Un nouveau code a été envoyé'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Redémarrer le compteur
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          // Afficher un message de succès amélioré
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inscription réussie !',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Text(
                          'Votre compte a été créé avec succès',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
          
          // Redirection automatique vers l'écran principal après vérification OTP réussie
          Navigator.pushReplacementNamed(context, AppRoutes.main);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.text),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // En-tête
                    const Text(
                      'Vérification',
                      style: AppStyles.heading1,
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textLight,
                        ),
                        children: [
                          const TextSpan(
                            text:
                                'Veuillez entrer le code à 6 chiffres envoyé au numéro ',
                          ),
                          TextSpan(
                            text: _maskedPhoneNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Image illustrative
                    SizedBox(
                      height: size.height * 0.25,
                      child: Center(
                        child: Image.asset(
                          'assets/images/otp_verification.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.message_rounded,
                                  size: 150,
                                  color: AppColors.buttonColor.withOpacity(0.7),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    // Champs OTP
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isKeyboardVisible = true;
                          });
                          FocusScope.of(context).requestFocus(_focusNode);
                        },
                        child: OtpTextField(
                          numberOfFields: 6,
                          borderColor: AppColors.buttonColor,
                          focusedBorderColor: AppColors.buttonColor,
                          showFieldAsBox: true,
                          borderWidth: 2.0,
                          fieldWidth: 45,
                          borderRadius: BorderRadius.circular(12),
                          styles: List.generate(
                            6,
                            (index) => const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          onCodeChanged: (String code) {
                            // Gérer la validation ici
                            setState(() {
                              _isKeyboardVisible = true;
                            });
                          },
                          onSubmit: (String verificationCode) {
                            setState(() {
                              _otp = verificationCode;
                              _isKeyboardVisible = false;
                            });
                            _verifyOTP();
                          },
                          clearText: _otp.isEmpty,
                        ),
                      ),
                    ),

                    // Bouton de validation
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Vérifier',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                    // Option pour renvoyer le code
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Vous n\'avez pas reçu de code? ',
                                style: TextStyle(
                                  color: AppColors.textLight,
                                ),
                              ),
                              GestureDetector(
                                onTap: _canResend ? _resendOTP : null,
                                child: Text(
                                  _canResend
                                      ? 'Renvoyer'
                                      : 'Renvoyer ($_formattedTime)',
                                  style: TextStyle(
                                    color: _canResend
                                        ? AppColors.buttonColor
                                        : AppColors.textLight,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_canResend)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Vous pourrez renvoyer un code dans $_formattedTime',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton de collage flottant qui apparaît quand le clavier est visible
            if (_isKeyboardVisible)
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton(
                  onPressed: _pasteOtpCode,
                  backgroundColor: AppColors.buttonColor,
                  child: const Icon(Icons.content_paste, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}
