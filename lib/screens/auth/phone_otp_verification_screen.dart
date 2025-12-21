import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../../constants.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';

class PhoneOTPVerificationScreen extends StatefulWidget {
  final String newPhone;
  
  const PhoneOTPVerificationScreen({
    Key? key,
    required this.newPhone,
  }) : super(key: key);

  @override
  State<PhoneOTPVerificationScreen> createState() => _PhoneOTPVerificationScreenState();
}

class _PhoneOTPVerificationScreenState extends State<PhoneOTPVerificationScreen> {
  String _otp = '';
  bool _isLoading = false;
  final ProfileService _profileService = ProfileService();
  
  // Variables pour le compteur
  int _remainingSeconds = 300; // 5 minutes = 300 secondes
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _canResend = false;
    _remainingSeconds = 300;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String _maskPhoneNumber(String phone) {
    if (phone.length <= 7) return phone;
    final start = phone.substring(0, 4);
    final end = phone.substring(phone.length - 3);
    final masked = 'X' * (phone.length - 7);
    return '$start$masked$end';
  }

  Future<void> _verifyOTP() async {
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

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final result = await _profileService.verifyPhoneOTP(
        token: token,
        otp: _otp,
        newPhone: widget.newPhone,
      );

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Numéro de téléphone mis à jour avec succès'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Retourner à l'écran précédent
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await StorageService().getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      await _profileService.updatePhone(
        token: token,
        newPhone: widget.newPhone,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un nouveau code a été envoyé'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification OTP'),
        backgroundColor: AppColors.buttonColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 40),
              
              // Icône
              Icon(
                Icons.phone_android,
                size: 80,
                color: AppColors.buttonColor,
              ),
              
              const SizedBox(height: 24),
              
              // Titre
              const Text(
                'Vérification du numéro',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                'Un code de vérification a été envoyé au numéro\n${_maskPhoneNumber(widget.newPhone)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Champs OTP
              OtpTextField(
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
                  setState(() {
                    _otp = code;
                  });
                },
                onSubmit: (String verificationCode) {
                  setState(() {
                    _otp = verificationCode;
                  });
                  _verifyOTP();
                },
              ),
              
              const SizedBox(height: 24),
              
              // Compteur et bouton renvoyer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_canResend) ...[
                    Text(
                      'Renvoyer le code dans ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.buttonColor,
                      ),
                    ),
                  ] else
                    TextButton(
                      onPressed: _isLoading ? null : _resendOTP,
                      child: const Text(
                        'Renvoyer le code',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Bouton de validation
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading || _otp.length != 6 ? null : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Vérifier',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

