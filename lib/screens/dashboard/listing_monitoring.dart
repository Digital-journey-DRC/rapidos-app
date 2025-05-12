import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/constants.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:immo/widgets/custom_skeletons.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubit/listing_cubit.dart';
import '../../cubit/listing_state.dart';

class ListingMonitoring extends StatefulWidget {
  const ListingMonitoring({super.key});

  @override
  State<ListingMonitoring> createState() => _ListingMonitoringState();
}

class _ListingMonitoringState extends State<ListingMonitoring> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMoreData = true;
  static const String defaultImageUrl = 'https://ability2access.com/wp-content/plugins/ecommerce-product-catalog/img/no-default-thumbnail.png';

  void shareAnnonce(String idAnnonce) {
    final String lien = "https://www.geniusvente.com/annonce/${idAnnonce}";

    Share.share(lien, subject: "Découvrez cette annonce !");
  }

  @override
  void initState() {
    super.initState();
    _loadListings();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasMoreData &&
          _scrollController.position.maxScrollExtent > 0) {
        _loadMoreListings();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadListings() {
    setState(() {
      _hasMoreData = true;
      _currentPage = 1;
    });

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess &&
        authState.token != null &&
        authState.user != null) {
      final userId = authState.user!['id'];
      context.read<ListingCubit>().getUserListings(
            token: authState.token!,
            userId: userId,
            page: 1,
            limit: 10,
          );
    }
  }

  void _loadMoreListings() {
    final authState = context.read<AuthCubit>().state;
    final state = context.read<ListingCubit>().state;

    if (authState is AuthSuccess &&
        authState.token != null &&
        authState.user != null &&
        state is ListingSuccess) {
      final count = (state.data['count'] ?? 0) as int;
      final totalPages = (count / 10).ceil();
      if (_currentPage < totalPages) {
        _currentPage++;
        final userId = authState.user!['id'];
        context.read<ListingCubit>().getUserListings(
              token: authState.token!,
              userId: userId,
              page: _currentPage,
              limit: 10,
            );
      } else {
        setState(() {
          _hasMoreData = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return '';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    bool isAuthenticated = authState is AuthSuccess && authState.token != null;

    if (!isAuthenticated) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Veuillez vous connecter pour accéder à vos annonces',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Mes Annonces',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadListings,
          ),
        ],
      ),
      body: BlocBuilder<ListingCubit, ListingState>(
        builder: (context, state) {
          if (state is ListingLoading) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title skeleton
                  const SkeletonLine(
                    style: SkeletonLineStyle(
                      width: 200,
                      height: 24,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Listing skeletons
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const SkeletonLine(
                                  style: SkeletonLineStyle(
                                    width: 180,
                                    height: 18,
                                    borderRadius: BorderRadius.all(Radius.circular(8)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.buttonColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const SkeletonLine(
                                    style: SkeletonLineStyle(
                                      width: 60,
                                      height: 12,
                                      borderRadius: BorderRadius.all(Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Image and details row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Thumbnail skeleton
                                SkeletonAvatar(
                                  style: SkeletonAvatarStyle(
                                    width: 80,
                                    height: 80,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                
                                // Details column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      SkeletonLine(
                                        style: SkeletonLineStyle(
                                          width: 150,
                                          height: 16,
                                          borderRadius: BorderRadius.all(Radius.circular(4)),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      SkeletonLine(
                                        style: SkeletonLineStyle(
                                          width: 180,
                                          height: 14,
                                          borderRadius: BorderRadius.all(Radius.circular(4)),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      SkeletonLine(
                                        style: SkeletonLineStyle(
                                          width: 120,
                                          height: 14,
                                          borderRadius: BorderRadius.all(Radius.circular(4)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            const Divider(),
                            
                            // Actions row skeleton
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                for (int i = 0; i < 3; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: SkeletonAvatar(
                                      style: SkeletonAvatarStyle(
                                        width: 30,
                                        height: 30,
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }

          if (state is ListingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur: ${state.message}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadListings,
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          if (state is ListingSuccess) {
            final listings = state.data['data'] as List;
            if (listings.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.home_outlined, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune annonce trouvée',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Vous n\'avez pas encore publié d\'annonce',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              controller: _scrollController,
              itemCount: listings.length + (_hasMoreData ? 1 : 0),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                if (index == listings.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SkeletonLine(
                        style: SkeletonLineStyle(
                          width: 80,
                          height: 16,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                      ),
                    ),
                  );
                }

                final listing = listings[index];
                final apartment = listing['apartmentId'] ?? {};
                final building = apartment['buildingId'] ?? {};
                final address = building['address'] ?? {};
                final images = apartment['images'] as List? ?? [];
                final image = images.isNotEmpty
                    ? images[0]
                    : defaultImageUrl;

                return Card(
                  color: Colors.grey[100],
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(
                      // color: Colors.grey.withOpacity(0.5),
                      color: AppColors.buttonColor,
                      width: 2,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      // Handle tap
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            image,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.network(
                                defaultImageUrl,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.home_outlined, size: 50, color: Colors.grey),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing['title'] ?? 'Sans titre',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${address['street'] ?? ''}, ${address['city'] ?? ''}',
                                      style:
                                          const TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.home_outlined,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Type: ${(apartment['type'] ?? '').toUpperCase()}',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${listing['price']?['amount']} ${listing['price']?['currency']}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                          listing['status'] ?? ''),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      (listing['status'] ?? 'N/A')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Publié le: ${_formatDate(listing['createdAt'] ?? '')}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: AppColors.buttonColor,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          // Handle edit
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.edit_outlined,
                                                  color: AppColors.buttonColor,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Modifier',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: AppColors.buttonColor,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          shareAnnonce(listing['_id'].toString());
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.share_outlined,
                                                  color: AppColors.buttonColor,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Partager',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: AppColors.buttonColor,
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(8),
                                        onTap: () {
                                          // Handle edit
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: const Icon(
                                                  Icons.delete_outline,
                                                  color: AppColors.buttonColor,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'Supprimer',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
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
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}
