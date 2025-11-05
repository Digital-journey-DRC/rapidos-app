import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'store_service.dart';
import '../widgets/update_modal.dart';
import '../widgets/update_modal_v2.dart';

class VersionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Récupérer la version actuelle de l'app
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      int currentBuildNumber = int.parse(packageInfo.buildNumber);
      
      print('📱 Version actuelle: $currentVersion (build: $currentBuildNumber)');
      
      // Récupérer ou créer la version depuis Firebase
      DocumentSnapshot versionDoc = await _firestore
          .collection('version')
          .doc('latest')
          .get();
      
      Map<String, dynamic> versionData;
      
      if (!versionDoc.exists) {
        print('⚠️ Document version non trouvé dans Firebase, création automatique...');
        
        // Créer le document avec des valeurs par défaut
        versionData = {
          'ios': 1,
          'android': 1,
          'description': 'Version initiale',
          'created_at': FieldValue.serverTimestamp(),
        };
        
        await _firestore
            .collection('version')
            .doc('latest')
            .set(versionData);
        
        print('✅ Document version créé avec succès');
      } else {
        versionData = versionDoc.data() as Map<String, dynamic>;
        print('✅ Document version trouvé dans Firebase');
      }
      
      String description = versionData['description'] ?? '';
      
      // Déterminer la version minimale selon la plateforme
      int minVersion;
      if (Platform.isAndroid) {
        minVersion = versionData['android'] ?? 0;
      } else if (Platform.isIOS) {
        minVersion = versionData['ios'] ?? 0;
      } else {
        return; // Pas de vérification pour les autres plateformes
      }
      
      print('📱 Version minimale requise: $minVersion');
      
      // Vérifier si une mise à jour est nécessaire
      if (currentBuildNumber < minVersion) {
        print('⚠️ Mise à jour requise: $currentBuildNumber < $minVersion');
        // Afficher le modal de mise à jour forcée avec votre charte graphique
        UpdateModalV2Helper.showUpdateModalV2(context, description: description);
      } else {
        print('✅ Version à jour: $currentBuildNumber >= $minVersion');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la vérification de version: $e');
    }
  }
  

  
  static Future<void> _openStore() async {
    await StoreService.openStore();
  }
}
