import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/version_admin_service.dart';

class AdminVersionScreen extends StatefulWidget {
  const AdminVersionScreen({Key? key}) : super(key: key);

  @override
  State<AdminVersionScreen> createState() => _AdminVersionScreenState();
}

class _AdminVersionScreenState extends State<AdminVersionScreen> {
  final _iosController = TextEditingController(text: '1');
  final _androidController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController(text: 'Améliorations et corrections de bugs');
  
  Map<String, String>? _appInfo;
  Map<String, dynamic>? _currentVersions;
  bool _isLoading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _iosController.dispose();
    _androidController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

      // Récupérer les versions actuelles
      _currentVersions = await VersionAdminService.getCurrentVersions();
      
      if (_currentVersions != null) {
        _iosController.text = _currentVersions!['ios'].toString();
        _androidController.text = _currentVersions!['android'].toString();
        _descriptionController.text = _currentVersions!['description'] ?? '';
      }

      _status = '✅ Données chargées avec succès';
    } catch (e) {
      _status = '❌ Erreur: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateVersions() async {
    setState(() {
      _isLoading = true;
      _status = 'Mise à jour en cours...';
    });

    try {
      await VersionAdminService.updateVersionRequirements(
        iosVersion: int.parse(_iosController.text),
        androidVersion: int.parse(_androidController.text),
        description: _descriptionController.text,
      );
      
      _status = '✅ Versions mises à jour avec succès';
      await _loadData(); // Recharger les données
    } catch (e) {
      _status = '❌ Erreur: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceUpdate() async {
    setState(() {
      _isLoading = true;
      _status = 'Forçage de mise à jour...';
    });

    try {
      final currentBuild = int.parse(_appInfo?['buildNumber'] ?? '1');
      await VersionAdminService.forceUpdate(
        iosVersion: currentBuild + 1,
        androidVersion: currentBuild + 1,
        description: 'Mise à jour obligatoire - ${_descriptionController.text}',
      );
      
      _status = '✅ Mise à jour forcée pour tous les utilisateurs';
      await _loadData();
    } catch (e) {
      _status = '❌ Erreur: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disableForceUpdate() async {
    setState(() {
      _isLoading = true;
      _status = 'Désactivation des mises à jour forcées...';
    });

    try {
      await VersionAdminService.disableForceUpdate();
      _status = '✅ Mises à jour forcées désactivées';
      await _loadData();
    } catch (e) {
      _status = '❌ Erreur: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createTestVersion() async {
    setState(() {
      _isLoading = true;
      _status = 'Création de version de test...';
    });

    try {
      await VersionAdminService.createTestVersion();
      _status = '✅ Version de test créée (mise à jour forcée)';
      await _loadData();
    } catch (e) {
      _status = '❌ Erreur: $e';
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
        title: const Text('Admin - Gestion des Versions'),
        backgroundColor: Colors.red,
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
                        'Application Actuelle',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Version: ${_appInfo!['version']}'),
                      Text('Build: ${_appInfo!['buildNumber']}'),
                      Text('Package: ${_appInfo!['packageName']}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Formulaire de mise à jour
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration des Versions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _iosController,
                      decoration: const InputDecoration(
                        labelText: 'Version iOS minimale',
                        hintText: '1',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _androidController,
                      decoration: const InputDecoration(
                        labelText: 'Version Android minimale',
                        hintText: '1',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description de la mise à jour',
                        hintText: 'Améliorations et corrections de bugs',
                      ),
                      maxLines: 3,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateVersions,
                      icon: const Icon(Icons.update),
                      label: const Text('Mettre à jour les versions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Actions rapides
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Actions Rapides',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _forceUpdate,
                            icon: const Icon(Icons.warning),
                            label: const Text('Forcer Mise à Jour'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _disableForceUpdate,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Désactiver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _createTestVersion,
                        icon: const Icon(Icons.science),
                        label: const Text('Créer Version de Test'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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
                      '• Mettre à jour les versions : Change les versions minimales\n'
                      '• Forcer mise à jour : Force tous les utilisateurs à mettre à jour\n'
                      '• Désactiver : Désactive les mises à jour forcées\n'
                      '• Version de test : Crée une version très élevée pour tester',
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
}
