import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../widgets/app_logo.dart';
import '../../services/profile_service.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';
import '../auth/phone_otp_verification_screen.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/merchant_section_card.dart';
// import '../../widgets/merchant_closed_banner.dart';
import '../product/merchant_promo_products_screen.dart';
import '../home/voir_plus_produits.dart';
import '../merchant/merchant_service_hours_screen.dart';
import '../merchant/payment_methods_screen.dart';
import '../../cubit/product_cubit.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen>
    with SingleTickerProviderStateMixin {
  late TabController? _tabController;
  final _formKey = GlobalKey<FormState>();

  // Text field controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _newPhoneController = TextEditingController();

  // Profile image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // User balance data
  Map<String, dynamic>? _balanceData;
  Map<String, dynamic>? _incomeSummaryData;

  // ProfileCubit instance
  late final ProfileCubit _profileCubit;

  // Données dynamiques pour les marchands
  int _allProductsCount = 0;
  int _promoProductsCount = 0;
  bool _isLoadingCounts = false;

  // StreamSubscription pour écouter les changements d'AuthCubit
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize TabController as null initially
    _tabController = null;

    // Initialize ProfileCubit
    _profileCubit = ProfileCubit(ProfileService());

    // Get current user data from AuthCubit
    // Utiliser un délai pour s'assurer que le widget est complètement monté dans l'arbre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      // Utiliser un microtask pour s'assurer que le contexte est valide
      Future.microtask(() {
        if (!mounted) return;
        _loadUserData();
        
        // Écouter les changements de l'AuthCubit
        // S'assurer que le contexte est valide avant de créer la subscription
        try {
          final authCubit = context.read<AuthCubit>();
          _authSubscription = authCubit.stream.listen((authState) {
            // Ne pas recharger si le widget est démonté ou si l'utilisateur s'est déconnecté
            if (!mounted) return;
            
            // Si l'état est AuthInitial (déconnexion), ne pas recharger les données
            if (authState is AuthInitial) {
              return;
            }
            
            if (authState is AuthSuccess && authState.user != null) {
              _loadUserData();
            }
          });
        } catch (e) {
          // Erreur silencieuse pour la production
        }
      });
    });
  }

  /// Charge les compteurs dynamiques pour les marchands
  Future<void> _loadMerchantCounts() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) return;
    
    if (authState.user!['role'] != 'vendeur') return;

    setState(() => _isLoadingCounts = true);

    try {
      // Charger les produits
      await context.read<ProductCubit>().fetchProducts();
      
      // Charger les promotions filtrées par marchand
      final promotionService = PromotionService();
      int? merchantId;
      final userId = authState.user!['id'];
      if (userId != null) {
        if (userId is int) {
          merchantId = userId;
        } else if (userId is String) {
          merchantId = int.tryParse(userId);
        } else if (userId is num) {
          merchantId = userId.toInt();
        }
      }
      final promoResult = merchantId != null
          ? await promotionService.getMerchantPromotions(merchantId)
          : await promotionService.getPromotions();
      
      if (mounted) {
        setState(() {
          // Compter les produits depuis ProductCubit
          final productState = context.read<ProductCubit>().state;
          if (productState is ProductLoaded) {
            _allProductsCount = productState.products.length;
          }
          
          // Compter les promotions actives
          if (promoResult['success'] == true) {
            final promotions = promoResult['promotions'] as List<Promotion>;
            _promoProductsCount = promotions.where((p) => p.isActive).length;
          }
          
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des compteurs: $e');
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
    }
  }

  // Méthode pour charger les données utilisateur
  void _loadUserData() {
    // Vérifier que le widget est toujours monté avant d'accéder au contexte
    if (!mounted) return;
    
    try {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      // Mettre à jour les contrôleurs avec les données actuelles
        _firstNameController.text = authState.user!['firstName'] ?? '';
        _lastNameController.text = authState.user!['lastName'] ?? '';

        // Injecter l'AuthCubit dans le ProfileCubit
        // Vérifier à nouveau que le widget est monté avant d'accéder au contexte
        if (mounted) {
          try {
            _profileCubit.setAuthCubit(context.read<AuthCubit>());
          } catch (e) {
            return;
          }
        } else {
          return;
        }

      // Set the correct number of tabs based on user role
      final isProprietaire = authState.user!['role'] == 'proprietaire';
      final isVendeur = authState.user!['role'] == 'vendeur';
      
      // Only create TabController for proprietaire users
      if (isProprietaire) {
        _tabController = TabController(
          length: 2,
          vsync: this,
        );
        
        // Load user financial data only for proprietaire
        _loadUserFinancialData(authState.user!['id'], authState.token!);
      }
      
      // Charger les compteurs pour les marchands
      if (isVendeur) {
        _loadMerchantCounts();
      }
      
      // Forcer la mise à jour de l'interface utilisateur
      if (mounted) {
        setState(() {});
      }
      }
    } catch (e) {
      // Ne pas appeler setState si le widget n'est plus monté
      if (mounted) {
        setState(() {});
      }
    }
  }

    Future<void> _fetchUserMedia() async {
    try {
      // Récupérer l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        final userId = authState.user!['id']?.toString() ?? '';
        final token = authState.token;
        
        if (userId.isNotEmpty && token != null) {
          print('🔄 Récupération des médias pour l\'utilisateur: $userId');
          
          // Requête pour récupérer les médias de l'utilisateur
          final response = await http.get(
            Uri.parse('http://24.144.87.127:3333/users/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            print('✅ Médias récupérés: ${data['data']['media']}');
            
            // Mettre à jour les données utilisateur avec les médias
            if (data['data']['media'] != null) {
              final updatedUser = Map<String, dynamic>.from(authState.user!);
              updatedUser['media'] = data['data']['media'];
              
              // Mettre à jour l'état de l'authentification
              context.read<AuthCubit>().updateUser(updatedUser, token);
            }
          } else {
            print('❌ Erreur lors de la récupération des médias: ${response.statusCode}');
          }
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la récupération des médias: $e');
    }
  }

  // Méthode pour gérer la mise à jour du profil après upload d'image
  Future<void> _handleProfileUpdate(ProfileSuccess state) async {
    // print('📥 [PROFILE PHOTO] _handleProfileUpdate() appelée');
    // print('📥 [PROFILE PHOTO] Récupération de AuthCubit...');
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    
    // print('📥 [PROFILE PHOTO] authState type: ${authState.runtimeType}');
    // print('📥 [PROFILE PHOTO] authState is AuthSuccess: ${authState is AuthSuccess}');
    
    if (authState is! AuthSuccess || authState.user == null) {
      // print('❌ [PROFILE PHOTO] Erreur: authState n\'est pas AuthSuccess ou user est null');
      return;
    }
    
    // print('📥 [PROFILE PHOTO] Utilisateur trouvé: ${authState.user!['firstName']} ${authState.user!['lastName']}');
    // print('📥 [PROFILE PHOTO] Media actuel: ${authState.user!['media']}');
    
    // Préserver toutes les informations de l'utilisateur existant
    Map<String, dynamic> updatedUserData = Map<String, dynamic>.from(authState.user!);
    
    // print('📥 [PROFILE PHOTO] Réception ProfileSuccess');
    // print('📥 [PROFILE PHOTO] state.data: ${state.data}');
    // print('📥 [PROFILE PHOTO] state.data type: ${state.data?.runtimeType}');
    
    // Si state.data est null, on récupère les données depuis l'API
    if (state.data == null) {
      print('⚠️ state.data est null, récupération depuis /users/me...');
      // Récupérer les données utilisateur depuis l'API
      try {
        final response = await http.get(
          Uri.parse('http://24.144.87.127:3333/users/me'),
          headers: {
            'Authorization': 'Bearer ${authState.token}',
            'Content-Type': 'application/json',
          },
        );
        
        if (response.statusCode == 200) {
          final apiData = jsonDecode(response.body);
          print('✅ Données récupérées depuis API: ${apiData['data']}');
          
          if (apiData['data'] != null) {
            final userData = apiData['data'];
            
            // Mettre à jour le champ media si disponible
            if (userData['media'] != null) {
              updatedUserData['media'] = userData['media'];
              print('✅ Media mis à jour: ${userData['media']}');
            }
            
            // Mettre à jour les autres champs
            final fieldsToUpdate = ['firstName', 'lastName', 'email', 'phone'];
            for (final field in fieldsToUpdate) {
              if (userData[field] != null) {
                updatedUserData[field] = userData[field];
              }
            }
          }
        }
      } catch (e) {
        print('❌ Erreur lors de la récupération des données: $e');
      }
    } else {
      // Structure des données - format unifié
      // - Cas 1: { user: { firstName, lastName, etc. }, profileImage: "url" }
      // - Cas 2: { firstName, lastName, etc., media: "url" }
      // - Cas 3: { data: { user: {...}, media: "url" } }
      
      Map<String, dynamic> userData = state.data!;
      
      // Si les données sont dans un objet 'data'
      if (state.data!['data'] != null) {
        userData = state.data!['data'];
      }
      
      // Si les données sont dans un objet 'user'
      if (userData['user'] != null) {
        final userInfo = userData['user'];
        // Mettre à jour les champs utilisateur
        final fieldsToUpdate = ['firstName', 'lastName', 'email', 'phone'];
        for (final field in fieldsToUpdate) {
          if (userInfo[field] != null) {
            updatedUserData[field] = userInfo[field];
          }
        }
      }
      
      // 1. Gérer la mise à jour du media/profileImage
      // L'API peut retourner 'media' ou 'profileImage'
      if (userData['media'] != null) {
        updatedUserData['media'] = userData['media'];
        print('✅ Media mis à jour depuis state.data: ${userData['media']}');
      } else if (userData['profileImage'] != null) {
        updatedUserData['media'] = userData['profileImage'];
        print('✅ ProfileImage mis à jour depuis state.data: ${userData['profileImage']}');
      } else if (state.data!['media'] != null) {
        updatedUserData['media'] = state.data!['media'];
        print('✅ Media mis à jour depuis state.data (niveau racine): ${state.data!['media']}');
      } else if (state.data!['profileImage'] != null) {
        updatedUserData['media'] = state.data!['profileImage'];
        print('✅ ProfileImage mis à jour depuis state.data (niveau racine): ${state.data!['profileImage']}');
      }
      
      // 2. Gérer les autres champs de l'utilisateur 
      final fieldsToUpdate = ['firstName', 'lastName', 'email', 'phone'];
      
      // Mettre à jour uniquement les champs qui existent dans la réponse
      for (final field in fieldsToUpdate) {
        if (userData[field] != null) {
          updatedUserData[field] = userData[field];
        }
      }
    }
    
    // print('📤 Mise à jour des données utilisateur: $updatedUserData');
    
    // Mettre à jour avec les données complètes de l'utilisateur et le token original
    authCubit.updateUser(updatedUserData, authState.token!);
    
    // Forcer la mise à jour de l'UI
    if (mounted) {
      setState(() {
        _selectedImage = null; // Réinitialiser l'image sélectionnée
      });
    }
  }

  @override
  void dispose() {
    // Annuler la subscription pour éviter les memory leaks
    _authSubscription?.cancel();
    _tabController?.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _newPhoneController.dispose();
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _loadUserFinancialData(String userId, String token) async {
    // Get income summary data from API
    _profileCubit.getIncomeSummary(
      token: token,
    );

    // Keep the balance call for backward compatibility
    _profileCubit.getUserBalance(
      userId: userId,
      token: token,
    );
  }

  // Fonction pour prévisualiser une image
  void _previewImage(dynamic image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Aperçu de l\'image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: image is File
                          ? Image.file(
                              image,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : Image.network(
                              image,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Fermer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Enregistrer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          try {
                            // Use share_plus to share/save the image
                            final result = await Share.shareXFiles(
                              [XFile(image is File ? image.path : '')],
                              text: 'Mon image de profil',
                            );

                            if (result.status == ShareResultStatus.success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Image partagée avec succès'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors du partage: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                      ),
                      const Text(
                        'Zoom: pincer pour zoomer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
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

  // Widget pour afficher une option de source d'image
  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              size: 32,
              color: AppColors.buttonColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour uploader l'image au serveur
  Future<void> _uploadImageToServer(File imageFile) async {
    // print('📤 [PROFILE PHOTO] _uploadImageToServer() appelée');
    // print('📤 [PROFILE PHOTO] Chemin du fichier: ${imageFile.path}');
    // print('📤 [PROFILE PHOTO] Fichier existe: ${await imageFile.exists()}');
    // if (await imageFile.exists()) {
    //   print('📤 [PROFILE PHOTO] Taille du fichier: ${await imageFile.length()} bytes');
    // }
    
    try {
      // Récupérer le token de l'utilisateur connecté
      // print('📤 [PROFILE PHOTO] Récupération de l\'état d\'authentification...');
      final authState = context.read<AuthCubit>().state;
      // print('📤 [PROFILE PHOTO] Type d\'état: ${authState.runtimeType}');
      
      if (authState is! AuthSuccess || authState.token == null) {
        // print('❌ [PROFILE PHOTO] Erreur: Utilisateur non connecté ou token manquant');
        // print('❌ [PROFILE PHOTO] authState is AuthSuccess: ${authState is AuthSuccess}');
        // print('❌ [PROFILE PHOTO] token != null: ${authState is AuthSuccess ? (authState as AuthSuccess).token != null : "N/A"}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur: Utilisateur non connecté'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // print('📤 [PROFILE PHOTO] Token récupéré: ${authState.token!.substring(0, 20)}...');
      // print('📤 [PROFILE PHOTO] Début de l\'upload via ProfileCubit...');
      
      // Utiliser ProfileCubit pour uploader l'image (utilise le bon endpoint)
      await _profileCubit.uploadProfileImage(
        token: authState.token!,
        imageFile: imageFile,
      );
      
      // print('✅ [PROFILE PHOTO] uploadProfileImage() appelée, attente de la réponse...');
      // print('✅ [PROFILE PHOTO] Attente de 500ms pour que le BlocListener traite la réponse...');
      // Le BlocListener va gérer la mise à jour de l'utilisateur
      // On attend un peu pour que le BlocListener traite la réponse
      await Future.delayed(const Duration(milliseconds: 500));
      
      // print('✅ [PROFILE PHOTO] Rechargement des données utilisateur...');
      // Recharger les données utilisateur après l'upload pour s'assurer que tout est à jour
      if (mounted) {
        _fetchUserMedia();
        // print('✅ [PROFILE PHOTO] _fetchUserMedia() appelée');
      } else {
        // print('⚠️ [PROFILE PHOTO] Widget non monté, impossible de recharger les données');
      }
      
    } catch (e, stackTrace) {
      // print('❌ [PROFILE PHOTO] Erreur lors de l\'upload: $e');
      // print('❌ [PROFILE PHOTO] Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    // print('🖼️ [PROFILE PHOTO] _showImageSourceDialog() appelée');
    // print('🖼️ [PROFILE PHOTO] Affichage du modal bottom sheet');
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
                // print('🖼️ [PROFILE PHOTO] Option "Galerie" sélectionnée');
                Navigator.pop(context);
                // print('🖼️ [PROFILE PHOTO] Ouverture du sélecteur d\'image (galerie)...');
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 800,
                );
                // print('🖼️ [PROFILE PHOTO] Résultat du picker: ${image != null ? "Image sélectionnée: ${image.path}" : "Aucune image sélectionnée"}');
                if (image != null && context.mounted) {
                  // print('🖼️ [PROFILE PHOTO] Image sélectionnée, chemin: ${image.path}');
                  // print('🖼️ [PROFILE PHOTO] Mise à jour de _selectedImage');
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                  // print('🖼️ [PROFILE PHOTO] _selectedImage mis à jour: ${_selectedImage?.path}');
                  // Uploader l'image au serveur
                  if (mounted) {
                    // print('🖼️ [PROFILE PHOTO] Appel de _uploadImageToServer() avec le fichier: ${File(image.path).path}');
                    await _uploadImageToServer(File(image.path));
                  } else {
                    // print('⚠️ [PROFILE PHOTO] Widget non monté, impossible d\'uploader');
                  }
                } else {
                  // print('⚠️ [PROFILE PHOTO] Aucune image sélectionnée ou contexte non monté');
                }
              },
              child: const Column(
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
                // print('🖼️ [PROFILE PHOTO] Option "Caméra" sélectionnée');
                Navigator.pop(context);
                // print('🖼️ [PROFILE PHOTO] Ouverture de la caméra...');
                final XFile? photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 800,
                );
                // print('🖼️ [PROFILE PHOTO] Résultat de la caméra: ${photo != null ? "Photo prise: ${photo.path}" : "Aucune photo prise"}');
                if (photo != null && context.mounted) {
                  // print('🖼️ [PROFILE PHOTO] Photo prise, chemin: ${photo.path}');
                  // print('🖼️ [PROFILE PHOTO] Mise à jour de _selectedImage');
                  setState(() {
                    _selectedImage = File(photo.path);
                  });
                  // print('🖼️ [PROFILE PHOTO] _selectedImage mis à jour: ${_selectedImage?.path}');
                  // Uploader l'image au serveur
                  if (mounted) {
                    // print('🖼️ [PROFILE PHOTO] Appel de _uploadImageToServer() avec le fichier: ${File(photo.path).path}');
                    await _uploadImageToServer(File(photo.path));
                  } else {
                    // print('⚠️ [PROFILE PHOTO] Widget non monté, impossible d\'uploader');
                  }
                } else {
                  // print('⚠️ [PROFILE PHOTO] Aucune photo prise ou contexte non monté');
                }
              },
              child: const Column(
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
    return BlocProvider.value(
      value: _profileCubit,
      child: Scaffold(
        appBar: AppBarWithLogo(
          leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          title: 'Paramètres du compte',
          backgroundColor: AppColors.buttonColor,
          elevation: 0,
          useWhiteLogo: true,
        ),
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            // print('🔄 [PROFILE PHOTO] BlocListener: État reçu - ${state.runtimeType}');
            
            if (state is ProfileSuccess) {
              // print('✅ [PROFILE PHOTO] BlocListener: ProfileSuccess détecté');
              // print('✅ [PROFILE PHOTO] Message: ${state.message}');
              // print('✅ [PROFILE PHOTO] state.data: ${state.data}');
              // print('✅ [PROFILE PHOTO] state.data type: ${state.data?.runtimeType}');
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              
              // Traiter toutes les mises à jour de profil (image et champs de formulaire)
              // print('✅ [PROFILE PHOTO] Appel de _handleProfileUpdate()...');
              _handleProfileUpdate(state);
              // print('✅ [PROFILE PHOTO] _handleProfileUpdate() terminé');
            } else if (state is ProfileError) {
              // print('❌ [PROFILE PHOTO] BlocListener: ProfileError détecté');
              // print('❌ [PROFILE PHOTO] Message d\'erreur: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.error,
                ),
              );
            } else if (state is BalanceLoaded) {
              setState(() {
                _balanceData = state.balanceData;
              });
            } else if (state is IncomeSummaryLoaded) {
              setState(() {
                _incomeSummaryData = state.incomeSummaryData;
              });
            } else {
              // print('ℹ️ [PROFILE PHOTO] BlocListener: Autre état - ${state.runtimeType}');
            }
          },
          builder: (context, state) {
            return BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is AuthSuccess && authState.user != null) {
                  return Column(
                    children: [
                      _buildProfileHeader(authState.user!),
                      // Show TabBar only for proprietaire role
                      if (authState.user!['role'] == 'proprietaire' && _tabController != null) ...[
                        TabBar(
                          controller: _tabController!,
                          labelColor: AppColors.buttonColor,
                          indicatorColor: AppColors.buttonColor,
                          tabs: const [
                            Tab(text: 'Profil', icon: Icon(Icons.person)),
                            Tab(
                                text: 'Mes transactions',
                                icon: Icon(Icons.account_balance_wallet)),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController!,
                            children: [
                              _buildProfileTab(authState.user!),
                              _buildBalanceTab(authState.user!),
                            ],
                          ),
                        ),
                      ] else 
                        // For non-proprietaire users, show profile section directly
                        Expanded(
                          child: _buildProfileTab(authState.user!),
                        ),
                    ],
                  );
                } else {
                  return const Center(
                      child:
                          Text('Connectez-vous pour accéder à vos paramètres'));
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    String profileImage = user['media'] ?? '';
    String fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
    bool isProprietaire = user['role'] == 'proprietaire';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.buttonColor,
            AppColors.buttonColor.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.buttonColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 52,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade100,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!) as ImageProvider
                          : (profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null),
                      child: _selectedImage == null && profileImage.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.buttonColor.withOpacity(0.5),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // print('🖼️ [PROFILE PHOTO] Clic sur le bouton de modification de photo');
                  // print('🖼️ [PROFILE PHOTO] Appel de _showImageSourceDialog()');
                  _showImageSourceDialog();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.buttonColor, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.edit,
                    color: AppColors.buttonColor,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          if (isProprietaire) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: Colors.white.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  user['email'] ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileTab(Map<String, dynamic> user) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildOptionsMenuBlock(user),
      ),
    );
  }

  Widget _buildBalanceTab(Map<String, dynamic> user) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is IncomeSummaryLoaded ||
            state is BalanceLoaded ||
            _balanceData != null ||
            _incomeSummaryData != null) {
          // Use income summary data if available
          if (state is IncomeSummaryLoaded) {
            _incomeSummaryData = state.incomeSummaryData;
          }

          // Fallback to balance data
          if (state is BalanceLoaded) {
            _balanceData = state.balanceData;
          }

          // Get values from income summary data if available
          double balanceUSD = 0.0;
          double balanceCDF = 0.0;
          double pendingIncome = 0.0;
          double pendingExpenses = 0.0;
          int transactionCount = 0;

          if (_incomeSummaryData != null &&
              _incomeSummaryData!['success'] == true) {
            final data = _incomeSummaryData!['data'];
            balanceUSD = (data['totalUSD'] ?? 0.0).toDouble();
            balanceCDF = (data['totalCDF'] ?? 0.0).toDouble();

            transactionCount = data['transactionCount'] ?? 0;

            // For now, we'll equally split the total as pending income/expenses
            // since the API doesn't provide this breakdown
            pendingIncome = balanceUSD * 0.7; // 70% as example income
            pendingExpenses = balanceUSD * 0.3; // 30% as example expenses

            // If USD is 0, use CDF for the percentages
            if (balanceUSD == 0.0) {
              pendingIncome = balanceCDF * 0.7;
              pendingExpenses = balanceCDF * 0.3;
            }
          } else if (_balanceData != null) {
            // Fallback to old balance data
            balanceUSD = _balanceData?['balance'] ?? 0.0;
            pendingIncome = _balanceData?['pendingIncome'] ?? 0.0;
            pendingExpenses = _balanceData?['pendingExpenses'] ?? 0.0;
          }

          // Calculer les pourcentages pour les graphiques
          final totalTransactions = pendingIncome + pendingExpenses;
          final incomePercentage = totalTransactions > 0
              ? (pendingIncome / totalTransactions) * 100
              : 0.0;
          final expensesPercentage = totalTransactions > 0
              ? (pendingExpenses / totalTransactions) * 100
              : 0.0;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte de solde principale avec design amélioré
                  Card(
                    elevation: 8,
                    shadowColor: AppColors.buttonColor.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.buttonColor,
                            AppColors.buttonColor.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.buttonColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Solde disponible',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 28,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'USD ${balanceUSD.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'CDF ${balanceCDF.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                     
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // const Text(
                                  //   'Propriétaire',
                                  //   style: TextStyle(
                                  //     color: Colors.white70,
                                  //     fontSize: 14,
                                  //   ),
                                  // ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${user['firstName']} ${user['lastName']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.receipt_long,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$transactionCount transactions',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Résumé de transaction avec des montants mis en évidence
                  // const Text(
                  //   'Résumé des transactions',
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //   ),
                  // ),
                  // const SizedBox(height: 16),

                  // Cartes des montants d'entrée et de sortie

                  const SizedBox(height: 24),

                  // Résumé détaillé des montants
                  // Card(
                  //   elevation: 3,
                  //   shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(12)),
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(16.0),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         const Text(
                  //           'Détail des montants',
                  //           style: TextStyle(
                  //             fontWeight: FontWeight.bold,
                  //             fontSize: 16,
                  //           ),
                  //         ),
                  //         const SizedBox(height: 16),
                  //         _buildFinancialSummaryItem(
                  //           title: 'Revenus en attente',
                  //           amount: pendingIncome,
                  //           currency: 'USD',
                  //           icon: Icons.arrow_downward,
                  //           iconColor: Colors.green,
                  //         ),
                  //         const Divider(),
                  //         _buildFinancialSummaryItem(
                  //           title: 'Dépenses en attente',
                  //           amount: pendingExpenses,
                  //           currency: 'USD',
                  //           icon: Icons.arrow_upward,
                  //           iconColor: Colors.red,
                  //         ),
                  //         const Divider(),
                  //         _buildFinancialSummaryItem(
                  //           title: 'Solde actuel',
                  //           amount: balanceUSD,
                  //           currency: 'USD',
                  //           icon: Icons.account_balance_wallet,
                  //           iconColor: AppColors.buttonColor,
                  //           isBold: true,
                  //         ),
                  //         const Divider(),
                  //         _buildFinancialSummaryItem(
                  //           title: 'Solde actuel',
                  //           amount: balanceCDF,
                  //           currency: 'CDF',
                  //           icon: Icons.account_balance_wallet,
                  //           iconColor: AppColors.buttonColor,
                  //           isBold: true,
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),

                  const SizedBox(height: 24),

                  // Bouton d'actualisation
                  ElevatedButton(
                    onPressed: () {
                      // Refresh balance data
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthSuccess && authState.user != null) {
                        _loadUserFinancialData(
                            authState.user!['id'], authState.token!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: AppColors.buttonColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Actualiser les données financières',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Impossible de charger les données financières',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authState = context.read<AuthCubit>().state;
                    if (authState is AuthSuccess && authState.user != null) {
                      _loadUserFinancialData(
                          authState.user!['id'], authState.token!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildFinancialSummaryItem({
    required String title,
    required double amount,
    required String currency,
    required IconData icon,
    required Color iconColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            '$currency ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: isBold ? AppColors.buttonColor : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Supprime le compte et redirige vers LoginScreen
  Future<void> _deleteAccount() async {
    try {
      print('🗑️ Suppression du compte en cours...');
      
      // Récupérer les données utilisateur actuelles
      final authState = context.read<AuthCubit>().state;
      Map<String, dynamic> user = {};
      
      if (authState is AuthSuccess && authState.user != null) {
        user = authState.user!;
      }
      
      // Effacer toutes les données de session D'ABORD
      context.read<AuthCubit>().logout();
      
      // PUIS enregistrer dans SharedPreferences la marque de suppression de compte
      final prefs = await SharedPreferences.getInstance();
      final removeAccountData = {
        'phone': user['phone'] ?? '',
        'isRemove': true,
      };
      
      await prefs.setString('removeAccount', jsonEncode(removeAccountData));
      print('✅ removeAccount enregistré: $removeAccountData');
      
      // Afficher un message de confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compte supprimé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Rediriger vers LoginScreen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
      
      print('✅ Redirection vers LoginScreen effectuée');
    } catch (e) {
      print('❌ Erreur lors de la suppression du compte: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Construit le bloc de menu des options avec design moderne
  Widget _buildOptionsMenuBlock(Map<String, dynamic> user) {
    final isVendeur = user['role'] == 'vendeur';
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bannière de fermeture pour les marchands
          // if (isVendeur) const MerchantClosedBanner(),
          
          // Sections marchand
          if (isVendeur) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                    child: const Text(
                      'Gestion boutique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  BlocBuilder<ProductCubit, ProductState>(
                    builder: (context, productState) {
                      // Mettre à jour le compteur si les produits sont chargés
                      if (productState is ProductLoaded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _allProductsCount != productState.products.length) {
                            if (mounted) {
                              setState(() {
                                _allProductsCount = productState.products.length;
                              });
                            }
                          }
                        });
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: MerchantSectionCard(
                          title: 'Tous les produits',
                          subtitle: 'Voir et gérer tous vos produits',
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppColors.primary,
                          count: _isLoadingCounts ? null : _allProductsCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VoirPlusProduitsScreen(),
                              ),
                            ).then((_) {
                              // Rafraîchir les compteurs après retour
                              _loadMerchantCounts();
                            });
                          },
                        ),
                      );
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: PromotionService().getPromotions(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!['success'] == true) {
                        final promotions = snapshot.data!['promotions'] as List<Promotion>;
                        final activePromos = promotions.where((p) => p.isActive).length;
                        if (mounted && _promoProductsCount != activePromos) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                _promoProductsCount = activePromos;
                              });
                            }
                          });
                        }
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: MerchantSectionCard(
                          title: 'Produits en promotions',
                          subtitle: 'Gérer vos produits en promotion',
                          icon: Icons.local_offer_outlined,
                          iconColor: Colors.red,
                          count: _isLoadingCounts ? null : _promoProductsCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MerchantPromoProductsScreen(),
                              ),
                            ).then((_) {
                              // Rafraîchir les compteurs après retour
                              _loadMerchantCounts();
                            });
                          },
                        ),
                      );
                    },
                  ),
                  MerchantSectionCard(
                    title: 'Configurer heures de service',
                    subtitle: 'Définir vos heures d\'ouverture',
                    icon: Icons.access_time,
                    iconColor: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MerchantServiceHoursScreen(),
                        ),
                      );
                    },
                  ),
                  MerchantSectionCard(
                    title: 'Moyens de paiement',
                    subtitle: 'Configurer vos moyens de paiement acceptés',
                    icon: Icons.payment,
                    iconColor: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PaymentMethodsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
          
          // Options de profil
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modifier informations personnelles
                MerchantSectionCard(
                  title: 'Modifier informations personnelles',
                  subtitle: 'Mettre à jour vos données personnelles',
                  icon: Icons.edit_outlined,
                  iconColor: AppColors.primary,
                  onTap: () {
                    _showUpdateProfileDialog();
                  },
                ),
                // Modifier numéro de téléphone
                MerchantSectionCard(
                  title: 'Modifier numéro de téléphone',
                  subtitle: 'Changer votre numéro de téléphone',
                  icon: Icons.phone_outlined,
                  iconColor: AppColors.primary,
                  onTap: () {
                    _showUpdatePhoneDialog();
                  },
                ),
                // Modifier mot de passe
                MerchantSectionCard(
                  title: 'Modifier mot de passe',
                  subtitle: 'Changer votre mot de passe de sécurité',
                  icon: Icons.lock_outline,
                  iconColor: AppColors.primary,
                  onTap: () {
                    _showChangePasswordDialog();
                  },
                ),
                // Modifier vos adresses
                MerchantSectionCard(
                  title: 'Modifier vos adresses',
                  subtitle: 'Gérer vos adresses de livraison',
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.primary,
                  onTap: () {
                    _showAddressesDialog();
                  },
                ),
                // Se déconnecter
                MerchantSectionCard(
                  title: 'Se déconnecter',
                  subtitle: 'Déconnexion de votre compte',
                  icon: Icons.logout,
                  iconColor: AppColors.error,
                  onTap: () {
                    _showLogoutConfirmation();
                  },
                ),
                // Supprimer compte
                MerchantSectionCard(
                  title: 'Supprimer compte',
                  subtitle: 'Supprimer définitivement votre compte',
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  onTap: () {
                    _showDeleteAccountConfirmation();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche le dialogue de mise à jour du profil avec formulaire complet
  void _showUpdateProfileDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => BlocProvider.value(
        value: _profileCubit,
        child: StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Modifier informations personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Champ Prénom
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'Prénom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(Icons.person, color: AppColors.buttonColor),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre prénom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Champ Nom
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Nom',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(Icons.person, color: AppColors.buttonColor),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre nom';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    // Bouton Mettre à jour le profil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            _updateProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 4,
                          shadowColor: AppColors.buttonColor.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: BlocBuilder<ProfileCubit, ProfileState>(
                          builder: (context, state) {
                            if (state is ProfileLoading) {
                              return const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              );
                            }
                            return const Text(
                              'Mettre à jour le profil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche le dialogue de mise à jour du numéro de téléphone
  void _showUpdatePhoneDialog() {
    _newPhoneController.clear();
    bool _isLoading = false;
    final FocusNode phoneFocusNode = FocusNode();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    // Capturer le contexte parent pour la navigation
    final parentContext = context;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setState) {
          return AnimatedPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Modifier numéro de téléphone',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            phoneFocusNode.unfocus();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Description
                    Text(
                      'Entrez votre nouveau numéro de téléphone. Un code de vérification sera envoyé à ce numéro.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Champ Nouveau numéro
                    TextFormField(
                      controller: _newPhoneController,
                      focusNode: phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      autofocus: false,
                      decoration: InputDecoration(
                        labelText: 'Nouveau numéro de téléphone',
                        hintText: '+243819493099',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: Icon(Icons.phone, color: AppColors.buttonColor),
                      ),
                      onTap: () {
                        // S'assurer que le focus est bien géré
                        Future.delayed(const Duration(milliseconds: 100), () {
                          phoneFocusNode.requestFocus();
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de téléphone';
                        }
                        if (!value.startsWith('+')) {
                          return 'Le numéro doit commencer par +';
                        }
                        if (value.length < 10) {
                          return 'Numéro de téléphone invalide';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 28),
                  
                  // Bouton Continuer
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        // Fermer le clavier avant de valider
                        phoneFocusNode.unfocus();
                        
                        // Attendre un peu pour que le clavier se ferme
                        await Future.delayed(const Duration(milliseconds: 100));
                        
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                          });
                          
                          try {
                            final token = await StorageService().getToken();
                            if (token == null) {
                              throw Exception('Token d\'authentification manquant');
                            }
                            
                            final profileService = ProfileService();
                            final result = await profileService.updatePhone(
                              token: token,
                              newPhone: _newPhoneController.text.trim(),
                            );
                            
                            // Vérifier que le code de réponse est 200 (succès)
                            if (result['success'] == true) {
                              // Fermer le dialogue d'entrée du numéro
                              Navigator.pop(modalContext);
                              
                              // Attendre que le modal se ferme complètement
                              await Future.delayed(const Duration(milliseconds: 300));
                              
                              // Afficher le message de succès avec le contexte parent
                              if (mounted) {
                                ScaffoldMessenger.of(parentContext).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message'] ?? 'Code OTP envoyé avec succès au nouveau numéro'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                              
                              // Attendre un peu pour que le message s'affiche
                              await Future.delayed(const Duration(milliseconds: 500));
                              
                              // Rediriger vers la page de vérification OTP (processus 2)
                              // Utiliser le contexte de l'écran parent, pas celui du modal
                              if (mounted) {
                                final otpResult = await Navigator.of(parentContext).push(
                                  MaterialPageRoute(
                                    builder: (context) => PhoneOTPVerificationScreen(
                                      newPhone: _newPhoneController.text.trim(),
                                    ),
                                  ),
                                );
                                
                                // Si la vérification OTP a réussi (processus 2 terminé), recharger les données utilisateur
                                if (otpResult == true && this.mounted) {
                                  _loadUserData();
                                }
                              }
                            }
                          } catch (e) {
                            setState(() {
                              _isLoading = false;
                            });
                            
                            // Extraire le message d'erreur
                            String errorMessage = e.toString();
                            if (errorMessage.contains('Exception: ')) {
                              errorMessage = errorMessage.replaceAll('Exception: ', '');
                            }
                            
                            if (mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(errorMessage),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Continuer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool _isLoading = false;
    // Capturer le contexte parent pour afficher les messages
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Modifier mot de passe',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: oldPasswordController,
                  obscureText: obscureOldPassword,
                  decoration: InputDecoration(
                    labelText: 'Ancien mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.buttonColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureOldPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureOldPassword = !obscureOldPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.lock, color: AppColors.buttonColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Champ de confirmation (validation côté client uniquement)
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: Icon(Icons.lock, color: AppColors.buttonColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      // Validation
                      if (oldPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer votre ancien mot de passe'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      if (newPasswordController.text.isEmpty) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez entrer un nouveau mot de passe'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Le nouveau mot de passe doit contenir au moins 6 caractères'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      // Vérifier que les deux mots de passe correspondent
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(
                            content: Text('Les deux mots de passe ne correspondent pas'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }
                      
                      // Afficher un indicateur de chargement
                      setState(() {
                        _isLoading = true;
                      });
                      
                      try {
                        final token = await StorageService().getToken();
                        if (token == null) {
                          throw Exception('Token d\'authentification manquant');
                        }
                        
                        final profileService = ProfileService();
                        final result = await profileService.changePassword(
                          token: token,
                          oldPassword: oldPasswordController.text,
                          newPassword: newPasswordController.text,
                        );
                        
                        if (result['success'] == true) {
                          // Fermer le dialogue
                          Navigator.pop(modalContext);
                          
                          // Afficher le message de succès
                          if (mounted) {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Mot de passe modifié avec succès'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setState(() {
                          _isLoading = false;
                        });
                        
                        // Extraire le message d'erreur
                        String errorMessage = e.toString();
                        if (errorMessage.contains('Exception: ')) {
                          errorMessage = errorMessage.replaceAll('Exception: ', '');
                        }
                        
                        if (mounted) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text(errorMessage),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                      shadowColor: AppColors.buttonColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Modifier le mot de passe',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Affiche le dialogue de gestion des adresses
  void _showAddressesDialog() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return;
    }
    final userId = authState.user!['id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Modifier vos adresses',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Bouton pour ajouter une nouvelle adresse
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showAddAddressDialog();
                },
                icon: const Icon(Icons.add_location_alt, color: Colors.white),
                label: const Text(
                  'Ajouter une nouvelle adresse',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Vos adresses enregistrées',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('delivery_addresses')
                    .where('userId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    // Gérer l'erreur d'index manquant de manière gracieuse
                    final error = snapshot.error.toString();
                    if (error.contains('index') || error.contains('FAILED_PRECONDITION')) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 48,
                                color: Colors.orange.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Index Firestore requis',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Veuillez créer l\'index dans la console Firebase',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Text('Erreur: ${snapshot.error}'),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune adresse enregistrée',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Trier côté client par timestamp décroissant
                  final addresses = snapshot.data!.docs.toList()
                    ..sort((a, b) {
                      final aTimestamp = a.data() as Map<String, dynamic>;
                      final bTimestamp = b.data() as Map<String, dynamic>;
                      final aTime = aTimestamp['timestamp'] as Timestamp?;
                      final bTime = bTimestamp['timestamp'] as Timestamp?;
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime); // Décroissant
                    });

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: addresses.length,
                    itemBuilder: (context, index) {
                      final addressDoc = addresses[index];
                      final address = addressDoc.data() as Map<String, dynamic>;
                      final addressId = addressDoc.id;

                      return _buildAddressCard(address, addressId);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une carte d'adresse cliquable
  Widget _buildAddressCard(Map<String, dynamic> address, String addressId) {
    final ville = address['ville'] ?? '';
    final commune = address['commune'] ?? '';
    final quartier = address['quartier'] ?? '';
    final avenue = address['avenue'] ?? '';
    final numero = address['numero'] ?? '';
    final pays = address['pays'] ?? 'RDC';
    
    final fullAddress = '$numero, $avenue, $quartier, $commune, $ville, $pays';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                _showEditAddressDialog(address, addressId);
              },
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.buttonColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: AppColors.buttonColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Appuyez pour modifier',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_outlined,
                      color: AppColors.buttonColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDeleteAddressConfirmation(addressId, fullAddress),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.red.shade400,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Supprimer cette adresse',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.red.shade400,
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

  /// Affiche le dialogue de modification d'une adresse
  void _showEditAddressDialog(Map<String, dynamic> address, String addressId) {
    final villeController = TextEditingController(text: address['ville'] ?? '');
    final communeController = TextEditingController(text: address['commune'] ?? '');
    final quartierController = TextEditingController(text: address['quartier'] ?? '');
    final avenueController = TextEditingController(text: address['avenue'] ?? '');
    final numeroController = TextEditingController(text: address['numero'] ?? '');
    final paysController = TextEditingController(text: address['pays'] ?? 'RDC');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Modifier l\'adresse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Champ Ville
                  TextFormField(
                    controller: villeController,
                    decoration: InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.location_city, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Commune
                  TextFormField(
                    controller: communeController,
                    decoration: InputDecoration(
                      labelText: 'Commune',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.apartment, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Quartier
                  TextFormField(
                    controller: quartierController,
                    decoration: InputDecoration(
                      labelText: 'Quartier',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.home, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Avenue
                  TextFormField(
                    controller: avenueController,
                    decoration: InputDecoration(
                      labelText: 'Avenue',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.streetview, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Numéro
                  TextFormField(
                    controller: numeroController,
                    decoration: InputDecoration(
                      labelText: 'Numéro',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.numbers, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Pays
                  TextFormField(
                    controller: paysController,
                    decoration: InputDecoration(
                      labelText: 'Pays',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.public, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Bouton Sauvegarder
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _updateAddress(
                          addressId,
                          villeController.text,
                          communeController.text,
                          quartierController.text,
                          avenueController.text,
                          numeroController.text,
                          paysController.text,
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: AppColors.buttonColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Sauvegarder les modifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Met à jour une adresse dans Firestore
  Future<void> _updateAddress(
    String addressId,
    String ville,
    String commune,
    String quartier,
    String avenue,
    String numero,
    String pays,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('delivery_addresses')
          .doc(addressId)
          .update({
        'ville': ville,
        'commune': commune,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numero,
        'pays': pays,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse modifiée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche la confirmation de suppression d'adresse
  void _showDeleteAddressConfirmation(String addressId, String address) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Supprimer l\'adresse'),
          content: Text('Êtes-vous sûr de vouloir supprimer cette adresse ?\n\n$address'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAddress(addressId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Supprime une adresse de Firestore
  Future<void> _deleteAddress(String addressId) async {
    try {
      await FirebaseFirestore.instance
          .collection('delivery_addresses')
          .doc(addressId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse supprimée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche le dialogue d'ajout d'une nouvelle adresse
  void _showAddAddressDialog() {
    final villeController = TextEditingController();
    final communeController = TextEditingController();
    final quartierController = TextEditingController();
    final avenueController = TextEditingController();
    final numeroController = TextEditingController();
    final paysController = TextEditingController(text: 'RDC');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ajouter une nouvelle adresse',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Champ Ville
                  TextFormField(
                    controller: villeController,
                    decoration: InputDecoration(
                      labelText: 'Ville',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.location_city, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Commune
                  TextFormField(
                    controller: communeController,
                    decoration: InputDecoration(
                      labelText: 'Commune',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.apartment, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Quartier
                  TextFormField(
                    controller: quartierController,
                    decoration: InputDecoration(
                      labelText: 'Quartier',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.home, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Avenue
                  TextFormField(
                    controller: avenueController,
                    decoration: InputDecoration(
                      labelText: 'Avenue',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.streetview, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Numéro
                  TextFormField(
                    controller: numeroController,
                    decoration: InputDecoration(
                      labelText: 'Numéro',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.numbers, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Champ Pays
                  TextFormField(
                    controller: paysController,
                    decoration: InputDecoration(
                      labelText: 'Pays',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.buttonColor, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      prefixIcon: Icon(Icons.public, color: AppColors.buttonColor),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // Bouton Sauvegarder
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (villeController.text.isEmpty ||
                            communeController.text.isEmpty ||
                            quartierController.text.isEmpty ||
                            avenueController.text.isEmpty ||
                            numeroController.text.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Veuillez remplir tous les champs obligatoires'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          return;
                        }
                        await _addAddress(
                          villeController.text,
                          communeController.text,
                          quartierController.text,
                          avenueController.text,
                          numeroController.text,
                          paysController.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: AppColors.buttonColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ajouter l\'adresse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Ajoute une nouvelle adresse dans Firestore
  Future<void> _addAddress(
    String ville,
    String commune,
    String quartier,
    String avenue,
    String numero,
    String pays,
  ) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthSuccess || authState.user == null) {
      return;
    }
    final userId = authState.user!['id']?.toString() ?? '';
    final userName =
        '${authState.user!['firstName'] ?? ''} ${authState.user!['lastName'] ?? ''}'.trim();

    try {
      await FirebaseFirestore.instance.collection('delivery_addresses').add({
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'userName': userName,
        'ville': ville,
        'commune': commune,
        'quartier': quartier,
        'avenue': avenue,
        'numero': numero,
        'pays': pays,
        'phone': authState.user!['phone'] ?? '',
        'latitude': 0.0,
        'longitude': 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Affiche la confirmation de déconnexion
  void _showLogoutConfirmation() {
    // Récupérer le rôle de l'utilisateur avant la déconnexion
    final authState = context.read<AuthCubit>().state;
    final isMerchant = authState is AuthSuccess && 
                      authState.user != null && 
                      authState.user!['role'] == 'vendeur';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Attendre que logout() termine complètement (reset de toutes les données)
                await context.read<AuthCubit>().logout();
                // Rediriger selon le rôle : marchand vers login, autres vers home
                if (context.mounted) {
                  if (isMerchant) {
                    // Pour les marchands uniquement, rediriger vers l'écran de login
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  } else {
                    // Pour les clients, rediriger vers l'écran de démarrage (AuthGate)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthGate()),
                      (route) => false,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  /// Affiche la confirmation de suppression de compte
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Suppression du compte'),
          content: const Text(
            'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    print('🔄 Début de la mise à jour du profil');
    
    if (_formKey.currentState!.validate()) {
      print('✅ Validation du formulaire réussie');
      
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        print('✅ Utilisateur authentifié trouvé');
        
        // Récupérer les valeurs des inputs
        final String firstName = _firstNameController.text.trim();
        final String lastName = _lastNameController.text.trim();
        final String email = authState.user!['email'] ?? ''; // Récupérer l'email depuis l'état actuel
        final String userId = authState.user!['id'].toString();
        final String token = authState.token!;
        
        print('📝 Données du formulaire:');
        print('  - userId: $userId');
        print('  - firstName: $firstName');
        print('  - lastName: $lastName');
        print('  - email: $email');
        print('  - token: ${token.substring(0, 20)}...');
        
        try {
          // Appeler la mise à jour du profil
          print('🔄 Appel de _profileCubit.updateProfile...');
          await _profileCubit.updateProfile(
            userId: userId,
            token: token,
            firstName: firstName,
            lastName: lastName,
            email: email,
          );
          print('✅ Mise à jour du profil terminée avec succès');
          
          // Recharger les données utilisateur pour refléter les changements
          _loadUserData();
          
          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          
        } catch (e) {
          print('❌ Erreur lors de la mise à jour du profil: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la mise à jour: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ Utilisateur non authentifié');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      print('❌ Validation du formulaire échouée');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
