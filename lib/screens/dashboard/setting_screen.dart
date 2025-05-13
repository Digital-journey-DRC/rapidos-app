import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants.dart';
import '../../cubit/auth_cubit.dart';
import '../../cubits/profile/profile_cubit.dart';
import '../../services/profile_service.dart';

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
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        _firstNameController.text = authState.user!['firstName'] ?? '';
        _lastNameController.text = authState.user!['lastName'] ?? '';
        _phoneController.text = authState.user!['phone'] ?? '';

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
      }
    });
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

  Future<void> _pickImage() async {
    // Utiliser une seule image à la fois
    List<dynamic> selectedImages = [];
    if (_selectedImage != null) {
      selectedImages.add(_selectedImage);
    }

    // Afficher le dialogue de gestion d'images
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return _buildImageDialog(context, selectedImages, setDialogState);
          },
        );
      },
    );
  }

  Widget _buildImageDialog(BuildContext context, List<dynamic> selectedImages,
      StateSetter setDialogState) {
    void _showImageSourceOptions() {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sélectionner une image',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    title: 'Galerie',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image =
                          await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() {
                          // Remplacer l'image existante
                          selectedImages.clear();
                          selectedImages.add(File(image.path));
                        });
                      }
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Caméra',
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? photo =
                          await _picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        setDialogState(() {
                          // Remplacer l'image existante
                          selectedImages.clear();
                          selectedImages.add(File(photo.path));
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Photo de profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Affichage de l'image sélectionnée
            selectedImages.isEmpty
                ? Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'Aucune image sélectionnée',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // L'image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: selectedImages.first is File
                              ? Image.file(
                                  selectedImages.first as File,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  selectedImages.first as String,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        // Bouton de suppression
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                selectedImages.clear();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Icon(
                                Icons.delete,
                                size: 24,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            const SizedBox(height: 20),
            // Bouton pour choisir une image
            InkWell(
              onTap: () {
                _showImageSourceOptions();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: AppColors.buttonColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.buttonColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        selectedImages.isEmpty
                            ? Icons.add_photo_alternate
                            : Icons.edit,
                        color: AppColors.buttonColor,
                        size: 24),
                    const SizedBox(width: 10),
                    Text(
                      selectedImages.isEmpty
                          ? 'Ajouter une photo'
                          : 'Changer la photo',
                      style: const TextStyle(
                        color: AppColors.buttonColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: () async {
                      if (selectedImages.isEmpty) {
                        Navigator.pop(context);
                        return;
                      }

                      // Utiliser l'image sélectionnée comme photo de profil
                      final File imageFile = selectedImages.first as File;

                      setState(() {
                        _selectedImage = imageFile;
                      });

                      // Fermer le dialogue
                      Navigator.pop(context);

                      // Uploader l'image de profil en utilisant le cubit
                      final authState = context.read<AuthCubit>().state;
                      if (authState is AuthSuccess && authState.user != null) {
                        _profileCubit.uploadProfileImage(
                          token: authState.token!,
                          imageFile: imageFile,
                        );
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, size: 18, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'Enregistrer',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && authState.user != null) {
        // Conserver les valeurs à mettre à jour pour confirmer qu'elles sont correctement sauvegardées
        final String firstName = _firstNameController.text;
        final String lastName = _lastNameController.text;
        final String phone = _phoneController.text;
        
        // Appeler la mise à jour du profil
        await _profileCubit.updateProfile(
          userId: authState.user!['id'],
          token: authState.token!,
          firstName: firstName,
          lastName: lastName,
          phone: phone,
        );
        
        // Mettre à jour directement l'UI avec les nouvelles valeurs en attendant la confirmation API
        setState(() {
          // Les données seront officiellement mises à jour via le listener du ProfileCubit
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _profileCubit,
      child: Scaffold(
        appBar: AppBar(
          leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: const Icon(Icons.arrow_back_ios, color: Colors.white)),
          title: const Text(
            'Paramètres du compte',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: AppColors.buttonColor,
          elevation: 0,
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
    String profileImage = user['profileImage'] ?? '';
    String fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}';
    bool isProprietaire = user['role'] == 'proprietaire';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.buttonColor,
            AppColors.buttonColor,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 55,
                backgroundColor: AppColors.white,
                child: CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.buttonColor,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _selectedImage != null
                        ? FileImage(_selectedImage!) as ImageProvider
                        : (profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null),
                    child: _selectedImage == null && profileImage.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.buttonColor,
                          )
                        : null,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.buttonColor, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.buttonColor,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          // Text(
          //   user['role'] ?? 'Utilisateur',
          //   style: const TextStyle(
          //     color: Colors.white70,
          //     fontSize: 16,
          //   ),
          // ),
          if (isProprietaire) ...[
            const SizedBox(height: 5),
            Text(
              user['email'] ?? '',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ] else
            const SizedBox(height: 5),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileTab(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre prénom';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Téléphone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre numéro de téléphone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: AppColors.error),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // Show confirmation dialog before logout
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
                            Navigator.of(context).pop(); // Close dialog
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
                            Navigator.of(context).pop(); // Close dialog
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
              },
            ),
          ],
        ),
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
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.buttonColor,
                            AppColors.buttonColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(15),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
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
}
