import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../constants.dart';
import '../../services/merchant_service.dart';
import '../../models/vendeur.dart';
import '../../models/product.dart';
import '../product/product_detail_screen.dart';
import '../../services/review_service.dart';

class VendeurDetailScreen extends StatefulWidget {
  final int vendeurId;

  const VendeurDetailScreen({
    Key? key,
    required this.vendeurId,
  }) : super(key: key);

  @override
  State<VendeurDetailScreen> createState() => _VendeurDetailScreenState();
}

class _VendeurDetailScreenState extends State<VendeurDetailScreen> {
  Vendeur? _vendeur;
  bool _isLoading = true;
  String? _errorMessage;
  final MerchantService _merchantService = MerchantService();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadVendeurData();
  }

  Future<void> _loadVendeurData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _merchantService.getVendeurById(widget.vendeurId);
      
      if (mounted) {
        if (result['success'] == true) {
          setState(() {
            _vendeur = result['vendeur'] as Vendeur;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['error']?.toString() ?? 'Erreur inconnue';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getDayName(String jour) {
    final days = {
      'lundi': 'Lundi',
      'mardi': 'Mardi',
      'mercredi': 'Mercredi',
      'jeudi': 'Jeudi',
      'vendredi': 'Vendredi',
      'samedi': 'Samedi',
      'dimanche': 'Dimanche',
    };
    return days[jour.toLowerCase()] ?? jour;
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    // Convertir "07:30:00" en "07:30"
    return time.length >= 5 ? time.substring(0, 5) : time;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.06),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.store_mall_directory_rounded,
                              size: 46,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Impossible de charger ce marchand',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _loadVendeurData,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Réessayer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back, size: 18),
                                label: const Text('Retour'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _vendeur == null
                  ? const Center(child: Text('Aucune donnée disponible'))
                  : RefreshIndicator(
                      onRefresh: _loadVendeurData,
                      child: CustomScrollView(
                        slivers: [
                        // App Bar discret
                        SliverAppBar(
                          pinned: true,
                          backgroundColor: Colors.white,
                          elevation: 0,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
                            onPressed: () => Navigator.pop(context),
                          ),
                          title: Text(
                            _vendeur!.fullName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: Colors.black87),
                              onPressed: () => _showInfoBottomSheet(context),
                              tooltip: 'Informations',
                            ),
                          ],
                        ),
                        // Barre de recherche
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Rechercher un produit...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF5F5F5),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: (val) => setState(() => _search = val),
                            ),
                          ),
                        ),
                        // Header compact simplifié
                        SliverToBoxAdapter(
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Avatar simple
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: _vendeur!.profileImageUrl != null
                                      ? NetworkImage(_vendeur!.profileImageUrl!)
                                      : null,
                                  child: _vendeur!.profileImageUrl == null
                                      ? Icon(
                                          Icons.person,
                                          size: 20,
                                          color: Colors.grey.shade600,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                // Informations détaillées
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Nombre de produits
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.inventory_2_outlined,
                                            size: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${_vendeur!.totalProducts ?? 0} produits',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      // Email ou téléphone
                                      if (_vendeur!.email.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.email_outlined,
                                              size: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _vendeur!.email,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (_vendeur!.phone.isNotEmpty)
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.phone_outlined,
                                              size: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                _vendeur!.phone,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Grille de produits
                        _buildProductsSliverGrid(),
                      ],
                      ),
                    ),
    );
  }


  Widget _buildProductsSliverGrid() {
    if (_vendeur == null) {
      return SliverToBoxAdapter(
        child: const SizedBox.shrink(),
      );
    }

    final products = _vendeur!.products;
    if (products == null || products.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun produit disponible',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Filtrer les produits selon la recherche
    final filteredProducts = products.where((productJson) {
      if (_search.isEmpty) return true;
      try {
        final product = Product.fromJson(productJson as Map<String, dynamic>);
        final searchLower = _search.toLowerCase();
        return product.name.toLowerCase().contains(searchLower) ||
            product.description.toLowerCase().contains(searchLower) ||
            (product.category?.name ?? '').toLowerCase().contains(searchLower);
      } catch (e) {
        return false;
      }
    }).toList();

    if (filteredProducts.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Aucun produit trouvé',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final productJson = filteredProducts[index] as Map<String, dynamic>;
            try {
              final product = Product.fromJson(productJson);
              return _buildProductCard(product);
            } catch (e) {
              print('Erreur parsing product: $e');
              return const SizedBox.shrink();
            }
          },
          childCount: filteredProducts.length,
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final imageUrl = product.getMainImage();
    final productImages = product.getAllImages();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: product.description,
              idVendeur: product.vendeurId.toString(),
              id: product.id,
              tag: product.category?.name ?? 'PRODUIT',
              category: product.category?.name ?? '',
              stock: product.stock,
              name: product.name,
              price: product.price,
              imagePath: imageUrl,
              productImages: productImages.isNotEmpty ? productImages : null,
              product: product,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image du produit
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey.shade50,
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: double.infinity,
                      color: Colors.grey.shade100,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 32,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
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
            ),
            // Contenu de la carte
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Catégorie
                    if (product.category?.name != null && product.category!.name.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category!.name,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (product.category?.name != null && product.category!.name.isNotEmpty)
                      const SizedBox(height: 4),
                    // Nom du produit
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Prix et note
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(0)} FC',
                          style: const TextStyle(
                            color: Color(0xFF147C3C),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FutureBuilder<double>(
                          future: ReviewService().getCachedAverageRating(product.id),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data! > 0) {
                              final rating = snapshot.data!;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 11,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
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

  /// Affiche une bottom sheet avec les informations du vendeur
  void _showInfoBottomSheet(BuildContext context) {
    if (_vendeur == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Informations',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Identité
                    _buildSectionTitle('Identité'),
                    const SizedBox(height: 12),
                    _buildInfoItem('Nom complet', _vendeur!.fullName, Icons.person),
                    if (_vendeur!.email.isNotEmpty)
                      _buildInfoItem('Email', _vendeur!.email, Icons.email),
                    if (_vendeur!.phone.isNotEmpty)
                      _buildInfoItem('Téléphone', _vendeur!.phone, Icons.phone),
                    if (_vendeur!.userStatus != null)
                      _buildInfoItem('Statut', _vendeur!.userStatus!, Icons.info),
                    
                    const SizedBox(height: 24),
                    
                    // Horaires d'ouverture
                    if (_vendeur!.horairesOuverture != null &&
                        _vendeur!.horairesOuverture!.isNotEmpty) ...[
                      _buildSectionTitle('Horaires d\'ouverture'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: _vendeur!.horairesOuverture!.map((horaire) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getDayName(horaire.jour),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  if (horaire.estOuvert &&
                                      horaire.heureOuverture != null &&
                                      horaire.heureFermeture != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        '${_formatTime(horaire.heureOuverture)} - ${_formatTime(horaire.heureFermeture)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.red.shade200,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Fermé',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade800,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
