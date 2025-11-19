import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import '../merchant/merchant_profile_screen.dart';
import 'package:immo/constants.dart';
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
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un marchand...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
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
                    return const Center(child: Text('Aucun marchand trouvé'));
                  }
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
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
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MerchantProfileScreen(
                                  description: products.isNotEmpty ? products[0]['description'] ?? '' : '',
                                  merchantId: vendeur['id'].toString(),
                                  name: name,
                                  rating: 4.5,
                                  category: products.isNotEmpty ? products[0]['description'] ?? '' : '',
                                  imagePath: image,
                                  isVerified: true,
                                  products: products,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.07),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: Image.network(
                                      image,
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        height: 80,
                                        width: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(50),
                                        ),
                                        child: const Icon(Icons.store, color: Colors.grey, size: 40),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: AppColors.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 14),
                                    const SizedBox(width: 4),
                                    Text('4.5', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  products.isNotEmpty ? products[0]['description'] ?? '' : '',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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