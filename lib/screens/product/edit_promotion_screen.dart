import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import '../../constants.dart';
import '../../services/promotion_service.dart';
import '../../models/promotion.dart';

class EditPromotionScreen extends StatefulWidget {
  final Promotion promotion;
  
  const EditPromotionScreen({
    Key? key,
    required this.promotion,
  }) : super(key: key);

  @override
  State<EditPromotionScreen> createState() => _EditPromotionScreenState();
}

class _EditPromotionScreenState extends State<EditPromotionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _libelleController = TextEditingController();
  final _nouveauPrixController = TextEditingController();
  final _ancienPrixController = TextEditingController();
  
  DateTime? _delaiPromotion; // Date de fin (obligatoire)
  DateTime? _dateDebutPromotion; // Date de début (optionnel)
  List<String> _productSecondaryImages = []; // URLs des images supplémentaires du produit (non modifiables)
  String? _mainImageUrl; // URL de l'image principale existante
  File? _mainImageFile; // Nouveau fichier de l'image principale
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les données de la promotion
    _libelleController.text = widget.promotion.libelle;
    _nouveauPrixController.text = widget.promotion.nouveauPrix.toStringAsFixed(2);
    _ancienPrixController.text = widget.promotion.ancienPrix.toStringAsFixed(2);
    _delaiPromotion = widget.promotion.delaiPromotion;
    _dateDebutPromotion = widget.promotion.dateDebutPromotion;
    _mainImageUrl = widget.promotion.image;
    
    // Pré-remplir les images supplémentaires avec les vraies images du produit (non modifiables)
    final product = widget.promotion.product;
    if (product != null && product.images.isNotEmpty) {
      // Utiliser les images du produit si disponibles
      _productSecondaryImages = product.images.take(4).toList();
    } else if (widget.promotion.images.isNotEmpty) {
      // Sinon, utiliser les images de la promotion existante (verrouillées aussi)
      _productSecondaryImages = widget.promotion.images.take(4).toList();
    }
  }

  @override
  void dispose() {
    _libelleController.dispose();
    _nouveauPrixController.dispose();
    _ancienPrixController.dispose();
    super.dispose();
  }

  Future<void> _pickMainImage() async {
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<File?> _compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      img.Image resizedImage = originalImage;
      if (originalImage.width > 800) {
        final ratio = 800 / originalImage.width;
        resizedImage = img.copyResize(
          originalImage,
          width: 800,
          height: (originalImage.height * ratio).round(),
        );
      }

      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      final tempDir = Directory.systemTemp;
      final compressedFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    } catch (e) {
      print('Erreur compression image: $e');
      return imageFile;
    }
  }

  Future<void> _selectDate({bool isStartDate = false}) async {
    if (!mounted) return;
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_dateDebutPromotion ?? DateTime.now())
          : (_delaiPromotion ?? DateTime.now().add(const Duration(days: 30))),
      firstDate: isStartDate ? DateTime.now().subtract(const Duration(days: 30)) : DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
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
              colorScheme: ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        setState(() {
          final selectedDateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          
          if (isStartDate) {
            _dateDebutPromotion = selectedDateTime;
            // Si la date de début est après la date de fin, ajuster la date de fin
            if (_delaiPromotion != null && _dateDebutPromotion!.isAfter(_delaiPromotion!)) {
              _delaiPromotion = _dateDebutPromotion!.add(const Duration(days: 7));
            }
          } else {
            _delaiPromotion = selectedDateTime;
            // Si la date de fin est avant la date de début, ajuster la date de début
            if (_dateDebutPromotion != null && _delaiPromotion!.isBefore(_dateDebutPromotion!)) {
              _dateDebutPromotion = _delaiPromotion!.subtract(const Duration(days: 7));
            }
          }
        });
      }
    }
  }

  Future<void> _submitPromotion() async {
    if (!_formKey.currentState!.validate()) {
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

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Ne télécharger et envoyer les images que si elles ont été modifiées
      // Si on modifie seulement les dates, on ne touche pas aux images
      File? mainImageFile;
      bool imageModified = _mainImageFile != null;
      
      if (_mainImageFile != null) {
        // Image principale modifiée : compresser et envoyer
        mainImageFile = await _compressImage(_mainImageFile!);
      }
      // Si l'image principale n'a pas été modifiée, on ne l'envoie pas (null)
      // Le backend gardera l'image existante

      // Les images secondaires sont toujours celles du produit (verrouillées)
      // On ne les envoie pas lors de la modification car elles ne changent jamais
      // Le backend gardera les images existantes

      // Vérifier que la date de début est avant la date de fin si les deux sont définies
      if (_dateDebutPromotion != null && _delaiPromotion != null) {
        if (_dateDebutPromotion!.isAfter(_delaiPromotion!)) {
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La date de début doit être antérieure à la date de fin'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final promotionService = PromotionService();
      
      final result = await promotionService.updatePromotion(
        promotionId: widget.promotion.id,
        libelle: _libelleController.text,
        delaiPromotion: _delaiPromotion,
        dateDebutPromotion: _dateDebutPromotion,
        nouveauPrix: double.parse(_nouveauPrixController.text),
        ancienPrix: double.parse(_ancienPrixController.text),
        // Envoyer l'image principale seulement si elle a été modifiée
        image: imageModified ? mainImageFile : null,
        // Ne pas envoyer les images secondaires si elles n'ont pas été modifiées
        // Le backend gardera les images existantes
        image1: null,
        image2: null,
        image3: null,
        image4: null,
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promotion mise à jour avec succès !'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la promotion'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Libellé
              const Text('Libellé de la promotion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _libelleController,
                decoration: InputDecoration(
                  hintText: 'Ex: Promotion spéciale -50%',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 13),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un libellé';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Nouveau prix
              const Text('Nouveau prix (FC)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nouveauPrixController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 13),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nouveau prix';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Le prix doit être supérieur à 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Ancien prix
              const Text('Ancien prix (FC)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ancienPrixController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                style: const TextStyle(fontSize: 13),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer l\'ancien prix';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Le prix doit être supérieur à 0';
                  }
                  final nouveauPrix = double.tryParse(_nouveauPrixController.text);
                  if (nouveauPrix != null && price <= nouveauPrix) {
                    return 'L\'ancien prix doit être supérieur au nouveau prix';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Date de début (optionnel)
              const Text(
                'Date de début de promotion (optionnel)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Si non spécifiée, la promotion commence immédiatement',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _selectDate(isStartDate: true),
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
                        _dateDebutPromotion != null
                            ? '${_dateDebutPromotion!.day}/${_dateDebutPromotion!.month}/${_dateDebutPromotion!.year} ${_dateDebutPromotion!.hour}:${_dateDebutPromotion!.minute.toString().padLeft(2, '0')}'
                            : 'Sélectionner une date de début (optionnel)',
                        style: TextStyle(
                          fontSize: 13,
                          color: _dateDebutPromotion != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                      if (_dateDebutPromotion != null) ...[
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _dateDebutPromotion = null;
                            });
                          },
                          child: Icon(Icons.close, color: Colors.grey.shade400, size: 18),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Date de fin (obligatoire)
              const Text(
                'Date de fin de promotion *',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _selectDate(isStartDate: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _delaiPromotion == null ? Colors.red.shade300 : Colors.grey.shade300,
                      width: _delaiPromotion == null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today, 
                        color: _delaiPromotion == null ? Colors.red : AppColors.primary, 
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _delaiPromotion != null
                            ? '${_delaiPromotion!.day}/${_delaiPromotion!.month}/${_delaiPromotion!.year} ${_delaiPromotion!.hour}:${_delaiPromotion!.minute.toString().padLeft(2, '0')}'
                            : 'Sélectionner une date de fin *',
                        style: TextStyle(
                          fontSize: 13,
                          color: _delaiPromotion != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_delaiPromotion == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Ce champ est obligatoire',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade600,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Image principale
              const Text('Image principale', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickMainImage,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _mainImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_mainImageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : (_mainImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(_mainImageUrl!, fit: BoxFit.cover, width: double.infinity),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, color: Colors.grey.shade400, size: 20),
                                  const SizedBox(height: 4),
                                  Text('Sélectionner l\'image principale', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                ],
                              ),
                            )),
                ),
              ),
              const SizedBox(height: 12),

              // Images secondaires (non modifiables)
              const Text(
                'Images secondaires (non modifiables)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ces images proviennent du produit et ne peuvent pas être modifiées',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 100,
                child: _productSecondaryImages.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune image supplémentaire',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _productSecondaryImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Opacity(
                              opacity: 0.7,
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _productSecondaryImages[index],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: Icon(Icons.image_not_supported, 
                                          size: 20, 
                                          color: Colors.grey.shade400),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey.shade100,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

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
                          'Mettre à jour la promotion',
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

