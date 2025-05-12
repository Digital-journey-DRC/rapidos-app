import 'package:flutter/material.dart';

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
            color: Colors.black,
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
                          color: Colors.black,
                          height: 40,
                          width: 40,
                          child: const Icon(Icons.search, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Trouvez ce dont vous avez besoin',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Category icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCategoryItem('Food', Icons.fastfood),
                  _buildCategoryItem('Laptop', Icons.laptop_mac),
                  _buildCategoryItem('Smart Watch', Icons.watch),
                ],
              ),
            ),

            // Featured products section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produits vedettes',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 12),

                  // Products grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildProductCard(
                          tag: 'Nouveau',
                          category: 'Poisson',
                          name: 'Poisson Shaba',
                          price: '20 000 FC',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProductCard(
                          tag: 'En vente',
                          category: 'Laptop',
                          name: 'Laptop Pro',
                          price: '5 00 \$',
                        ),
                      ),
                    ],
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
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                    const Icon(Icons.location_on, color: Colors.grey),
                    const Positioned(
                      bottom: 10,
                      child: Text(
                        'Position Livraison',
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter options
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 0, top: 8.0, bottom: 16.0),
              child: Row(
                children: [
                  const Text('Filtre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Prix croissant', style: TextStyle(color: Colors.black, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Prix décroissant', style: TextStyle(color: Colors.black, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Dernier arrivage', style: TextStyle(color: Colors.black, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Panier',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard_outlined),
            label: 'commandes',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, color: Colors.blueAccent, size: 20),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  Widget _buildProductCard({
    required String tag,
    required String category,
    required String name,
    required String price,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                tag,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const Spacer(),
            Text(
              category,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
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
