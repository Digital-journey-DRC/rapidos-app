import 'package:flutter/material.dart';
import '../../../constants.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onAddTap;

  const QuickActions({
    super.key,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: Icons.add_home_work,
                label: 'Ajouter',
                onTap: onAddTap,
              ),
              _buildActionButton(
                context,
                icon: Icons.payment,
                label: 'Paiements',
                onTap: () {},
              ),
              _buildActionButton(
                context,
                icon: Icons.message,
                label: 'Messages',
                onTap: () {},
              ),
              _buildActionButton(
                context,
                icon: Icons.analytics,
                label: 'Statistiques',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
