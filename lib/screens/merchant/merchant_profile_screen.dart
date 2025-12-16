import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants.dart';
import '../../cubit/auth_cubit.dart';
import '../product/product_detail_screen.dart';

class MerchantProfileScreen extends StatefulWidget {
  final String name;
  final String imagePath;
  final String category;
  final double rating;
  final String description;
  final bool isVerified;
  final List<Map<String, dynamic>> products;
  final String merchantId; // Ajout de l'ID du marchand

  const MerchantProfileScreen({
    Key? key,
    required this.name,
    required this.imagePath,
    required this.category,
    required this.rating,
    required this.isVerified,
    required this.products,
    required this.description,
    required this.merchantId, // Ajout du paramètre
  }) : super(key: key);

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isFollowing = false;
  
  // Variables pour les abonnés
  int followersCount = 0;
  List<Map<String, dynamic>> subscribersList = [];
  bool isLoadingSubscribers = false;
  
  // Méthode pour gérer les abonnements
  Future<void> _toggleSubscription() async {
    try {
      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vous devez être connecté pour vous abonner'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      final user = authState.user!;
      final userId = user['id']?.toString() ?? '';
      final userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
      final userImage = user['media'] ?? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg';
      
      // ID du marchand
      final merchantId = widget.merchantId;
      
      if (isFollowing) {
        // Se désabonner
        await _unsubscribeFromMerchant(userId, merchantId);
      } else {
        // S'abonner
        await _subscribeToMerchant(userId, userName, merchantId, userImage);
      }
      
      setState(() {
        isFollowing = !isFollowing;
      });
      
      // Recharger les abonnés après le changement
      await _loadSubscribers();
      
    } catch (e) {
      print('Erreur lors de la gestion de l\'abonnement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Méthode pour s'abonner à un marchand
  Future<void> _subscribeToMerchant(String userId, String userName, String merchantId, String userImage) async {
    try {
      await FirebaseFirestore.instance.collection('abonnements').add({
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'merchantId': merchantId, // Vrai ID du marchand
        'merchantName': widget.name,
        'merchantImage': widget.imagePath,
        'merchantCategory': widget.category,
        'isActive': true,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Abonnement à ${widget.name} réussi !'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('Erreur lors de l\'abonnement: $e');
      throw Exception('Erreur lors de l\'abonnement: $e');
    }
  }
  
  // Méthode pour se désabonner d'un marchand
  Future<void> _unsubscribeFromMerchant(String userId, String merchantId) async {
    try {
      // Rechercher l'abonnement existant
      final subscriptionQuery = await FirebaseFirestore.instance
          .collection('abonnements')
          .where('userId', isEqualTo: userId)
          .where('merchantId', isEqualTo: merchantId)
          .where('isActive', isEqualTo: true)
          .get();
      
      if (subscriptionQuery.docs.isNotEmpty) {
        // Désactiver l'abonnement
        await subscriptionQuery.docs.first.reference.update({
          'isActive': false,
          'unsubscribedAt': FieldValue.serverTimestamp(),
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Désabonnement de ${widget.name} réussi !'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
    } catch (e) {
      print('Erreur lors du désabonnement: $e');
      throw Exception('Erreur lors du désabonnement: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    print('🚀 MerchantProfileScreen initialisé pour: ${widget.name} (ID: ${widget.merchantId})');
    _checkSubscriptionStatus();
    _loadSubscribers();
  }
  
  // Méthode pour vérifier le statut d'abonnement
  Future<void> _checkSubscriptionStatus() async {
    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final userId = authState.user!['id']?.toString() ?? '';
        final merchantId = widget.merchantId;
        
        // Vérifier si l'utilisateur est déjà abonné
        final subscriptionQuery = await FirebaseFirestore.instance
            .collection('abonnements')
            .where('userId', isEqualTo: userId)
            .where('merchantId', isEqualTo: merchantId)
            .where('isActive', isEqualTo: true)
            .get();
        
        if (mounted) {
          setState(() {
            isFollowing = subscriptionQuery.docs.isNotEmpty;
          });
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du statut d\'abonnement: $e');
    }
  }
  
  // Méthode pour charger les abonnés
  Future<void> _loadSubscribers() async {
    try {
      print('🔄 Début du chargement des abonnés...');
      setState(() {
        isLoadingSubscribers = true;
      });
      
      final merchantId = widget.merchantId;
      print('📍 MerchantId: $merchantId');
      
      // Récupérer tous les abonnements (requête simple pour éviter les problèmes d'index)
      final subscribersQuery = await FirebaseFirestore.instance
          .collection('abonnements')
          .get();
      
      print('📊 Nombre total d\'abonnements: ${subscribersQuery.docs.length}');
      
      if (mounted) {
        setState(() {
          // Filtrer côté client
          final filteredDocs = subscribersQuery.docs.where((doc) {
            final data = doc.data();
            return data['merchantId'] == merchantId && data['isActive'] == true;
          }).toList();
          
          followersCount = filteredDocs.length;
          subscribersList = filteredDocs.map((doc) {
            final data = doc.data();
            print('👤 Abonné: ${data['userName']} - ${data['userId']}');
            return {
              'id': doc.id,
              'userId': data['userId'] ?? '',
              'userName': data['userName'] ?? '',
              'userImage': data['userImage'] ?? '',
              'timestamp': data['timestamp'],
            };
          }).toList();
          
          // Trier côté client par timestamp (plus récent en premier)
          subscribersList.sort((a, b) {
            final timestampA = a['timestamp'] as Timestamp?;
            final timestampB = b['timestamp'] as Timestamp?;
            if (timestampA == null || timestampB == null) return 0;
            return timestampB.compareTo(timestampA); // Ordre décroissant
          });
          
          isLoadingSubscribers = false;
        });
        
        print('✅ Abonnés chargés avec succès. Count: $followersCount');
      }
      
    } catch (e) {
      print('❌ Erreur lors du chargement des abonnés: $e');
      if (mounted) {
        setState(() {
          isLoadingSubscribers = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure imagePath is not null or empty
    final safeImagePath = widget.imagePath.isNotEmpty 
        ? widget.imagePath 
        : 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg';
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with merchant cover image
          SliverAppBar(
            expandedHeight: 180.0,
            pinned: true,
            systemOverlayStyle: SystemUiOverlayStyle.light,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image with gradient overlay
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent],
                      ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image.network(
                      safeImagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(Icons.store, color: Colors.grey.shade400, size: 80),
                        );
                      },
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
          
          // Merchant profile information
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image and name
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.grey.shade100,
                          backgroundImage: NetworkImage(safeImagePath),
                          onBackgroundImageError: (_, __) {},
                          child: ClipOval(
                            child: Image.network(
                              safeImagePath,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(Icons.store, color: Colors.grey.shade400, size: 32),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (widget.isVerified) ...[
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Stats card
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isLoadingSubscribers)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          _buildStatColumn(_formatCount(followersCount), 'Abonnés'),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Follow/Message buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _toggleSubscription,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFollowing ? Colors.grey.shade200 : AppColors.primary,
                            foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isFollowing ? 'Abonné' : 'S\'abonner',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.message_outlined, size: 20),
                          onPressed: () {},
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 14),
                  
                  // Description
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Vendeur officiel de ${widget.category.toLowerCase()}. Livraison rapide et produits de qualité garantis.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Tab Bar
          SliverPersistentHeader(
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.grid_on, size: 20),
                    text: 'Produits',
                  ),
                  Tab(
                    icon: Icon(Icons.favorite_border, size: 20),
                    text: 'Abonnés',
                  ),
                ],
              ),
            ),
            pinned: true,
          ),
          
          // Tab Bar View
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsGrid(),
                _buildSubscribersList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  // Widget pour afficher la liste des abonnés
  Widget _buildSubscribersList() {
    print('🔍 _buildSubscribersList appelé - isLoading: $isLoadingSubscribers, count: ${subscribersList.length}');
    
    if (isLoadingSubscribers) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (subscribersList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun abonné pour le moment',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les abonnés apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            // Widget de débogage
    
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: subscribersList.length,
      itemBuilder: (context, index) {
        final subscriber = subscribersList[index];
        final timestamp = subscriber['timestamp'] as Timestamp?;
        final date = timestamp?.toDate();
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              backgroundImage: NetworkImage(subscriber['userImage'] ?? 'https://www.shutterstock.com/image-vector/vector-flat-illustration-grayscale-avatar-600nw-2281862025.jpg'),
              onBackgroundImageError: (_, __) {},
            ),
            title: Text(
              subscriber['userName']?.toString() ?? 'Utilisateur inconnu',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              date != null 
                ? 'Abonné le ${date.day}/${date.month}/${date.year}'
                : 'Abonné récemment',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductsGrid() {
    final List<Map<String, dynamic>> products = widget.products;
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
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
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        // Safe access to image: nouveau format (image) ou ancien format (media.mediaUrl)
        String imagePath = 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop';
        
        // Priorité 1: Nouveau format avec 'image' (string)
        if (product['image'] != null && product['image'].toString().isNotEmpty) {
          imagePath = product['image'].toString();
        }
        // Priorité 2: Ancien format avec 'media.mediaUrl'
        else if (product['media'] != null && product['media'] is Map) {
          final media = product['media'] as Map<String, dynamic>;
          if (media['mediaUrl'] != null && media['mediaUrl'].toString().isNotEmpty) {
            imagePath = media['mediaUrl'].toString();
          }
        }
        
        return _buildProductItem(
          idVendeur: product['vendeurId']?.toString() ?? '',
          description: product['description']?.toString() ?? '',
          stock: int.tryParse(product['stock']?.toString() ?? '0') ?? 0,
          id: int.tryParse(product['id']?.toString() ?? index.toString()) ?? index,
          name: product['name']?.toString() ?? '',
          price: product['price'] != null ? double.tryParse(product['price'].toString()) ?? 0.0 : 0.0,
          imagePath: imagePath,
          tag: 'Produit',
          category: product['description']?.toString() ?? '',
        );
      },
    );
  }

  Widget _buildProductItem({
    required String idVendeur,
    required String description,
    required int id,
    required String name,
    required double price,
    required String imagePath,
    required String tag,
    required String category,
    required int stock,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              description: description,
              idVendeur: idVendeur,
              stock: stock,
              id: id,
              tag: tag,
              category: category,
              name: name,
              price: price,
              imagePath: imagePath
            ),
          ),
        );
      },
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with tag
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          final expectedTotalBytes = loadingProgress.expectedTotalBytes;
                          return Center(
                            child: CircularProgressIndicator(
                              value: expectedTotalBytes != null && expectedTotalBytes > 0
                                ? loadingProgress.cumulativeBytesLoaded / expectedTotalBytes
                                : null,
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade100,
                            child: Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 32),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$price FC",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '5.0',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
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
}

// Custom SliverPersistentHeaderDelegate
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
