import 'package:flutter/material.dart';
import '../../widgets/image_viewer.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Image
        Positioned.fill(
          child: ImageViewerWidget(
            url: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?q=80&w=2070',
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            imageFit: BoxFit.cover,
          ),
        ),
        // Content
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeText(),
                      _buildSearchBar(),
                      _buildContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 4),
                Text('Paris', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Text(
        'Trouvez votre\nprochain chez-vous',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Rechercher un bien',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Type • Prix • Surface',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Biens recommandés',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(),
          const SizedBox(height: 24),
          const Text(
            'Découvrez nos quartiers',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDiscoverSection(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPropertyCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ImageViewerWidget(
                  url: 'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=2070',
                  width: double.infinity,
                  height: 200,
                  imageFit: BoxFit.cover,
                ),
              ),
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Appartement moderne à Paris',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.star, size: 16),
                        Text('4.8 (32)'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '75m² • 3 pièces • 1 salle de bain • 2ème étage',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '450 000€ ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: '• '),
                      TextSpan(text: '6 000€/m²'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverSection() {
    final List<String> discoverImages = [
      'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?q=80&w=2074',
      'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?q=80&w=2070',
      'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?q=80&w=2029',
    ];
    
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: discoverImages.length,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(left: index == 0 ? 0 : 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ImageViewerWidget(
                url: discoverImages[index],
                width: 160,
                height: 120,
                imageFit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
