import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/product/product_detail_screen.dart';
import '../merchant/merchant_profile_screen.dart';

class NewHomeScreen extends StatelessWidget {
  const NewHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'RAPIDOS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Recherche',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ),
                        ),
                        Container(
                          color: AppColors.primary,
                          height: 40,
                          width: 40,
                          child: const Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Trouvez ce dont vous avez besoin',
                    style: TextStyle( fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Category icons - scrollable
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildCategoryItem('Food', Icons.fastfood),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Laptop', Icons.laptop_mac),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Smart Watch', Icons.watch),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Téléphone', Icons.phone_android),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Vêtements', Icons.shopping_bag),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Meubles', Icons.chair),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Beauté', Icons.face),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Sport', Icons.fitness_center),
                    const SizedBox(width: 16),
                    _buildCategoryItem('Livres', Icons.book),
                  ],
                ),
              ),
            ),

            // Featured products section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Produits vedettes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal scrollable products
                  SizedBox(
                    height: 190,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        _buildProductCard(
                          tag: 'Nouveau',
                          category: 'Poisson',
                          name: 'Poisson Shaba',
                          price: '20 000 FC',
                          imagePath: 'https://images.unsplash.com/photo-1574781330855-d0db8cc6a79c?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                        ),
                        const SizedBox(width: 12),
                        _buildProductCard(
                          tag: 'En vente',
                          category: 'Laptop',
                          name: 'Laptop Pro',
                          price: '5 00 \$',
                          imagePath: 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                        ),
                        const SizedBox(width: 12),
                        _buildProductCard(
                          tag: 'Populaire',
                          category: 'Montre',
                          name: 'Smart Watch',
                          price: '200 \$',
                          imagePath: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                        ),
                        const SizedBox(width: 12),
                        _buildProductCard(
                          tag: 'Nouveau',
                          category: 'Vêtements',
                          name: 'T-shirt Classique',
                          price: '25 000 FC',
                          imagePath: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Top Marchands section
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Top Marchands',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal scrollable merchants
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      children: [
                        _buildMerchantCard(
                          name: 'Rapidos Store',
                          rating: 4.8,
                          category: 'Électronique',
                          imagePath: 'https://images.unsplash.com/photo-1511649475669-e288648b2339?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                          isVerified: true,
                        ),
                        const SizedBox(width: 12),
                        _buildMerchantCard(
                          name: 'Fresh Foods',
                          rating: 4.6,
                          category: 'Alimentation',
                          imagePath: 'https://images.unsplash.com/photo-1533900298318-6b8da08a523e?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                          isVerified: true,
                        ),
                        const SizedBox(width: 12),
                        _buildMerchantCard(
                          name: 'Style Mode',
                          rating: 4.7,
                          category: 'Vêtements',
                          imagePath: 'https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                          isVerified: true,
                        ),
                        const SizedBox(width: 12),
                        _buildMerchantCard(
                          name: 'Tech Hub',
                          rating: 4.5,
                          category: 'Informatique',
                          imagePath: 'https://images.unsplash.com/photo-1518770660439-4636190af475?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                          isVerified: false,
                        ),
                        const SizedBox(width: 12),
                        _buildMerchantCard(
                          name: 'Déco Maison',
                          rating: 4.4,
                          category: 'Décoration',
                          imagePath: 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80',
                          isVerified: false,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // User profile
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 16,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Doe',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.primary),
                      ),
                      Text(
                        'Heureux de vous revoir !',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Customer reviews
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Avis des clients',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReviewCard('Alice', 5, 'Excellent produit'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildReviewCard('Bob', 5, 'Excellent service'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Map background with pattern
                    CustomPaint(
                      painter: MapPatternPainter(),
                      size: Size.infinite,
                    ),
                    Icon(Icons.location_on, color: AppColors.primary.withOpacity(0.7)),
                   const Positioned(
                      bottom: 10,
                      child: Text(
                        'Position Livraison',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.primary),
                      ),
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

  Widget _buildCategoryItem(String title, IconData icon) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(5),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.grey.shade100, size: 20),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildProductCard({
    required String tag,
    required String category,
    required String name,
    required String price,
    required String imagePath,
  }) {
    return Builder(
      builder: (context) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(
                  tag: tag,
                  category: category,
                  name: name,
                  price: price,
                  imagePath: imagePath,
                ),
              ),
            );
          },
          child: Container(
            width: 150,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container with tag overlay
                Stack(
                  children: [
                    // Product image
                    Hero(
                      tag: imagePath,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                        child: Image.network(
                          imagePath,
                          height: 100,
                          width: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              width: 150,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                    ),
                    // Tag label
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                // Product details
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMerchantCard({
    required String name,
    required double rating,
    required String category,
    required String imagePath,
    required bool isVerified,
  }) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MerchantProfileScreen(
                name: name,
                rating: rating,
                category: category,
                imagePath: imagePath,
                isVerified: isVerified,
              ),
            ),
          );
        },
        child: Container(
          width: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Merchant image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
                child: Image.network(
                  imagePath,
                  width: 60,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 100,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.store, color: Colors.grey.shade400),
                    );
                  },
                ),
              ),
              // Merchant details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Merchant name with verification badge
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isVerified) const SizedBox(width: 4),
                          if (isVerified)
                            const Icon(
                              Icons.verified,
                              color: AppColors.primary,
                              size: 14,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Category
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(String name, int rating, String comment) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                radius: 12,
              ),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(
              rating,
              (index) => const Icon(Icons.star, color: Colors.amber, size: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

// Custom painter to draw a grid pattern for the map background
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    double horizontalSpacing = 15;
    for (double i = 0; i < size.height; i += horizontalSpacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    double verticalSpacing = 15;
    for (double i = 0; i < size.width; i += verticalSpacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw diagonal lines for a more map-like appearance
    for (double i = -size.height; i < size.width + size.height; i += horizontalSpacing * 2) {
      canvas.drawLine(
        Offset(i, 0), 
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
