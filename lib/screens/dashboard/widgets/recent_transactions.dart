import 'package:flutter/material.dart';
import '../../../constants.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions récentes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.payment, color: AppColors.primary),
                  ),
                  title: Text(
                    'Paiement loyer',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  subtitle: Text(
                    '12 Jan 2024',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Text(
                    '\$ 1,200',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
