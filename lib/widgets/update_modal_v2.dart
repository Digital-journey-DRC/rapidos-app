import 'dart:io';
import 'package:flutter/material.dart';
import '../services/store_service.dart';
import '../constants.dart';

class UpdateModalV2 extends StatelessWidget {
  final String description;
  final VoidCallback? onUpdatePressed;
  
  const UpdateModalV2({
    Key? key,
    required this.description,
    this.onUpdatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône avec cercle coloré
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              
              // Titre
              Text(
                'Mise à jour disponible',
                style: AppStyles.heading2.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Description
              Text(
                description.isNotEmpty 
                    ? description 
                    : 'Une nouvelle version de l\'application est disponible avec des améliorations et corrections de bugs.',
                style: AppStyles.body.copyWith(
                  color: AppColors.textLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Bouton principal
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (onUpdatePressed != null) {
                      onUpdatePressed!();
                    } else {
                      StoreService.openStore();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Platform.isAndroid 
                            ? Icons.android 
                            : Icons.apple,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
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
              ),
              const SizedBox(height: 12),
              
              // Bouton secondaire
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () {
                    // Optionnel : permettre de fermer le modal
                    // Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textLight,
                  ),
                  child: const Text(
                    'Plus tard',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Texte informatif
              Text(
                'Cette mise à jour est obligatoire pour continuer à utiliser l\'application.',
                style: AppStyles.caption.copyWith(
                  color: AppColors.textLight.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper pour afficher le modal V2
class UpdateModalV2Helper {
  static void showUpdateModalV2(
    BuildContext context, {
    required String description,
    VoidCallback? onUpdatePressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return UpdateModalV2(
          description: description,
          onUpdatePressed: onUpdatePressed,
        );
      },
    );
  }
}
