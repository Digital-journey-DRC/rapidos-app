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
  
  DateTime? _delaiPromotion;
  List<String> _existingSecondaryImages = []; // URLs des images existantes
  List<bool> _deleteSecondaryImages = []; // Indique si on doit supprimer chaque image
  List<File> _newSecondaryImages = []; // Nouvelles images à uploader
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
    _mainImageUrl = widget.promotion.image;
    _existingSecondaryImages = List.from(widget.promotion.images);
    _deleteSecondaryImages = List.filled(_existingSecondaryImages.length, false);
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

  Future<void> _pickSecondaryImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 800,
      );
      if (images.isNotEmpty && mounted) {
        setState(() {
          final newImages = images.map((xFile) => File(xFile.path)).toList();
          final totalSlots = _existingSecondaryImages.length + _newSecondaryImages.length;
          final remainingSlots = 4 - totalSlots;
          if (remainingSlots > 0) {
            _newSecondaryImages.addAll(newImages.take(remainingSlots));
            if (newImages.length > remainingSlots && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 4 images secondaires autorisées'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Maximum 4 images secondaires autorisées'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        });
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
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_delaiPromotion ?? DateTime.now()),
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
      File? mainImageFile;
      if (_mainImageFile != null) {
        mainImageFile = await _compressImage(_mainImageFile!);
      }

      final List<File> compressedSecondaryImages = [];
      for (var image in _newSecondaryImages) {
        if (!mounted) break;
        final compressed = await _compressImage(image);
        if (compressed != null) {
          compressedSecondaryImages.add(compressed);
        }
      }

      final promotionService = PromotionService();
      
      final result = await promotionService.updatePromotion(
        promotionId: widget.promotion.id,
        libelle: _libelleController.text,
        delaiPromotion: _delaiPromotion,
        nouveauPrix: double.parse(_nouveauPrixController.text),
        ancienPrix: double.parse(_ancienPrixController.text),
        image: mainImageFile,
        image1: compressedSecondaryImages.isNotEmpty ? compressedSecondaryImages[0] : null,
        image2: compressedSecondaryImages.length > 1 ? compressedSecondaryImages[1] : null,
        image3: compressedSecondaryImages.length > 2 ? compressedSecondaryImages[2] : null,
        image4: compressedSecondaryImages.length > 3 ? compressedSecondaryImages[3] : null,
        deleteImage1: _deleteSecondaryImages.isNotEmpty && _deleteSecondaryImages[0],
        deleteImage2: _deleteSecondaryImages.length > 1 && _deleteSecondaryImages[1],
        deleteImage3: _deleteSecondaryImages.length > 2 && _deleteSecondaryImages[2],
        deleteImage4: _deleteSecondaryImages.length > 3 && _deleteSecondaryImages[3],
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
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

              // Date de fin
              const Text('Date de fin de promotion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _delaiPromotion != null
                            ? '${_delaiPromotion!.day}/${_delaiPromotion!.month}/${_delaiPromotion!.year} ${_delaiPromotion!.hour}:${_delaiPromotion!.minute.toString().padLeft(2, '0')}'
                            : 'Sélectionner une date',
                        style: TextStyle(
                          fontSize: 13,
                          color: _delaiPromotion != null ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                      const Icon(Icons.calendar_today, size: 20),
                    ],
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

              // Images secondaires existantes
              if (_existingSecondaryImages.isNotEmpty) ...[
                const Text('Images secondaires existantes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _existingSecondaryImages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _deleteSecondaryImages[index] ? Colors.red : Colors.grey.shade300,
                                  width: _deleteSecondaryImages[index] ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  _existingSecondaryImages[index],
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _deleteSecondaryImages[index] = !_deleteSecondaryImages[index];
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _deleteSecondaryImages[index] ? Colors.red : Colors.grey.shade700,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _deleteSecondaryImages[index] ? Icons.close : Icons.delete,
                                    color: Colors.white,
                                    size: 16,
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
                const SizedBox(height: 12),
              ],

              // Nouvelles images secondaires
              const Text('Nouvelles images secondaires (optionnelles, max 4)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickSecondaryImages,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _newSecondaryImages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, color: Colors.grey.shade400, size: 20),
                              const SizedBox(height: 4),
                              Text('Ajouter des images', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(4),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: _newSecondaryImages.length,
                          itemBuilder: (context, index) {
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _newSecondaryImages[index],
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
                                        _newSecondaryImages.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ),
              const SizedBox(height: 30),

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

