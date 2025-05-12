import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:immo/screens/mise_location.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/listing_cubit.dart';
import '../cubit/listing_state.dart';
import '../cubits/apartment/apartment_cubit.dart';
import '../constants.dart';
import 'package:immo/widgets/custom_skeletons.dart';

class ApartmentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> apartment;

  const ApartmentDetailScreen({Key? key, required this.apartment})
      : super(key: key);

  @override
  State<ApartmentDetailScreen> createState() => _ApartmentDetailScreenState();
}

class _ApartmentDetailScreenState extends State<ApartmentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _minimumStayController = TextEditingController();
  DateTime _availableFrom = DateTime.now();
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  int _currentPage = 0;
  PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _minimumStayController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _showPublishDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publier l\'annonce'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Titre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un titre';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Prix par mois'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer un prix';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _minimumStayController,
                  decoration:
                      const InputDecoration(labelText: 'Séjour minimum (mois)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez entrer une durée minimum';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Veuillez entrer un nombre entier';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Disponible à partir de'),
                  subtitle: Text(_availableFrom.toString().split(' ')[0]),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _availableFrom,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _availableFrom = date;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.buttonColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
            onPressed: _isLoading ? null : _publishListing,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: SkeletonAvatar(
                      style: SkeletonAvatarStyle(
                        shape: BoxShape.circle,
                        width: 20,
                        height: 20,
                      ),
                    ),
                  )
                : const Text('Publier'),
          ),
        ],
      ),
    );
  }

  Future<void> _publishListing() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authState = context.read<AuthCubit>().state;
      if (authState is! AuthSuccess || authState.token == null) {
        throw Exception('Vous devez être connecté pour publier une annonce');
      }

      // Debug: afficher la structure des données de l'appartement
      print('Apartment data: ${widget.apartment}');

      // Vérifier les différentes possibilités pour l'ID
      final apartmentId = widget.apartment['id'] ??
          widget.apartment['_id'] ??
          widget.apartment['apartmentId'];

      if (apartmentId == null) {
        throw Exception(
            'ID de l\'appartement introuvable. Données reçues: ${widget.apartment}');
      }

      await context.read<ListingCubit>().createListing(
            apartmentId: apartmentId,
            title: _titleController.text,
            description: _descriptionController.text,
            price: double.parse(_priceController.text),
            availableFrom: _availableFrom,
            minimumStay: int.parse(_minimumStayController.text),
            token: authState.token!,
          );

      if (!mounted) return;

      Navigator.pop(context); // Ferme le dialog
      
      // Vérifier que nous sommes toujours sur l'écran ApartmentDetailScreen avant d'afficher le message
      if (mounted && ModalRoute.of(context)?.settings.name == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce publiée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      Navigator.pushNamed(context, AppRoutes.main);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'disponible':
        return 'Disponible';
      case 'occupe':
        return 'Occupé';
      case 'en_renovation':
        return 'En rénovation';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'disponible':
        return Colors.green;
      case 'occupe':
        return Colors.red;
      case 'en_renovation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFeatureChip(String text, {bool isFeature = false}) {
    return Chip(
      label: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      backgroundColor:
          isFeature ? AppColors.primary.withOpacity(0.2) : Colors.grey[200],
    );
  }

  Future<void> _showAddImagesDialog() async {
    List<dynamic> selectedImages = [];

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildImageDialog(context, selectedImages, setDialogState);
        },
      ),
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

    void _previewImage(dynamic image) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: image is File
                    ? FileImage(image)
                    : NetworkImage(image) as ImageProvider,
                fit: BoxFit.contain,
              ),
            ),
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
                  'Ajouter des images',
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
            // Titre et compteur d'images
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Images sélectionnées',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${selectedImages.length} ${selectedImages.length <= 1 ? 'image' : 'images'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Affichage des images sélectionnées
            selectedImages.isEmpty
                ? Container(
                    height: 150,
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
                            size: 40,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Aucune image sélectionnée',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.3,
                    ),
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: selectedImages[index] is File
                                    ? Image.file(
                                        selectedImages[index],
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.network(
                                        selectedImages[index],
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: () {
                                    _previewImage(selectedImages[index]);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.preview,
                                      size: 16,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 20),
            // Bouton pour ajouter une nouvelle image
            InkWell(
              onTap: () {
                _showImageSourceOptions();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Ajouter une image',
                      style: TextStyle(
                        color: AppColors.primary,
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
                      print('========== DÉBUT PRÉPARATION UPLOAD ==========');
                      // Filtrer pour ne garder que les fichiers (pas les URLs)
                      final List<File> fileImages = selectedImages
                          .where((image) => image is File)
                          .map((image) => image as File)
                          .toList();

                      print(
                          'Nombre de fichiers sélectionnés: ${fileImages.length}');
                      for (int i = 0; i < fileImages.length; i++) {
                        print('Fichier $i: ${fileImages[i].path}');
                        print(
                            'Fichier $i existe: ${fileImages[i].existsSync()}');
                        if (fileImages[i].existsSync()) {
                          print(
                              'Taille du fichier $i: ${fileImages[i].lengthSync()} bytes');
                        }
                      }

                      // Convert File objects to their paths
                      final List<String> imagePaths =
                          fileImages.map((file) => file.path).toList();

                      print('Chemins des images: $imagePaths');

                      // Fermer le dialogue d'images
                      Navigator.pop(context);

                      if (fileImages.isNotEmpty) {
                        // Get the token from the AuthCubit
                        final authState = context.read<AuthCubit>().state;
                        final token =
                            authState is AuthSuccess ? authState.token : null;

                        print('Token obtenu: ${token != null ? 'Oui' : 'Non'}');

                        if (token != null) {
                          print('Apartment ID: ${widget.apartment['id']}');

                          try {
                            // Afficher un message de chargement
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Téléchargement en cours...',
                                      style: TextStyle(color: Colors.white)),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 10),
                                ),
                              );
                              // Navigator.pushReplacementNamed(context, AppRoutes.main);
                              // Navigator.of(context).pop();
                              Navigator.of(context).pop(true);
                            }

                            // Upload des images
                            final apartmentCubit =
                                context.read<ApartmentCubit>();
                            await apartmentCubit.uploadApartmentImages(
                              apartmentId: widget.apartment['_id'],
                              imagePaths: imagePaths,
                              token: token,
                            );

                            // Attendre un court instant pour s'assurer que l'état est mis à jour
                            await Future.delayed(
                                const Duration(milliseconds: 500));

                            // Vérifier si le contexte est toujours valide et fermer le dialogue
                            if (context.mounted) {
                              final state = apartmentCubit.state;
                              if (state is ImagesUploaded) {
                                Navigator.of(context)
                                    .pop(); // Ferme le dialogue de progression
                                print(
                                    'Dialogue de progression fermé après succès');

                                // Afficher le message de succès
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Images téléchargées avec succès'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                Navigator.of(context).pop(true);
                              } else if (state is ApartmentError) {
                                Navigator.of(context)
                                    .pop(); // Ferme le dialogue de progression
                                print(
                                    'Dialogue de progression fermé après erreur');

                                // Afficher le message d'erreur
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: ${state.error}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            // Fermer le dialogue de progression en cas d'erreur
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              print(
                                  'Dialogue de progression fermé après erreur');
                            }

                            print('ERREUR lors de l\'upload: $e');

                            // Show error message
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } else {
                          // Show error message
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Erreur: Vous n\'êtes pas connecté'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        // If no new images, just show success message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selectedImages.length} ${selectedImages.length <= 1 ? 'image ajoutée' : 'images ajoutées'} avec succès!',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Navigator.of(context).pop(true);
                        }
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
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final features = widget.apartment['features'] as Map<String, dynamic>;
    final price = widget.apartment['price'] as Map<String, dynamic>;
    final List<dynamic> images = widget.apartment['images'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apartment['name'] ?? 'Détails de l\'appartement'),
      ),
      floatingActionButton: _getStatusText(widget.apartment['status']) == "loué"
          ? Container()
          : Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationPage(
                          apartmentId: widget.apartment['_id'],
                          amount: widget.apartment['price']['amount'],
                          currency: widget.apartment['price']['currency'],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.attach_money,
                    color: Colors.white,
                  ),
                  label: const Text('Mettre en location',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: AppColors.buttonColor,
                  heroTag: 'mettre en location',
                ),
                const SizedBox(height: 16),
                FloatingActionButton.extended(
                  onPressed: () => {

                    _priceController.text = widget.apartment['price']['amount'].toString(),
                    _showPublishDialog()

                  },
                  
                  icon: const Icon(
                    Icons.campaign,
                    color: Colors.white,
                  ),
                  label: const Text('Publier l\'annonce',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  backgroundColor: AppColors.buttonColor,
                  heroTag: 'publish',
                ),
              ],
            ),
      body: BlocListener<ListingCubit, ListingState>(
        listener: (context, state) {
          if (state is ListingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Annonce publiée avec succès')),
            );
          } else if (state is ListingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${state.message}')),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Carrousel d'images
              if (images.isNotEmpty)
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      // Images
                      PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              // Afficher l'image en plein écran
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                image: DecorationImage(
                                  image: NetworkImage(images[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Indicateurs de page
                      Positioned(
                        bottom: 10,
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
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey.withOpacity(0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bouton d'ajout d'images
                      Positioned(
                        top: 10,
                        right: 10,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            icon: const Icon(Icons.add_photo_alternate),
                            onPressed: () {
                              _showAddImagesDialog();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Si pas d'images, afficher un conteneur avec un bouton pour ajouter des images
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.add_photo_alternate,
                          size: 50,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: _showAddImagesDialog,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ajouter des images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${price['amount']} ${price['currency']}/${price['paymentFrequency']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: _getStatusText(widget.apartment['status']) ==
                                    "loué"
                                ? Colors.grey
                                : Colors.green,
                            borderRadius: BorderRadius.circular(50)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(_getStatusText(widget.apartment['status'])),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Caractéristiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('${widget.apartment['surface']} m²'),
                  _buildFeatureChip('${widget.apartment['rooms']} Pièces'),
                  _buildFeatureChip(
                      '${widget.apartment['bathrooms']} Salle(s) de bain'),
                  _buildFeatureChip('Étage ${widget.apartment['floor']}'),
                  if (features['water'] == true)
                    _buildFeatureChip('Eau incluse dans le loyer', isFeature: true),
                  if (features['electricity'] == true)
                    _buildFeatureChip('Électricité incluse dans le loyer', isFeature: true),
                  if (features['gas'] == true)
                    _buildFeatureChip('Gaz inclus dans le loyer', isFeature: true),
                  if (features['elevator'] == true)
                    _buildFeatureChip('Ascenseur', isFeature: true),
                  if (features['garden'] == true)
                    _buildFeatureChip('Jardin', isFeature: true),
                  if (features['terrace'] == true)
                    _buildFeatureChip('Terrasse', isFeature: true),
                  if (features['fitted_kitchen'] == true)
                    _buildFeatureChip('Cuisine équipée', isFeature: true),
                  if (features['pool'] == true)
                    _buildFeatureChip('Piscine', isFeature: true),

                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.apartment['description'],
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 200),
            ],
          ),
        ),
      ),
    );
  }
}
