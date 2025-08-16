import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/version_service.dart';

class TestFirebaseScreen extends StatefulWidget {
  const TestFirebaseScreen({Key? key}) : super(key: key);

  @override
  State<TestFirebaseScreen> createState() => _TestFirebaseScreenState();
}

class _TestFirebaseScreenState extends State<TestFirebaseScreen> {
  Map<String, dynamic>? _versionData;
  Map<String, String>? _appInfo;
  String _status = 'En attente...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _status = 'Chargement...';
    });

    try {
      // Récupérer les informations de l'app
      final packageInfo = await PackageInfo.fromPlatform();
      _appInfo = {
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };

      // Récupérer les données Firebase
      final doc = await FirebaseFirestore.instance
          .collection('version')
          .doc('latest')
          .get();

      if (doc.exists) {
        _versionData = doc.data() as Map<String, dynamic>;
        _status = '✅ Données Firebase récupérées avec succès';
      } else {
        _status = '❌ Document "latest" non trouvé dans la collection "version"';
      }
    } catch (e) {
      _status = '❌ Erreur: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testVersionCheck() async {
    setState(() {
      _isLoading = true;
      _status = 'Test de vérification de version...';
    });

    try {
      await VersionService.checkForUpdate(context);
      _status = '✅ Test de vérification terminé';
    } catch (e) {
      _status = '❌ Erreur lors du test: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase Version'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Informations de l'application
            if (_appInfo != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations de l\'Application',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Version: ${_appInfo!['version']}'),
                      Text('Build Number: ${_appInfo!['buildNumber']}'),
                      Text('Package: ${_appInfo!['packageName']}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Données Firebase
            if (_versionData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Données Firebase',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('iOS: ${_versionData!['ios']}'),
                      Text('Android: ${_versionData!['android']}'),
                      Text('Description: ${_versionData!['description'] ?? 'Aucune'}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Comparaison
            if (_appInfo != null && _versionData != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Comparaison',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                                             _buildComparisonRow('iOS', _appInfo!['buildNumber'] ?? '0', _versionData!['ios']),
                       _buildComparisonRow('Android', _appInfo!['buildNumber'] ?? '0', _versionData!['android']),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualiser les données'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testVersionCheck,
              icon: const Icon(Icons.system_update),
              label: const Text('Tester la vérification de version'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Vérifiez que la collection "version" existe dans Firebase\n'
                      '2. Vérifiez que le document "latest" existe\n'
                      '3. Vérifiez que les champs ios, android et description sont présents\n'
                      '4. Si les données ne se chargent pas, vérifiez les règles de sécurité Firestore',
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

  Widget _buildComparisonRow(String platform, String current, dynamic required) {
    final currentNum = int.tryParse(current) ?? 0;
    final requiredNum = required is int ? required : int.tryParse(required.toString()) ?? 0;
    final needsUpdate = currentNum < requiredNum;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$platform: '),
          Text('$currentNum vs $requiredNum'),
          const SizedBox(width: 8),
          Icon(
            needsUpdate ? Icons.warning : Icons.check_circle,
            color: needsUpdate ? Colors.orange : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            needsUpdate ? 'Mise à jour requise' : 'À jour',
            style: TextStyle(
              color: needsUpdate ? Colors.orange : Colors.green,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
