import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../../constants.dart';
import '../../widgets/app_logo.dart';
import '../../services/promotion_service.dart';
import '../../cubit/product_cubit.dart';
import '../../models/product.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreatePromotionScreen extends StatefulWidget {
  final Product? product; // Produit sélectionné (optionnel)
  
  const CreatePromotionScreen({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<CreatePromotionScreen> createState() => _CreatePromotionScreenState();
}

class _CreatePromotionScreenState extends State<CreatePromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _nouveauPrixController = TextEditingController();
  final _ancienPrixController = TextEditingController();
  final _productIdController = TextEditingController();
  
  DateTime? _delaiPromotion;
  List<File> _selectedImages = []; // Images secondaires (optionnelles)
  String? _mainImageUrl; // Image principale du produit (pré-remplie) - pour affichage uniquement
  File? _mainImageFile; // Fichier de l'image principale à envoyer
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Product> _products = [];
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    if (widget.product != null) {
      _selectedProduct = widget.product;
      _productIdController.text = widget.product!.id.toString();
      _ancienPrixController.text = widget.product!.price.toStringAsFixed(2);
      // Pré-remplir l'image principale du produit
      _mainImageUrl = widget.product!.media?.mediaUrl;
    }
  }

  Future<void> _loadProducts() async {
    try {
      final productCubit = context.read<ProductCubit>();
      await productCubit.fetchProducts();
      
      if (productCubit.state is ProductLoaded) {
        setState(() {
          _products = (productCubit.state as ProductLoaded).products;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des produits: $e');
    }
  }

  Future<void> _pickImages({bool isMain = false}) async {
    try {
      if (isMain) {
        // Sélectionner l'image principale
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 800,
        );
        if (image != null && mounted) {
          setState(() {
            _mainImageFile = File(image.path);
            _mainImageUrl = null; // Effacer l'URL si on sélectionne un nouveau fichier
          });
        }
      } else {
        // Sélectionner les images secondaires
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
          maxWidth: 800,
        );
        if (images.isNotEmpty && mounted) {
          setState(() {
            final newImages = images.map((xFile) => File(xFile.path)).toList();
            // Limiter à 4 images secondaires
            final totalImages = _selectedImages.length + newImages.length;
            if (totalImages > 4) {
              final remainingSlots = 4 - _selectedImages.length;
              _selectedImages.addAll(newImages.take(remainingSlots));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maximum 4 images secondaires autorisées'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            } else {
              _selectedImages.addAll(newImages);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Compresse une image pour réduire sa taille
  Future<File?> _compressImage(File imageFile) async {
    try {
      // Lire l'image
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) return null;

      // Redimensionner l'image si elle est trop grande (max 800px de largeur)
      img.Image resizedImage = originalImage;
      if (originalImage.width > 800) {
        final ratio = 800 / originalImage.width;
        resizedImage = img.copyResize(
          originalImage,
          width: 800,
          height: (originalImage.height * ratio).round(),
        );
      }

      // Compresser l'image (qualité 85%)
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      
      // Créer un fichier temporaire compressé
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      print('Erreur compression image: $e');
      // En cas d'erreur, retourner le fichier original
      return imageFile;
    }
  }


  Future<void> _selectDate() async {
    if (!mounted) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _delaiPromotion ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          _delaiPromotion = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Vérifier qu'on a l'image principale
    if (_mainImageFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une image principale'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_delaiPromotion == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une date de fin de promotion'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (_selectedProduct == null && _productIdController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un produit'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Compresser l'image principale si nécessaire
      File? mainImageFile = _mainImageFile;
      if (mainImageFile != null) {
        final compressed = await _compressImage(mainImageFile);
        mainImageFile = compressed ?? mainImageFile;
      }

      // Compresser les images secondaires
      final List<File> compressedSecondaryImages = [];
      for (var image in _selectedImages) {
        if (!mounted) break;
        final compressed = await _compressImage(image);
        compressedSecondaryImages.add(compressed ?? image);
      }

      // Créer la promotion avec les fichiers directement
      final promotionService = PromotionService();
      final productId = _selectedProduct?.id ?? int.parse(_productIdController.text);
      
      final result = await promotionService.createPromotion(
        productId: productId,
        image: mainImageFile!,
        image1: compressedSecondaryImages.isNotEmpty ? compressedSecondaryImages[0] : null,
        image2: compressedSecondaryImages.length > 1 ? compressedSecondaryImages[1] : null,
        image3: compressedSecondaryImages.length > 2 ? compressedSecondaryImages[2] : null,
        image4: compressedSecondaryImages.length > 3 ? compressedSecondaryImages[3] : null,
        libelle: _libelleController.text,
        delaiPromotion: _delaiPromotion!,
        nouveauPrix: double.parse(_nouveauPrixController.text),
        ancienPrix: double.parse(_ancienPrixController.text),
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion créée avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true); // Retour avec succès
        }
      } else {
        throw Exception(result['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _nouveauPrixController.dispose();
    _ancienPrixController.dispose();
    _productIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Créer une promotion',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection du produit
              if (widget.product == null) ...[
                const Text(
                  'Produit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<Product>(
                  value: _selectedProduct,
                  decoration: InputDecoration(
                    labelText: 'Sélectionner un produit',
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  dropdownColor: Colors.white,
                  icon: Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 24),
                  isExpanded: true,
                  menuMaxHeight: 400,
                  items: _products.map((product) {
                    final imageUrl = product.media?.mediaUrl ?? '';
                    return DropdownMenuItem(
                      value: product,
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.only(top: 2, bottom: 2),
                        child: Row(
                          children: [
                            // Image du produit
                            if (imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  imageUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(Icons.image, size: 16, color: Colors.grey.shade400),
                                    );
                                  },
                                ),
                              )
                            else
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(Icons.image, size: 16, color: Colors.grey.shade400),
                              ),
                            const SizedBox(width: 8),
                            // Nom du produit
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setState(() {
                      _selectedProduct = product;
                      _productIdController.text = product?.id.toString() ?? '';
                      _ancienPrixController.text = product?.price.toStringAsFixed(2) ?? '';
                      // Pré-remplir l'image principale du produit
                      _mainImageUrl = product?.media?.mediaUrl;
                      // Réinitialiser les images secondaires
                      _selectedImages = [];
                    });
                  },
                  validator: (value) {
                    if (value == null && _productIdController.text.isEmpty) {
                      return 'Veuillez sélectionner un produit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ] else ...[
                // Afficher le produit sélectionné
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          widget.product!.media?.mediaUrl ?? '',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image, size: 20),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${widget.product!.price.toStringAsFixed(0)} FC',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Libellé
              const Text(
                'Libellé de la promotion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _libelleController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ex: Promotion spéciale -50%',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un libellé';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Prix
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ancien prix',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ancienPrixController,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixText: 'FC ',
                            prefixStyle: const TextStyle(fontSize: 13),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Prix invalide';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nouveau prix',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nouveauPrixController,
                          style: const TextStyle(fontSize: 13),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: const TextStyle(fontSize: 13),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixText: 'FC ',
                            prefixStyle: const TextStyle(fontSize: 13),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requis';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Prix invalide';
                            }
                            final nouveauPrix = double.parse(value);
                            final ancienPrix = double.tryParse(_ancienPrixController.text) ?? 0;
                            if (nouveauPrix >= ancienPrix) {
                              return 'Le nouveau prix doit être inférieur';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date de fin
              const Text(
                'Date de fin de promotion',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        _delaiPromotion != null
                            ? '${_delaiPromotion!.day}/${_delaiPromotion!.month}/${_delaiPromotion!.year} ${_delaiPromotion!.hour}:${_delaiPromotion!.minute.toString().padLeft(2, '0')}'
                            : 'Sélectionner une date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _delaiPromotion != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Image principale
              const Text(
                'Image principale',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => _pickImages(isMain: true),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _mainImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _mainImageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                      : (_mainImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _mainImageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate, color: Colors.grey.shade400, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Sélectionner l\'image principale',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.grey.shade400, size: 20),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sélectionner l\'image principale',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                  ),
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 12),
              // Images secondaires (optionnelles)
              const Text(
                'Images secondaires (optionnelles, max 4)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vous pouvez ajouter jusqu\'à 4 images supplémentaires',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _pickImages(isMain: false),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _selectedImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.grey.shade400, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                'Appuyer pour ajouter des images',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 4,
                            mainAxisSpacing: 4,
                          ),
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(
                                    _selectedImages[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPromotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Créer la promotion',
                          style: TextStyle(
                            fontSize: 14,
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
  }
}

