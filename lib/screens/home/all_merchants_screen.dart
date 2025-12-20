import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import '../merchant/vendeur_detail_screen.dart';
import 'package:immo/widgets/app_logo.dart';

class AllMerchantsScreen extends StatefulWidget {
  const AllMerchantsScreen({Key? key}) : super(key: key);

  @override
  State<AllMerchantsScreen> createState() => _AllMerchantsScreenState();
}

class _AllMerchantsScreenState extends State<AllMerchantsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Tous les marchands',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un marchand...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _search = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<MerchantCubit, MerchantState>(
              builder: (context, state) {
                if (state is MerchantLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is MerchantLoaded) {
                  final merchants = state.merchants.where((m) {
                    final vendeur = m['vendeur'];
                    final name = ('${vendeur['firstName']} ${vendeur['lastName']}').toLowerCase();
                    return _search.isEmpty || name.contains(_search);
                  }).toList();
                  if (merchants.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun marchand trouvé',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: merchants.length,
                    itemBuilder: (context, index) {
                      final vendeur = merchants[index]['vendeur'];
                      final products = (merchants[index]['products'] as List).cast<Map<String, dynamic>>();
                      final media = merchants[index]['media'];
                      final image = media != null && media['mediaUrl'] != null
                          ? media['mediaUrl']
                          : 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop';
                      final name = '${vendeur['firstName']} ${vendeur['lastName']}';
                      final vendeurId = vendeur['id'] is int 
                          ? vendeur['id'] 
                          : int.tryParse(vendeur['id'].toString());
                      final productCount = products.length;
                      
                      return GestureDetector(
                        onTap: () {
                          // Utiliser VendeurDetailScreen pour la cohérence
                          if (vendeurId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VendeurDetailScreen(
                                  vendeurId: vendeurId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Image du marchand
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade50,
                                    child: Image.network(
                                      image,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Icon(
                                          Icons.store,
                                          color: Colors.grey.shade400,
                                          size: 24,
                                        ),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Nom du marchand
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 3),
                                // Note et nombre de produits
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber.shade700,
                                      size: 11,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '4.5',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$productCount',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                if (state is MerchantError) {
                  return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
} 