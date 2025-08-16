import 'dart:io';
import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../constants.dart';

class UpdateModal extends StatelessWidget {
  final String description;
  final VoidCallback? onUpdatePressed;
  
  const UpdateModal({
    Key? key,
    required this.description,
    this.onUpdatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Empêcher la fermeture avec le bouton retour
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
                    child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.buttonColor2,
                  ],
                ),
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône animée de mise à jour
              _buildUpdateIcon(),
              const SizedBox(height: 24),
              
              // Titre
                                const Text(
                    'Mise à jour disponible',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                description.isNotEmpty 
                    ? description 
                    : 'Une nouvelle version de l\'application est disponible avec des améliorations et corrections de bugs.',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Bouton de mise à jour
              _buildUpdateButton(context),
              const SizedBox(height: 16),
              
              // Texte informatif
              Text(
                'Cette mise à jour est obligatoire pour continuer à utiliser l\'application.',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildUpdateIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle animé
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              );
            },
          ),
          // Icône de mise à jour
          const Icon(
            Icons.system_update_rounded,
            color: AppColors.white,
            size: 40,
          ),
        ],
      ),
    );
  }
  
  Widget _buildUpdateButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          if (onUpdatePressed != null) {
            onUpdatePressed!();
          } else {
            StoreService.openStore();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Platform.isAndroid 
                  ? Icons.android 
                  : Icons.apple,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'Mettre à jour maintenant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher le modal de mise à jour
class UpdateModalHelper {
  static void showUpdateModal(
    BuildContext context, {
    required String description,
    VoidCallback? onUpdatePressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // Empêcher la fermeture en cliquant à l'extérieur
      builder: (BuildContext context) {
        return UpdateModal(
          description: description,
          onUpdatePressed: onUpdatePressed,
        );
      },
    );
  }
}
