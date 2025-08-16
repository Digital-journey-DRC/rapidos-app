import 'package:cloud_firestore/cloud_firestore.dart';

class VersionAdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Met à jour les versions minimales requises
  static Future<void> updateVersionRequirements({
    required int iosVersion,
    required int androidVersion,
    required String description,
  }) async {
    try {
      await _firestore.collection('version').doc('latest').set({
        'ios': iosVersion,
        'android': androidVersion,
        'description': description,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      print('✅ Versions mises à jour avec succès');
      print('📱 iOS: $iosVersion, Android: $androidVersion');
      print('📝 Description: $description');
    } catch (e) {
      print('❌ Erreur lors de la mise à jour des versions: $e');
      rethrow;
    }
  }
  
  /// Récupère les versions actuelles
  static Future<Map<String, dynamic>?> getCurrentVersions() async {
    try {
      final doc = await _firestore
          .collection('version')
          .doc('latest')
          .get();
      
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des versions: $e');
      return null;
    }
  }
  
  /// Force une mise à jour pour tous les utilisateurs
  static Future<void> forceUpdate({
    required int iosVersion,
    required int androidVersion,
    required String description,
  }) async {
    // Utilise une version très élevée pour forcer la mise à jour
    await updateVersionRequirements(
      iosVersion: iosVersion,
      androidVersion: androidVersion,
      description: description,
    );
  }
  
  /// Désactive les mises à jour forcées
  static Future<void> disableForceUpdate() async {
    await updateVersionRequirements(
      iosVersion: 1,
      androidVersion: 1,
      description: 'Mises à jour désactivées',
    );
  }
  
  /// Crée une version de test
  static Future<void> createTestVersion() async {
    await updateVersionRequirements(
      iosVersion: 999,
      androidVersion: 999,
      description: 'Version de test - Mise à jour forcée',
    );
  }
}
