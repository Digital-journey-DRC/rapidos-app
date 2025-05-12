import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:immo/widgets/image_viewer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../constants.dart';
import '../cubit/auth_cubit.dart';
import '../cubits/building/building_cubit.dart';
import '../cubits/building/building_state.dart';
import '../cubits/apartment/apartment_cubit.dart';
// import '../cubits/apartment/apartment_state.dart';
import '../models/building.dart';
import '../screens/apartment_detail_screen.dart';
import 'package:immo/widgets/custom_skeletons.dart';

class BuildingDetailScreen extends StatefulWidget {
  final Building building;
  

  const BuildingDetailScreen({
    Key? key,
    required this.building,
  }) : super(key: key);

  @override
  State<BuildingDetailScreen> createState() => _BuildingDetailScreenState();
}

class _BuildingDetailScreenState extends State<BuildingDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controllers for apartment form
  final _numberController = TextEditingController();
  final _priceController = TextEditingController();
  final _surfaceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedType = 'studio';
  String _selectedStatus = 'disponible';
  int _selectedFloor = 0;
  int _rooms = 1;
  int _bathrooms = 1;
  String _selectedCurrency = 'USD';
  String _selectedPaymentFrequency = 'mois';
  bool _payTax = false;

  // Available options for form fields
  final List<String> _apartmentTypes = ['studio', 'f1', 'f2', 'f3', 'f4', 'f5'];
  final List<String> _apartmentStatuses = [
    'disponible',
    'occupe',
    'en_renovation'
  ];
  final List<String> _currencies = ['USD', 'CDF'];
  final List<String> _paymentFrequencies = ['mois', 'annee'];
  final List<String> _availableFeatures = [
    'eau incluse dans le loyer',
    'électricité incluse dans le loyer',
    'gaz inclus dans le loyer',
    'meuble',
    'climatisation',
    'balcon',
    'parking',
    'ascenseur',
    'internet',
    'cuisine équipée',
    'sécurité',
    'piscine',
    'jardin',
    'terrasse',
  ];

  List<String> _selectedFeatures = [];

  final ImagePicker _picker = ImagePicker();
  List<dynamic> selectedImages = [];
  bool isLoading = false;
  double uploadProgress = 0.0;
  
  // Pour le rafraîchissement
  int _refreshCounter = 0;
  late StreamSubscription<String> _imageUploadSubscription;

  @override
  void initState() {
    _surfaceController.text = "0";
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSuccess) {
      context.read<ApartmentCubit>().getApartmentsByBuilding(
            widget.building.id.toString(),
            authState.token!,
          );
    }
    
    // Écouter les notifications de téléchargement d'images
    _imageUploadSubscription = ApartmentCubit.imageUploadStream.listen((apartmentId) {
      print('🔄 Image upload notification reçue pour l\'appartement: $apartmentId');
      
      // Rafraîchir les données des appartements
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthSuccess && mounted) {
        print('🔄 Rafraîchissement des appartements après notification d\'upload');
        
        // Incrémenter le compteur pour forcer le rafraîchissement
        setState(() {
          _refreshCounter++;
        });
        
        // Rafraîchir les données
        context.read<ApartmentCubit>().getApartmentsByBuilding(
          widget.building.id.toString(),
          authState.token!,
        );
      }
    });
  }
  
  @override
  void dispose() {
    _imageUploadSubscription.cancel();
    _pageController.dispose();
    _numberController.dispose();
    _priceController.dispose();
    _surfaceController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  String _getStatusText(String status) {
    switch (status) {
      case 'disponible':
        return 'Disponible';
      case 'occupe':
        return 'Occupé';
      case 'en_construction':
        return 'En construction';
      default:
        return 'Inconnu';
    }
  }

  Widget _buildFeatureChip(String feature) {
    return Chip(
      label: Text(
        feature,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
        ),
      ),
      backgroundColor: Colors.grey[200],
    );
  }

  void _clearForm() {
    _numberController.clear();
    _priceController.clear();
    _surfaceController.clear();
    _descriptionController.clear();
    _selectedFeatures.clear();
    _selectedType = 'studio';
    _selectedStatus = 'disponible';
    setState(() {});
  }

  void _showAddApartmentDialog() {
    final _numberController = TextEditingController();
    final _amountController = TextEditingController();
    final _surfaceController = TextEditingController(text: '0');
    final _roomsController = TextEditingController(text: '1');
    final _bathroomsController = TextEditingController(text: '1');
    final _floorController = TextEditingController(text: '0');
    final _descriptionController = TextEditingController();
    String type = 'studio';
    String currency = 'CDF';
    String paymentFrequency = 'mensuel';
    String status = 'disponible';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Ajouter un appartement', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    "studio",
                    "f1",
                    "f2",
                    "f3",
                    "f4",
                    "f5",
                    "duplex",
                    "penthouse"
                  ].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => type = value!),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primary),
                    // color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeDescription(type),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _floorController,
                        decoration: const InputDecoration(
                          labelText: 'Étage',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _surfaceController,
                        decoration: const InputDecoration(
                          labelText: 'Surface (m²)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _roomsController,
                        decoration: const InputDecoration(
                          labelText: 'Chambres',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _bathroomsController,
                        decoration: const InputDecoration(
                          labelText: 'Salles de bain',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Prix',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: currency,
                        decoration: const InputDecoration(
                          labelText: 'Devise',
                          border: OutlineInputBorder(),
                        ),
                        items: ['CDF', 'USD'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => currency = value!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: paymentFrequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence de paiement',
                    border: OutlineInputBorder(),
                  ),
                  items: ['mensuel', 'annuel'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => paymentFrequency = value!),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text(
                    'Souhaitez-vous payer la taxe pour cet appartement ?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  value: _payTax,
                  activeColor: AppColors.primary,
                  onChanged: (bool? value) {
                    setState(() {
                      _payTax = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                MultiSelectDialogField<String>(
                  items: _availableFeatures
                      .map((feature) => MultiSelectItem<String>(
                          feature,
                          feature[0].toUpperCase() +
                              feature.substring(1).replaceAll('_', ' ')))
                      .toList(),
                  listType: MultiSelectListType.CHIP,
                  cancelText: const Text('Annuler'),
                  selectedItemsTextStyle: const TextStyle(color: Colors.white),
                  onConfirm: (values) {
                    setState(() {
                      _selectedFeatures = values;
                    });
                  },
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  buttonText: const Text('choisir les Caractéristiques'),
                  title: const Text('Caractéristiques'),
                  selectedColor: AppColors.primary,
                  chipDisplay: MultiSelectChipDisplay(
                    onTap: (value) {
                      setState(() {
                        _selectedFeatures.remove(value);
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final number = _numberController.text;
                final amountStr = _amountController.text;
                final surfaceStr = _surfaceController.text;
                final description = _descriptionController.text;
                final floorStr = _floorController.text;
                final roomsStr = _roomsController.text;
                final bathroomsStr = _bathroomsController.text;

                if (number.isEmpty ||
                    amountStr.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Certains champs requis sont manquants. Veuillez remplir le numéro et le montant.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 4),
                    ),
                  );
                  return;
                }

                final double? amount = double.tryParse(amountStr);
                final double surface = surfaceStr.isEmpty ? 0 : double.tryParse(surfaceStr) ?? 0;
                final int floor = int.tryParse(floorStr) ?? 0;
                final int rooms = int.tryParse(roomsStr) ?? 1;
                final int bathrooms = int.tryParse(bathroomsStr) ?? 1;

                if (amount == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Le prix doit être un nombre valide'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (amount == null || surface == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Le prix et la surface doivent être des nombres valides'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final authState = context.read<AuthCubit>().state;
                if (authState is! AuthSuccess) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Vous devez être connecté pour créer un appartement'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Convertir la liste des caractéristiques en objet
                final Map<String, bool> featuresMap = {
                  'water':
                      _selectedFeatures.contains('eau incluse dans le loyer'),
                  'electricity': _selectedFeatures
                      .contains('électricité incluse dans le loyer'),
                  'gas': _selectedFeatures.contains('gaz inclus dans le loyer'),
                  'furnished': _selectedFeatures.contains('meuble'),
                  'airConditioning':
                      _selectedFeatures.contains('climatisation'),
                  'balcony': _selectedFeatures.contains('balcon'),
                  'internet': _selectedFeatures.contains('internet'),
                  'parking': _selectedFeatures.contains('parking'),
                  'securitySystem': _selectedFeatures.contains('sécurité'),
                  'elevator': _selectedFeatures.contains('ascenseur'),
                  'garden': _selectedFeatures.contains('jardin'),
                  'terrace': _selectedFeatures.contains('terrasse'),
                  'fitted_kitchen':
                      _selectedFeatures.contains('cuisine équipée'),
                  'pool': _selectedFeatures.contains('piscine')
                };

                context.read<ApartmentCubit>().createApartment(
                      token: authState.token!,
                      buildingId: widget.building.id.toString(),
                      number: number,
                      taxe: _payTax,
                      type: type,
                      floor: floor,
                      surface: surface,
                      rooms: rooms,
                      bathrooms: bathrooms,
                      amount: amount,
                      currency: currency,
                      paymentFrequency: paymentFrequency,
                      description: description,
                      features: featuresMap,
                      status: status,
                    );
                Navigator.pop(dialogContext);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFeatureText(String feature) {
    switch (feature) {
      case 'meuble':
        return 'Meublé';
      case 'climatisation':
        return 'Climatisation';
      case 'balcon':
        return 'Balcon';
      case 'parking':
        return 'Parking';
      case 'ascenseur':
        return 'Ascenseur';
      case 'internet':
        return 'Internet';
      case 'cuisine_equipee':
        return 'Cuisine équipée';
      case 'chauffage':
        return 'Chauffage';
      case 'securite':
        return 'Sécurité';
      case 'piscine':
        return 'Piscine';
      case 'jardin':
        return 'Jardin';
      case 'terrasse':
        return 'Terrasse';
      default:
        return feature;
    }
  }

  String _getTypeDescription(String type) {
    switch (type.toLowerCase()) {
      case 'studio':
        return 'Une pièce unique servant à la fois de salon, chambre et cuisine. Surface moyenne : 20-35m²';
      case 'f1':
        return '1 pièce principale + cuisine séparée. Surface moyenne : 25-35m²';
      case 'f2':
        return '2 pièces : 1 chambre + salon + cuisine. Surface moyenne : 35-45m²';
      case 'f3':
        return '3 pièces : 2 chambres + salon + cuisine. Surface moyenne : 55-70m²';
      case 'f4':
        return '4 pièces : 3 chambres + salon + cuisine. Surface moyenne : 70-90m²';
      case 'f5':
        return '5 pièces : 4 chambres + salon + cuisine. Surface moyenne : 90-120m²';
      case 'duplex':
        return 'Appartement sur deux niveaux reliés par un escalier intérieur';
      case 'penthouse':
        return 'Appartement luxueux situé au dernier étage avec souvent une terrasse privative';
      default:
        return 'Sélectionnez un type pour voir sa description';
    }
  }

  void _showAddImagesDialog() {
    // Liste temporaire pour stocker les nouvelles images sélectionnées
    List<dynamic> selectedImages = [];
    final ImagePicker _picker = ImagePicker();

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
                                    child: SkeletonAvatar(
                                      style: SkeletonAvatarStyle(
                                        width: 100,
                                        height: 100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.close),
                          label: const Text('Fermer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
                color: AppColors.primary,
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

    // Fonction pour construire le dialogue d'images
    Widget _buildImageDialog(BuildContext context, List<dynamic> selectedImages,
        StateSetter setDialogState) {
      // Fonction pour afficher le menu de sélection d'image
      void _showImageSourceOptions() {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (BuildContext context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Choisir une source',
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
                            final XFile? image = await _picker.pickImage(
                                source: ImageSource.gallery);
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
                            final XFile? photo = await _picker.pickImage(
                                source: ImageSource.camera);
                            if (photo != null) {
                              setDialogState(() {
                                selectedImages.add(File(photo.path));
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
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
                      Icon(Icons.add_photo_alternate,
                          color: AppColors.primary, size: 24),
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
                        // Filter to get only File objects (not network images)
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

                          print(
                              'Token obtenu: ${token != null ? 'Oui' : 'Non'}');

                          if (token != null) {
                            print('Building ID: ${widget.building.id}');

                            try {
                              // Afficher un dialogue de progression
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Téléchargement en cours...',
                                        style: TextStyle(color: Colors.white)),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 10),
                                  ),
                                );
                                Navigator.pushReplacementNamed(
                                    context, AppRoutes.main);
                                // Navigator.of(context).pop();
                              }

                              // Upload the images using the BuildingCubit
                              final buildingCubit =
                                  context.read<BuildingCubit>();
                              await buildingCubit.uploadBuildingImages(
                                buildingId: widget.building.id!,
                                imagePaths: imagePaths,
                                token: token,
                                onSuccess: () async {
                                  // Rafraîchir la liste des bâtiments depuis le tableau de bord
                                  print('🔄 Callback de succès appelé après téléchargement des images');
                                },
                              );

                              // Attendre un court instant pour s'assurer que l'état est mis à jour
                              await Future.delayed(
                                  const Duration(milliseconds: 500));

                              // Vérifier si le contexte est toujours valide et fermer le dialogue
                              if (context.mounted) {
                                final state = buildingCubit.state;
                                if (state is BuildingLoaded) {
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
                                } else if (state is BuildingError) {
                                  Navigator.of(context)
                                      .pop(); // Ferme le dialogue de progression
                                  print(
                                      'Dialogue de progression fermé après erreur');

                                  // Afficher le message d'erreur
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Erreur: ${state.message}'),
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

    // Afficher le dialogue initial avec la liste vide
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

  Widget _buildApartmentCard(Map<String, dynamic> apartment) {
    final image =
        (apartment['images'] != null && apartment['images'].isNotEmpty)
            ? apartment['images'][0]
            : 'https://via.placeholder.com/150';
    return Card(
      color: Colors.white.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        leading: ImageViewerWidget(
          url: image,
          borderRadius: BorderRadius.circular(10),
          width: 70,
          height: 60,
          border: Border.all(color: Colors.transparent, width: 1),
        ),
        onTap: () async {
          final needsRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ApartmentDetailScreen(
                apartment: apartment,
              ),
            ),
          );
          
          // Si on reçoit true, cela signifie que des images ont été ajoutées et qu'un rafraîchissement est nécessaire
          if (needsRefresh == true) {
            final authState = context.read<AuthCubit>().state;
            if (authState is AuthSuccess) {
              // Rafraîchir la liste des appartements
              context.read<ApartmentCubit>().getApartmentsByBuilding(
                    widget.building.id.toString(),
                    authState.token!,
                  );
            }
          }
        },
        title: Text('${apartment['type']} - ${apartment['rooms']} chambres'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Surface: ${apartment['surface']} m²'),
            Text(
                'Prix: ${apartment['price']['amount']} ${apartment['price']['currency']}'),
            if (apartment['publisherName'] != null)
              Text(
                'Publié par: ${apartment['publisherName']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            if (apartment['views'] != null) Text('Vues: ${apartment['views']}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              apartment['listingStatus'] ?? apartment['status'] ?? 'disponible',
              style: TextStyle(
                color: _getStatusColor(apartment['listingStatus'] ??
                    apartment['status'] ??
                    'disponible'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.building.images?.isNotEmpty == true
        ? widget.building.images!
        : ['https://via.placeholder.com/400'];

    return BlocListener<ApartmentCubit, ApartmentState>(
      listener: (context, state) {
        if (state is ApartmentSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          final authState = context.read<AuthCubit>().state;
          if (authState is AuthSuccess) {
            context.read<ApartmentCubit>().getApartmentsByBuilding(
                  widget.building.id.toString(),
                  authState.token!,
                );
          }
          _clearForm();
        }

        if (state is ApartmentError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              onPressed: () => _showAddImagesDialog(),
              icon: const Icon(
                Icons.add_a_photo,
                color: Colors.white,
              ),
              label: const Text('Ajouter une photo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: AppColors.buttonColor,
              heroTag: 'Ajouter une photo',
            ),
            const SizedBox(height: 16),
            FloatingActionButton.extended(
              onPressed: () => _showAddApartmentDialog(),
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: const Text('Ajouter Appartement',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 11)),
              backgroundColor: AppColors.buttonColor,
              heroTag: 'publish',
            ),
          ],
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                ),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.add_photo_alternate),
                                        onPressed: () {
                                          _showAddImagesDialog();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    CircleAvatar(
                                      backgroundColor: Colors.white,
                                      child: IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () {
                                          _showAddApartmentDialog();
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Image Counter
                        if (images.length > 1)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
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
                        if (images.length > 1)
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
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.building.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${widget.building.address.street}, ${widget.building.address.city}, ${widget.building.address.country}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //       horizontal: 12, vertical: 6),
                            //   decoration: BoxDecoration(
                            //     color: _getStatusColor(widget.building.status)
                            //         .withOpacity(0.1),
                            //     borderRadius: BorderRadius.circular(20),
                            //   ),
                            //   child: Text(
                            //     _getStatusText(widget.building.status),
                            //     style: TextStyle(
                            //       color:
                            //           _getStatusColor(widget.building.status),
                            //       fontWeight: FontWeight.w600,
                            //       fontSize: 10,
                            //     ),
                            //   ),
                            // ),
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
                          widget.building.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
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
                        const SizedBox(height: 16),
                        BlocBuilder<ApartmentCubit, ApartmentState>(
                          builder: (context, state) {
                            if (state is ApartmentsLoaded) {
                              final totalApartments = state.apartments.length;
                              final availableApartments = state.apartments
                                  .where((apt) => apt['status'] == 'disponible')
                                  .length;
                              final occupiedApartments = state.apartments
                                  .where((apt) => apt['status'] == 'occupe')
                                  .length;
                              final renovationApartments = state.apartments
                                  .where(
                                      (apt) => apt['status'] == 'en_renovation')
                                  .length;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  _buildFeatureChip(
                                      '$totalApartments Appartements'),
                                  _buildFeatureChip(
                                      '$availableApartments Disponibles'),
                                  _buildFeatureChip(
                                      '$occupiedApartments Occupés'),
                                  _buildFeatureChip(
                                      '$renovationApartments En rénovation'),
                                  _buildFeatureChip(
                                      'Année ${widget.building.constructionYear}'),
                                  ...widget.building.features.map(
                                      (feature) => _buildFeatureChip(feature)),
                                ],
                              );
                            }
                            return Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: List.generate(6, (index) => 
                                SkeletonAvatar(
                                  style: SkeletonAvatarStyle(
                                    width: index % 2 == 0 ? 120 : 80,
                                    height: 32,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: const Icon(Icons.person,
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Propriétaire',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (widget.building.owner != null)
                                          Text(
                                            '${widget.building.owner!['firstName']} ${widget.building.owner!['lastName']}',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Appartements',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final authState =
                                    context.read<AuthCubit>().state;
                                if (authState is AuthSuccess) {
                                  // Afficher un indicateur de chargement
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Rafraîchissement en cours...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  // Rafraîchir les données
                                  await context
                                      .read<ApartmentCubit>()
                                      .getApartmentsByBuilding(
                                        widget.building.id.toString(),
                                        authState.token!,
                                      );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 6, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.refresh,
                                        color: AppColors.primary, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Rafraîchir',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        // const SizedBox(height: 16),
                        BlocBuilder<ApartmentCubit, ApartmentState>(
                          key: ValueKey('apartments_list_$_refreshCounter'),
                          builder: (context, state) {
                            if (state is ApartmentsLoaded) {
                              if (state.apartments.isEmpty) {
                                return const Center(
                                  child: Text('Aucun appartement disponible'),
                                );
                              }
                              return Column(
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: state.apartments.length,
                                    itemBuilder: (context, index) {
                                      final apartment = state.apartments[index];
                                      return _buildApartmentCard(apartment);
                                    },
                                  ),
                                ],
                              );
                            }
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Squelettes pour les 3 appartements
                                  for (int i = 0; i < 3; i++)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        children: [
                                          // Image de l'appartement
                                          SkeletonAvatar(
                                            style: SkeletonAvatarStyle(
                                              width: 80,
                                              height: 80,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Informations de l'appartement
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SkeletonLine(
                                                  style: SkeletonLineStyle(
                                                    height: 16,
                                                    width: 120,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                SkeletonLine(
                                                  style: SkeletonLineStyle(
                                                    height: 14,
                                                    width: 150,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                SkeletonLine(
                                                  style: SkeletonLineStyle(
                                                    height: 14,
                                                    width: 100,
                                                    borderRadius: BorderRadius.circular(8),
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
                            );
                          },
                        ),
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Affichage de la progression d'upload si en cours
            if (isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Card(
                      margin: EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Téléchargement en cours',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SkeletonAvatar(
                              style: SkeletonAvatarStyle(
                                width: 48,
                                height: 48,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Veuillez patienter...',
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
