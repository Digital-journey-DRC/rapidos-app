import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/main_screen.dart';
import 'package:immo/screens/auth/login_screen.dart';
import 'package:immo/services/auth_gate_service.dart';
import 'package:immo/cubit/auth_cubit.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthGateService _authGateService = AuthGateService();

  @override
  void initState() {
    super.initState();
    // Attendre que le widget soit complètement monté avant de commencer le bootstrap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    try {
      print('🚀 AuthGate: Démarrage de l\'initialisation...');
      
      // D'ABORD vérifier si c'est la première fois
      final isFirst = await _authGateService.isFirstTime();
      print('🔍 AuthGate: Première fois? $isFirst');
      
      if (isFirst) {
        // Première fois : faire l'auto-login avec les credentials par défaut
        print('🆕 AuthGate: Première utilisation, auto-login avec credentials par défaut...');
        final autoLoginSuccess = await _authGateService.tryAutoLogin();
        print('🔍 AuthGate: Résultat auto-login première fois: $autoLoginSuccess');
        
        if (autoLoginSuccess) {
          print('✅ AuthGate: Auto-login réussi, synchronisation avec AuthCubit...');
          await _syncWithAuthCubit();
          print('🏠 AuthGate: Redirection basée sur le rôle...');
          _redirectBasedOnRole();
        } else {
          print('❌ AuthGate: Auto-login échoué, redirection vers LoginScreen');
          _goToLogin();
        }
      } else {
        // Pas la première fois : vérifier si une session valide existe
        print('🔄 AuthGate: Pas première fois, vérification de la session existante...');
        final hasSession = await _authGateService.hasValidSession();
        print('🔍 AuthGate: Résultat vérification session: $hasSession');
        
        if (hasSession) {
          // Session valide trouvée : utiliser cette session
          print('✅ AuthGate: Session valide trouvée, synchronisation avec AuthCubit...');
          await _syncWithAuthCubit();
          print('🏠 AuthGate: Redirection basée sur le rôle...');
          _redirectBasedOnRole();
        } else {
          // Pas de session valide : rediriger vers login
          print('❌ AuthGate: Aucune session valide, redirection vers LoginScreen');
          _goToLogin();
        }
      }
    } catch (e) {
      print('❌ AuthGate: Erreur lors de l\'initialisation: $e');
      _goToLogin();
    }
  }

  /// Synchronise les données de session avec AuthCubit
  Future<void> _syncWithAuthCubit() async {
    try {
      final token = await _authGateService.getToken();
      final userData = await _authGateService.getUserData();
      
      if (token != null && userData != null) {
        // Informer AuthCubit de la session existante
        if (mounted) {
          // Utiliser checkAuth() pour restaurer la session
          await context.read<AuthCubit>().checkAuth();
          print('✅ AuthCubit synchronisé avec la session');
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la synchronisation avec AuthCubit: $e');
    }
  }

  /// Redirige vers l'écran approprié selon le rôle de l'utilisateur
  Future<void> _redirectBasedOnRole() async {
    try {
      final userRole = await _authGateService.getUserRole();
      print('🎭 AuthGate: Rôle utilisateur détecté: $userRole');
      
      if (mounted) {
        // Utiliser MainScreen qui gère automatiquement la navigation selon le rôle
        print('🏠 AuthGate: Redirection vers MainScreen...');
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const MainScreen()),
              (route) => false,
            );
            print('✅ AuthGate: Navigation vers MainScreen effectuée pour le rôle: $userRole');
          }
        });
      } else {
        print('❌ AuthGate: Widget non monté, impossible de naviguer');
      }
    } catch (e) {
      print('❌ AuthGate: Erreur lors de la redirection basée sur le rôle: $e');
      // En cas d'erreur, rediriger vers MainScreen par défaut
      _goToMainScreen();
    }
  }

  void _goToMainScreen() {
    if (mounted) {
      print('🏠 AuthGate: Redirection vers MainScreen...');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
          print('✅ AuthGate: Navigation vers MainScreen effectuée');
        }
      });
    } else {
      print('❌ AuthGate: Widget non monté, impossible de naviguer');
    }
  }

  void _goToLogin() {
    if (mounted) {
      print('🔐 AuthGate: Redirection vers LoginScreen...');
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
          print('✅ AuthGate: Navigation vers LoginScreen effectuée');
        }
      });
    } else {
      print('❌ AuthGate: Widget non monté, impossible de naviguer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                // boxShadow: [
                //   BoxShadow(
                //     color: Colors.grey.withOpacity(0.3),
                //     spreadRadius: 2,
                //     blurRadius: 8,
                //     offset: const Offset(0, 4),
                //   ),
                // ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/rapidos.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback vers l'icône si l'image ne charge pas
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.delivery_dining,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Indicateur de chargement
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            
            // Texte de chargement
            const Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            
            // Sous-texte
            const Text(
              'Initialisation de l\'application',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
