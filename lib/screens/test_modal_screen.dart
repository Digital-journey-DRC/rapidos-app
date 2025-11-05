import 'package:flutter/material.dart';
import '../widgets/update_modal.dart';
import '../widgets/update_modal_v2.dart';
import '../constants.dart';

class TestModalScreen extends StatelessWidget {
  const TestModalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Modals'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations sur les couleurs
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Votre Charte Graphique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildColorRow('Primary', AppColors.primary),
                    _buildColorRow('Secondary', AppColors.secondary),
                    _buildColorRow('Accent', AppColors.accent),
                    _buildColorRow('Button Color 2', AppColors.buttonColor2),
                    _buildColorRow('Background', AppColors.background),
                    _buildColorRow('Text', AppColors.text),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Test Modal Original
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modal Original (Gradient)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Gradient avec vos couleurs primary et buttonColor2',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showOriginalModal(context),
                      icon: const Icon(Icons.preview),
                      label: const Text('Tester Modal Original'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Modal V2
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modal V2 (Design Moderne)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Design épuré avec vos couleurs et styles',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showV2Modal(context),
                      icon: const Icon(Icons.preview),
                      label: const Text('Tester Modal V2'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor2,
                        foregroundColor: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Comparaison
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comparaison des Designs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonRow(
                      'Modal Original',
                      'Gradient avec animation',
                      'Couleurs: Primary + ButtonColor2',
                    ),
                    _buildComparisonRow(
                      'Modal V2',
                      'Design épuré moderne',
                      'Couleurs: Primary + Styles',
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
                      '• Testez les deux modals pour voir la différence\n'
                      '• Le modal V2 utilise votre charte graphique complète\n'
                      '• Le modal original utilise un gradient avec vos couleurs\n'
                      '• Vous pouvez choisir celui qui vous plaît le plus',
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

  Widget _buildColorRow(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$name: ${color.value.toRadixString(16).toUpperCase()}'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String title, String description, String colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            colors,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showOriginalModal(BuildContext context) {
    UpdateModalHelper.showUpdateModal(
      context,
      description: 'Test du modal original avec gradient utilisant votre charte graphique.',
    );
  }

  void _showV2Modal(BuildContext context) {
    UpdateModalV2Helper.showUpdateModalV2(
      context,
      description: 'Test du modal V2 avec design moderne utilisant votre charte graphique complète.',
    );
  }
}
