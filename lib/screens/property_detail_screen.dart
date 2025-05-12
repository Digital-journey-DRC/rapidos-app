import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/screens/main_screen.dart';
import '../widgets/image_viewer.dart';
import '../screens/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubits/message/message_cubit.dart';
import '../cubits/message/message_state.dart';
import '../screens/messages_screen.dart';
import '../repository/favorites_repository.dart';
import '../screens/favoris_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({
    Key? key,
    required this.property,
  }) : super(key: key);

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const String defaultImageUrl = 'https://ability2access.com/wp-content/plugins/ecommerce-product-catalog/img/no-default-thumbnail.png';

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.property.images.isEmpty 
        ? [defaultImageUrl]  // Use default image if no images available
        : widget.property.images;

    return Scaffold(
      body: Stack(
        children: [
          // Image Carousel
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return ImageViewerWidget(
                      url: images[index],
                      width: double.infinity,
                      height: double.infinity,
                      imageFit: BoxFit.cover,
                    );
                  },
                ),
                // Navigation Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Row(
                          children: [
                            FutureBuilder<bool>(
                              future: FavoritesRepository.isFavorite(widget.property.id),
                              builder: (context, snapshot) {
                                final isFavorite = snapshot.data ?? false;
                                return CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: Icon(
                                      isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: isFavorite ? Colors.red : null,
                                    ),
                                    onPressed: () async {
                                      await FavoritesRepository.toggleFavorite(widget.property.toJson());
                                      setState(() {}); // Rafraîchir l'UI
                                      favoritesUpdateStream.add(null); // Notifier le FavorisScreen
                                      
                                      // Afficher un message de confirmation
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isFavorite 
                                              ? 'Retiré des favoris' 
                                              : 'Ajouté aux favoris'
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.all(16),
                                          backgroundColor: isFavorite 
                                            ? Colors.grey 
                                            : Colors.green,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.ios_share),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Image Counter
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // Step Indicator
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      images.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                // Image Navigation Buttons
                Positioned.fill(
                  child: Row(
                    children: [
                      // Previous Button
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 60,
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      // Next Button
                      if (_currentPage < images.length - 1)
                        GestureDetector(
                          onTap: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 60,
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_right,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.property.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.property.location,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.property.rating} (${widget.property.reviews} avis)',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeature(
                            icon: Icons.king_bed_outlined,
                            value: '${widget.property.bedrooms}',
                            label: 'Chambres',
                          ),
                          _buildFeature(
                            icon: Icons.bathtub_outlined,
                            value: '${widget.property.bathrooms}',
                            label: 'Sdb',
                          ),
                          _buildFeature(
                            icon: Icons.square_foot,
                            value: '${widget.property.surface}',
                            label: 'm²',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.property.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Caractéristiques',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCharacteristicRow(
                      icon: Icons.location_on,
                      title: 'Localisation',
                      value: widget.property.location,
                    ),
                    const SizedBox(height: 12),
                    _buildCharacteristicRow(
                      icon: Icons.home,
                      title: 'Type',
                      value: widget.property.propertyType == PropertyType.apartmentForRent
                          ? 'Appartement à louer'
                          : 'Maison à louer',
                    ),
                    const SizedBox(height: 12),
                    _buildCharacteristicRow(
                      icon: Icons.calendar_today,
                      title: 'Disponibilité',
                      value: widget.property.availability == Availability.available
                          ? 'Disponible maintenant'
                          : 'Non disponible',
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Informations supplémentaires',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey[600]),
                              const SizedBox(width: 12),
                              const Text(
                                'À propos de ce bien',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Publié le ${widget.property.publishedAt.day}/${widget.property.publishedAt.month}/${widget.property.publishedAt.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
          // Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.property.price.toInt()} \$',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Prix/mois',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        context.read<MessageCubit>().sendMessage(
                          receiverId: widget.property.publisher['_id'],
                          content: "L'appartement est toujours dispo ?",
                          listingId: widget.property.id,
                          context: context,
                        ).then((_) {
                          final state = context.read<MessageCubit>().state;
                          if (state is MessageSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Message envoyé avec succès'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MainScreen(),
                              ),
                            );
                          } else if (state is MessageError) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.error),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: BlocBuilder<MessageCubit, MessageState>(
                        builder: (context, state) {
                          if (state is MessageLoading) {
                            return const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            );
                          }
                          return const Text('Contacter');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCharacteristicRow({required IconData icon, required String title, required String value}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }
}
