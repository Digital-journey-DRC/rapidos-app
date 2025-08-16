import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/version_service.dart';
import '../services/store_service.dart';
import '../widgets/update_modal.dart';

class TestVersionScreen extends StatelessWidget {
  const TestVersionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Version Checker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Informations sur la version actuelle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Version Actuelle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder(
                      future: _getVersionInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final versionInfo = snapshot.data as Map<String, String>;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Version: ${versionInfo['version']}'),
                              Text('Build: ${versionInfo['buildNumber']}'),
                              Text('Package: ${versionInfo['packageName']}'),
                            ],
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Boutons de test
            ElevatedButton.icon(
              onPressed: () => _testVersionCheck(context),
              icon: const Icon(Icons.system_update),
              label: const Text('Vérifier la version'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: () => _testUpdateModal(context),
              icon: const Icon(Icons.update),
              label: const Text('Tester le modal de mise à jour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: () => _testStoreOpening(context),
              icon: const Icon(Icons.store),
              label: const Text('Tester l\'ouverture du store'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Instructions
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions de Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Configurez Firebase avec une version supérieure à la version actuelle\n'
                      '2. Testez la vérification automatique\n'
                      '3. Vérifiez que le modal s\'affiche correctement\n'
                      '4. Testez l\'ouverture du store',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<Map<String, String>> _getVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };
    } catch (e) {
      return {
        'version': 'Erreur',
        'buildNumber': 'Erreur',
        'packageName': 'Erreur',
      };
    }
  }
  
  void _testVersionCheck(BuildContext context) async {
    try {
      await VersionService.checkForUpdate(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vérification de version terminée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _testUpdateModal(BuildContext context) {
    UpdateModalHelper.showUpdateModal(
      context,
      description: 'Ceci est un test du modal de mise à jour avec une description personnalisée.',
    );
  }
  
  void _testStoreOpening(BuildContext context) async {
    try {
      await StoreService.openStore();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ouverture du store tentée'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
