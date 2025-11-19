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
import '../auth/login_screen.dart';

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

  // Profile image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // User balance data
  Map<String, dynamic>? _balanceData;
  Map<String, dynamic>? _incomeSummaryData;

  // ProfileCubit instance
  late final ProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    // Initialize TabController as null initially
    _tabController = null;

    // Initialize ProfileCubit
    _profileCubit = ProfileCubit(ProfileService());

    // Get current user data from AuthCubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
      
      // Écouter les changements de l'AuthCubit
      context.read<AuthCubit>().stream.listen((authState) {
        if (authState is AuthSuccess && authState.user != null) {
          print('🔄 AuthCubit a changé, rechargement des données utilisateur');
          _loadUserData();
        }
      });
    });
  }

  // Méthode pour charger les données utilisateur
  void _loadUserData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess && authState.user != null) {
      print('🔄 Chargement des données utilisateur: ${authState.user}');
      
      // Mettre à jour les contrôleurs avec les données actuelles
      _firstNameController.text = authState.user!['firstName'] ?? '';
      _lastNameController.text = authState.user!['lastName'] ?? '';
      _phoneController.text = authState.user!['phone'] ?? '';

      // Injecter l'AuthCubit dans le ProfileCubit
      _profileCubit.setAuthCubit(context.read<AuthCubit>());

      // Set the correct number of tabs based on user role
      final isProprietaire = authState.user!['role'] == 'proprietaire';
      
      // Only create TabController for proprietaire users
      if (isProprietaire) {
        _tabController = TabController(
          length: 2,
          vsync: this,
        );
        
        // Load user financial data only for proprietaire
        _loadUserFinancialData(authState.user!['id'], authState.token!);
      }
      
      // Forcer la mise à jour de l'interface utilisateur
      setState(() {});
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

  @override
  void dispose() {
    _tabController?.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
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
    try {
      // Récupérer le token de l'utilisateur connecté
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur: Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Afficher un indicateur de chargement
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload de l\'image en cours...'),
          backgroundColor: Colors.green,
        ),
      );

      // Préparer la requête multipart
      var headers = {
        'Authorization': 'Bearer ${authState.token}',
      };
      
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('http://24.144.87.127:3333/users/update-profil')
      );
      
      // Ajouter le fichier image
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path)
      );
      
      // Ajouter les headers
      request.headers.addAll(headers);

      // Envoyer la requête
      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('Upload réussi: $responseBody');
        _fetchUserMedia();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploadée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Mettre à jour l'interface si nécessaire
        setState(() {
          // L'image sera mise à jour via le ProfileCubit
        });
        
      } else {
        print('Erreur upload: ${response.reasonPhrase}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload: ${response.reasonPhrase}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'upload: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
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
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _selectedImage = File(image.path);
                  });
                  // Uploader l'image au serveur
                  await _uploadImageToServer(File(image.path));
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
                Navigator.pop(context);
                final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() {
                    _selectedImage = File(photo.path);
                  });
                  // Uploader l'image au serveur
                  await _uploadImageToServer(File(photo.path));
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
            if (state is ProfileSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.success,
                ),
              );
              
              // Traiter toutes les mises à jour de profil (image et champs de formulaire)
              final authCubit = context.read<AuthCubit>();
              final authState = authCubit.state;
              
              if (authState is AuthSuccess && authState.user != null && state.data != null) {
                // Préserver toutes les informations de l'utilisateur existant
                Map<String, dynamic> updatedUserData = Map<String, dynamic>.from(authState.user!);
                
                // Structure des données - format unifié
                // - Cas 1: { user: { firstName, lastName, etc. }, profileImage: "url" }
                // - Cas 2: { firstName, lastName, etc. }
                
                // 1. Gérer la mise à jour du profileImage
                if (state.data!['profileImage'] != null) {
                  updatedUserData['profileImage'] = state.data!['profileImage'];
                }
                
                // 2. Gérer les autres champs de l'utilisateur 
                // Récupérer le bon niveau de données selon la structure retournée
                Map<String, dynamic> userData = state.data!;
                if (state.data!['user'] != null) {
                  userData = state.data!['user'];
                }
                
                // Mise à jour des champs utilisateur spécifiques sans écraser les autres
                final fieldsToUpdate = ['firstName', 'lastName', 'email', 'phone', 'profileImage'];
                
                // Mettre à jour uniquement les champs qui existent dans la réponse
                for (final field in fieldsToUpdate) {
                  if (userData[field] != null) {
                    updatedUserData[field] = userData[field];
                  }
                }
                
                print('Mise à jour des données utilisateur: $updatedUserData'); // Debug print
                
                // Mettre à jour avec les données complètes de l'utilisateur et le token original
                authCubit.updateUser(updatedUserData, authState.token!);
              }
            } else if (state is ProfileError) {
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
                onTap: _showImageSourceDialog,
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
    return Container(
      width: double.infinity,
      height: double.infinity,
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
          _buildMenuItem(
            icon: Icons.edit_outlined,
            iconColor: AppColors.buttonColor,
            title: 'Modifier informations personnelles',
            onTap: () {
              // Ouvrir le formulaire de mise à jour du profil
              _showUpdateProfileDialog();
            },
            showDivider: true,
          ),
          // Modifier mot de passe
          _buildMenuItem(
            icon: Icons.lock_outline,
            iconColor: AppColors.buttonColor,
            title: 'Modifier mot de passe',
            onTap: () {
              _showChangePasswordDialog();
            },
            showDivider: true,
          ),
          // Modifier vos adresses
          _buildMenuItem(
            icon: Icons.location_on_outlined,
            iconColor: AppColors.buttonColor,
            title: 'Modifier vos adresses',
            onTap: () {
              _showAddressesDialog();
            },
            showDivider: true,
          ),
          // Se déconnecter
          _buildMenuItem(
            icon: Icons.logout,
            iconColor: AppColors.error,
            title: 'Se déconnecter',
            onTap: () {
              _showLogoutConfirmation();
            },
            showDivider: true,
          ),
          // Supprimer compte
          _buildMenuItem(
            icon: Icons.delete_outline,
            iconColor: Colors.red,
            title: 'Supprimer compte',
            onTap: () {
              _showDeleteAccountConfirmation();
            },
            showDivider: false,
          ),
          // Espace flexible pour occuper le reste de l'écran
          const Spacer(),
        ],
      ),
    );
  }

  /// Construit un item de menu avec icône et texte
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: iconColor.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: iconColor == Colors.red ? Colors.red.shade700 : Colors.grey.shade800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                ],
              ),
            ),
            if (showDivider)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 60,
                endIndent: 20,
                color: Colors.grey.shade200,
              ),
          ],
        ),
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
                    const SizedBox(height: 16),
                    // Champ Téléphone
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Téléphone',
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer votre numéro de téléphone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    // Bouton Mettre à jour le profil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
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

  /// Affiche le dialogue de modification du mot de passe
  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

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
                      onPressed: () => Navigator.pop(context),
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
                    onPressed: () {
                      // TODO: Implémenter la logique de changement de mot de passe
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité en cours de développement'),
                          backgroundColor: Colors.orange,
                        ),
                      );
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
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('delivery_addresses')
                    .where('userId', isEqualTo: userId)
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
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

                  final addresses = snapshot.data!.docs;

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
            const SizedBox(height: 16),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _showEditAddressDialog(address, addressId);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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

  /// Affiche la confirmation de déconnexion
  void _showLogoutConfirmation() {
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
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().logout();
                Navigator.of(context).pushReplacementNamed('/login');
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
        final String phone = _phoneController.text.trim();
        final String email = authState.user!['email'] ?? ''; // Récupérer l'email depuis l'état actuel
        final String userId = authState.user!['id'].toString();
        final String token = authState.token!;
        
        print('📝 Données du formulaire:');
        print('  - userId: $userId');
        print('  - firstName: $firstName');
        print('  - lastName: $lastName');
        print('  - email: $email');
        print('  - phone: $phone');
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
            phone: phone,
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
