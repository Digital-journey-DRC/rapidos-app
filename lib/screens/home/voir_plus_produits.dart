import 'package:flutter/material.dart';
import 'package:immo/constants.dart';

class VoirPlusProduitsScreen extends StatelessWidget {
  final List<Map<String, String>> products;
  const VoirPlusProduitsScreen({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tous les produits'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return _TwitterStyleProductCard(product: product);
          },
        ),
      ),
    );
  }
}

class _TwitterStyleProductCard extends StatelessWidget {
  final Map<String, String> product;
  const _TwitterStyleProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              product['imageUrl'] ?? '',
              height: 110,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 110,
                color: Colors.grey[200],
                child: const Icon(Icons.image, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (product['isPromo'] == 'true') ? Colors.redAccent : AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(product['badge'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                    const Spacer(),
                    Icon(
                      (product['isPromo'] == 'true') ? Icons.local_offer : Icons.star,
                      color: (product['isPromo'] == 'true') ? Colors.redAccent : AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(product['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(product['stock'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${product['price'] ?? ''} FC', style: TextStyle(color: (product['isPromo'] == 'true') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 