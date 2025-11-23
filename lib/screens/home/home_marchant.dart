import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/screens/home/voir_plus_produits.dart';
import 'package:immo/screens/home/detail_produit_marchant.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/product_cubit.dart';
import 'package:immo/models/product.dart';
import 'package:immo/services/storage_service.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:immo/screens/dashboard/setting_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/widgets/shimmer_loading.dart';
import 'package:immo/cubit/category_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:immo/screens/product/merchant_promo_products_screen.dart';
import 'package:immo/screens/product/merchant_recommended_products_screen.dart';
import 'package:immo/services/promotion_service.dart';
import 'package:immo/models/promotion.dart';

class HomeMarchantScreen extends StatefulWidget {
  const HomeMarchantScreen({Key? key}) : super(key: key);

  @override
  State<HomeMarchantScreen> createState() => _HomeMarchantScreenState();
}

class _HomeMarchantScreenState extends State<HomeMarchantScreen> {
  String? _selectedCategory;
  final List<String> _categories = [
    'sports',
    
  ];

  bool _isLoading = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    context.read<ProductCubit>().fetchProducts();
    context.read<CategoryCubit>().fetchCategories();
    _getCurrentLocation();
    
  }

  

void saveCommande() async {
    // Enregistrer la commande
    DocumentReference commandeRef = await FirebaseFirestore.instance.collection('commandes').add({
      'client': 'Joël',
      'adresse': 'Gombe',
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });

    print("✅ Commande enregistrée avec succès: ${commandeRef.id}");

}


  Future<void> _getCurrentLocation() async {
    try {
      // Vérifier et demander les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      // Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Animer la caméra vers la position
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print('Erreur de localisation: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddProductSheet() {
    final _nameController = TextEditingController();
    final _stockController = TextEditingController();
    final _badgeController = TextEditingController();
    final _priceController = TextEditingController();
    final _categoryController = TextEditingController();
    File? _imageFile;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text('Ajouter un produit',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nom du produit',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _badgeController,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^[0-9]+([.][0-9]{0,2})?')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Prix',
                        // prefixIcon: const Icon(Icons.attach_money),
                        // prefixIcon: const Text("FC", style: TextStyle(fontSize: 20),),
                        prefixIcon: const Padding(padding: EdgeInsets.only(left:10), child: Text("FC", style: TextStyle(fontSize: 18),),),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        labelText: 'Stock',
                        prefixIcon: const Icon(Icons.inventory_2_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<CategoryCubit, CategoryState>(
                      builder: (context, state) {
                        if (state is CategoryLoading) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (state is CategoryLoaded) {
                          return DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Catégorie',
                              prefixIcon: const Icon(Icons.category_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: state.categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat.name,
                                      child: Text(cat.name),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            },
                          );
                        }
                        if (state is CategoryError) {
                          return Text('Erreur chargement catégories', style: TextStyle(color: Colors.red));
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        _showImageSourceDialog(context, setState, (file) {
                          _imageFile = file;
                        });
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _imageFile != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(_imageFile!, fit: BoxFit.cover),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children:[
                                  Icon(Icons.add_photo_alternate, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Ajouter une image', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_nameController.text.isNotEmpty &&
                                    _badgeController.text.isNotEmpty &&
                                    _priceController.text.isNotEmpty &&
                                    _stockController.text.isNotEmpty &&
                                    _selectedCategory != null &&
                                    _imageFile != null) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  try {
                                    var request = http.MultipartRequest(
                                      'POST',
                                      Uri.parse('http://24.144.87.127:3333/products/store'),
                                    );
                                    // Headers
                                    final token = await StorageService().getToken();
                                    request.headers.addAll({
                                      'Authorization': 'Bearer $token',
                                    });
                                    // Fields
                                    request.fields.addAll({
                                      'name': _nameController.text,
                                      'description': _badgeController.text,
                                      'price': _priceController.text,
                                      'stock': _stockController.text,
                                      'category': _selectedCategory!,
                                    });
                                    // File
                                    request.files.add(
                                      await http.MultipartFile.fromPath(
                                        'medias',
                                        _imageFile!.path,
                                      ),
                                    );
                                    var response = await request.send();
                                    var responseData = await response.stream.bytesToString();
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    if (response.statusCode == 201) {
                                      Navigator.pop(context);
                                      context.read<ProductCubit>().fetchProducts();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Produit ajouté avec succès !'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    } else {
                                      throw Exception('Erreur lors de l\'ajout du produit : ' + responseData);
                                    }
                                  } catch (e) {
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Erreur: ${e.toString()}'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Veuillez remplir tous les champs requis'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Ajouter', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showImageSourceDialog(BuildContext context, StateSetter setSheetState, Function(File) onImageSelected) {
    final ImagePicker _picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 800,
                );
                if (image != null && context.mounted) {
                  setSheetState(() {
                    onImageSelected(File(image.path));
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.photo_library, size: 40, color: AppColors.buttonColor),
                  SizedBox(height: 8),
                  Text('Galerie'),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 800,
                );
                if (photo != null && context.mounted) {
                  setSheetState(() {
                    onImageSelected(File(photo.path));
                  });
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.camera_alt, size: 40, color: AppColors.buttonColor),
                  SizedBox(height: 8),
                  Text('Caméra'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const AppLogo(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthSuccess && state.user != null && state.user!['media'] != null) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.white,
                        backgroundImage: NetworkImage(state.user!['media']),
                      ),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingScreen()),
                      );
                    },
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.buttonColor2,
                      child: CircleAvatar(
                        radius: 17,
                        backgroundColor: AppColors.buttonColor,
                        child: Icon(Icons.person, color: AppColors.white),
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const SizedBox(height: 30),
            // Navigation rapide
            // const Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     _QuickNavButton(
            //         icon: Icons.local_shipping, label: 'Livraisons'),
            //     _QuickNavButton(icon: Icons.inventory_2, label: 'Produits'),
            //     _QuickNavButton(icon: Icons.person, label: 'Profil'),
            //   ],
            // ),
            // const SizedBox(height: 12),
            // Profil

            // const SizedBox(height: 18),
            // Vos Produits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ElevatedButton(onPressed: saveCommande, child: const Text('Enregistrer commande')),
                const Text('Mes Produits',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Cliquez pour modifier',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) => const ProductCardShimmer(),
                    ),
                  );
                }
                
                if (state is ProductError) {
                  return Center(child: state.message == 'Pas de produits trouvés' ? const SizedBox(
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Aucun produit pour l'instant", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ) : const Text('Erreur lors du chargement des produits'));
                }
                
                if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return const SizedBox(
                      height: 120,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.inbox, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Aucun produit pour l'instant", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = state.products.reversed.toList()[index];
                        return SizedBox(
                          width: 220,
                          child: _ProductCard(
                            badge: product.category?.name ?? '',
                            name: product.name,
                            stock: product.stock.toString(),
                            isPromo: false,
                            price: product.price.toString(),
                            imageUrl: product.media?.mediaUrl ?? 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
                            productId: product.id,
                          ),
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 20),
            
            // Section: Produits en promotions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produits en promotions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MerchantPromoProductsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                int? merchantId;
                if (authState is AuthSuccess && authState.user != null) {
                  final userId = authState.user!['id'];
                  print('🔍 home_marchant - userId brut: $userId (type: ${userId.runtimeType})');
                  if (userId != null) {
                    if (userId is int) {
                      merchantId = userId;
                      print('🔍 home_marchant - userId est int: $merchantId');
                    } else if (userId is String) {
                      merchantId = int.tryParse(userId);
                      print('🔍 home_marchant - userId est String, parsé: $merchantId');
                    } else if (userId is num) {
                      merchantId = userId.toInt();
                      print('🔍 home_marchant - userId est num, converti: $merchantId');
                    }
                  } else {
                    print('🔍 home_marchant - userId est null');
                  }
                } else {
                  print('🔍 home_marchant - authState n\'est pas AuthSuccess ou user est null');
                }
                print('🔍 home_marchant - merchantId final: $merchantId');
                
                return FutureBuilder<Map<String, dynamic>>(
                  future: merchantId != null
                      ? PromotionService().getMerchantPromotions(merchantId)
                      : PromotionService().getPromotions(),
                  builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                
                if (snapshot.hasData && snapshot.data!['success'] == true) {
                  final promotions = snapshot.data!['promotions'] as List<Promotion>;
                  final activePromos = promotions.where((p) => p.isActive).toList();
                  
                  if (activePromos.isEmpty) {
                    return const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Aucune promotion active',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: activePromos.length > 5 ? 5 : activePromos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final promotion = activePromos[index];
                        final product = promotion.product;
                        if (product == null) return const SizedBox.shrink();
                        
                        return SizedBox(
                          width: 220,
                          child: _ProductCard(
                            badge: 'PROMO',
                            name: product.name,
                            stock: product.stock.toString(),
                            isPromo: true,
                            price: promotion.nouveauPrix.toString(),
                            imageUrl: promotion.image,
                            productId: product.id,
                          ),
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      'Erreur chargement promotions',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                );
                  },
                );
              },
            ),

            const SizedBox(height: 20),
            
            // Section: Produits recommandés
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Produits recommandés',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MerchantRecommendedProductsScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            BlocBuilder<ProductCubit, ProductState>(
              builder: (context, state) {
                if (state is ProductLoaded && state.products.isNotEmpty) {
                  // Filtrer les produits recommandés (logique simple basée sur le stock et prix)
                  final recommended = state.products
                      .where((p) => p.stock > 20 && p.price > 0 && p.price < 50000)
                      .toList();
                  
                  if (recommended.isEmpty) {
                    return const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Aucun produit recommandé',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  
                  return SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recommended.length > 5 ? 5 : recommended.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final product = recommended[index];
                        return SizedBox(
                          width: 220,
                          child: _ProductCard(
                            badge: product.category?.name ?? '',
                            name: product.name,
                            stock: product.stock.toString(),
                            isPromo: false,
                            price: product.price.toString(),
                            imageUrl: product.media?.mediaUrl ?? 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
                            productId: product.id,
                          ),
                        );
                      },
                    ),
                  );
                }
                return const SizedBox(
                  height: 60,
                  child: Center(
                    child: Text(
                      'Aucun produit recommandé',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Livraisons en cours
            const Text('Position du livreur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
        
            // Carte de livraison
            const SizedBox(height: 18),
            // Carte de livraison
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _currentPosition == null
                        ? const Center(
                            child: Text('Impossible d\'obtenir la localisation',
                                style: TextStyle(color: Colors.black54)))
                        : GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              zoom: 15,
                            ),
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            mapType: MapType.normal,
                          ),
              ),
            ),

            // Avis Clients
            const Text('Avis Clients',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _ReviewCard(
                      client: 'Client A',
                      comment: 'Excellent service!',
                      rating: 5),
                  SizedBox(width: 10),
                  _ReviewCard(
                      client: 'Client B',
                      comment: 'Livraison rapide et efficace.',
                      rating: 4),
                ],
              ),
            ),
            



     

            const SizedBox(height: 10),
            // Produits recommandés (carousel placeholder)

            const SizedBox(height: 18),
            // Statistiques de vente
            const Text('Statistiques de Vente',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Row(
              children: [
                _StatCard(title: 'Ventes', value: '150', percent: '+10%'),
                const SizedBox(width: 10),
                _StatCard(title: 'Clients', value: '200', percent: '-5%'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Ajouter un produit',
      ),

    );
  }
}

class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickNavButton({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary),
          ),
          padding: const EdgeInsets.all(20),
          child: Icon(icon, color: AppColors.primary, size: 8),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}

class _ProductCard extends StatefulWidget {
  final String badge;
  final String name;
  final String stock;
  final bool isPromo;
  final String imageUrl;
  final String price;
  final int productId;
  const _ProductCard(
      {required this.badge,
      required this.name,
      required this.stock,
      required this.price,
      required this.isPromo,
      required this.imageUrl,
      required this.productId});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final String displayImageUrl = (widget.imageUrl.isEmpty || widget.imageUrl == 'null')
        ? 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop'
        : widget.imageUrl.startsWith('http')
            ? widget.imageUrl
            : 'http://24.144.87.127:3333/$widget.imageUrl';
    return GestureDetector(
      onTap: () {
        // Si c'est une promotion, rediriger vers la page des promotions
        if (widget.isPromo) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MerchantPromoProductsScreen(),
            ),
          );
        } else {
          // Sinon, navigation vers la page de détail du produit
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailProduitMarchantScreen(
                productName: widget.name,
                productPrice: widget.price,
                productStock: widget.stock,
                productBadge: widget.badge,
                productImageUrl: widget.imageUrl,
                isPromo: widget.isPromo,
                productId: widget.productId,
              ),
            ),
          );
        }
      },
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return SizedBox(
            width: 220,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.center,
              child: Container(
                width: 220,
                height: 110,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                              child: Image.network(
                                displayImageUrl,
                                width: 64,
                                height: 110,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 64,
                                  height: 110,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.isPromo ? Colors.redAccent : AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.badge,
                                  style: const TextStyle(color: Colors.white, fontSize: 11),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 4),
                                Text("En Stock: "+widget.stock,
                                    style:
                                        TextStyle(color: Colors.grey[600], fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  "${widget.price} FC",
                                  style: TextStyle(
                                    color: widget.isPromo ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Indicateur de clic pour modifier
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'Modifier',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Indicateur de clic subtil
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String client;
  final String comment;
  final int rating;
  const _ReviewCard(
      {required this.client, required this.comment, required this.rating});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 14, color: Colors.white)),
              const SizedBox(width: 8),
              Text(client,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(
                children: List.generate(
                    rating,
                    (index) =>
                        const Icon(Icons.star, color: Colors.amber, size: 14)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _DeliveryRow extends StatelessWidget {
  final String title;
  final String status;
  final String livreur;
  final IconData icon;
  final Color iconColor;
  const _DeliveryRow(
      {required this.title,
      required this.status,
      required this.livreur,
      required this.icon,
      required this.iconColor});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(status, style: const TextStyle(color: Colors.grey)),
          const Spacer(),
          Text('Livreur: $livreur',
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          const Icon(Icons.notifications_active, color: Colors.amber, size: 18),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final String label;
  const _ChipButton({required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.primary.withOpacity(0.13),
      labelStyle: const TextStyle(color: AppColors.primary),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  const _CategoryCard({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String percent;
  const _StatCard(
      {required this.title, required this.value, required this.percent});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const Spacer(),
            Row(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(width: 8),
                Text(percent,
                    style: TextStyle(
                        color:
                            percent.startsWith('+') ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCardShimmer extends StatelessWidget {
  const OrderCardShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline shimmer
          Container(
            width: 6,
            height: 110,
            margin: const EdgeInsets.only(right: 10, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: AppColors.buttonColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Image shimmer
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 0, right: 10),
            child: ShimmerLoading(
              width: 70,
              height: 70,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          // Détails shimmer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 90,
                        height: 16,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 8),
                      ShimmerLoading(
                        width: 60,
                        height: 16,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoading(
                    width: 120,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 12),
                      ShimmerLoading(
                        width: 50,
                        height: 14,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ShimmerLoading(
                        width: 80,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      const SizedBox(width: 8),
                      ShimmerLoading(
                        width: 60,
                        height: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductCardShimmer extends StatelessWidget {
  const ProductCardShimmer({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                  child: ShimmerLoading(
                    width: 64,
                    height: 110,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: ShimmerLoading(
                    width: 40,
                    height: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerLoading(
                      width: 80,
                      height: 15,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 4),
                    ShimmerLoading(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 4),
                    ShimmerLoading(
                      width: 50,
                      height: 13,
                      borderRadius: BorderRadius.circular(6),
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
