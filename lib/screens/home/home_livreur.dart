import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';

class HomeLivreurScreen extends StatelessWidget {
  const HomeLivreurScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            Image.asset(AppAssets.logo, width: 60, height: 60),
            
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess && state.user != null && state.user!['profileImage'] != null) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.white,
                        backgroundImage: NetworkImage(state.user!['profileImage']),
                      ),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingScreen()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.white,
                        child: Icon(Icons.person, color: AppColors.buttonColor),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header profil
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess && state.user != null) {
                  return Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${state.user!['firstName'] ?? ''} ${state.user!['lastName'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                          const Text('Livreur', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  );
                }
                return const Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Livreur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                        Text('Livreur', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            // Livraison en cours
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Livraison en cours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: const [
                      Text('Voir tout', style: TextStyle(color: AppColors.primary)),
                      Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            _CommandeRow(
              icon: Icons.inventory_2,
              title: 'Commande 1234',
              heure: '14:00',
              status: 'En route',
              statusColor: Colors.green,
            ),
            _CommandeRow(
              icon: Icons.inventory_2,
              title: 'Commande 5678',
              heure: '15:30',
              status: 'Attente',
              statusColor: Colors.orange,
            ),
            const SizedBox(height: 16),
            // Carte de position livraison
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('Position Livraison', style: TextStyle(color: Colors.black54))),
            ),
            const SizedBox(height: 18),
            // Evaluations clients
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Évaluations des Clients', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: const [
                      Text('Voir tout', style: TextStyle(color: AppColors.primary)),
                      Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _ReviewCard(client: 'Client A', comment: 'Livreur très courtois', rating: 5),
                  SizedBox(width: 10),
                  _ReviewCard(client: 'Client B', comment: 'Livraison à l\'heure', rating: 4),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Performance du jour
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Performance du Jour', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Voir Détails', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            Row(
              children: const [
                _StatCard(title: 'Livraisons Complétées', value: '10'),
                SizedBox(width: 12),
                _StatCard(title: 'Kilomètres parcourus', value: '50'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CommandeRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String heure;
  final String status;
  final Color statusColor;
  const _CommandeRow({required this.icon, required this.title, required this.heure, required this.status, required this.statusColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Livraison prévue: $heure', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Text('Status: ', style: const TextStyle(color: Colors.black54)),
          Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String client;
  final String comment;
  final int rating;
  const _ReviewCard({required this.client, required this.comment, required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 12, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(client, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(rating, (index) => const Icon(Icons.star, color: Colors.amber, size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
    );
  }
} 