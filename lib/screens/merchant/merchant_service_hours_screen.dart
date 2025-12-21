import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/merchant_hours.dart';
import 'package:immo/services/merchant_hours_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MerchantServiceHoursScreen extends StatefulWidget {
  const MerchantServiceHoursScreen({Key? key}) : super(key: key);

  @override
  State<MerchantServiceHoursScreen> createState() => _MerchantServiceHoursScreenState();
}

class _MerchantServiceHoursScreenState extends State<MerchantServiceHoursScreen> {
  MerchantServiceConfig _config = MerchantServiceConfig.getDefault();
  bool _isLoading = false;
  final MerchantHoursService _hoursService = MerchantHoursService();
  // Map pour suivre quels jours ont déjà un horaire enregistré dans l'API
  final Map<String, bool> _existingHoraires = {};
  // Sauvegarder l'état précédent des jours avant désactivation
  List<MerchantHours>? _previousHoursState;
  // Map pour suivre les jours en cours de chargement (par jour)
  final Map<String, bool> _loadingDays = {};

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      // Charger depuis l'API
      final result = await _hoursService.getAllHoraires();
      
      if (result['success'] == true && mounted) {
        final horairesJson = result['horaires'] as List<dynamic>;
        
        // Marquer tous les jours qui ont un horaire existant
        _existingHoraires.clear();
        for (var horaire in horairesJson) {
          final jour = horaire['jour']?.toString().toLowerCase() ?? '';
          if (jour.isNotEmpty) {
            _existingHoraires[jour] = true;
          }
        }
        
        if (horairesJson.isNotEmpty) {
          // Convertir depuis l'API
          _config = MerchantServiceConfig.fromApiHoraires(horairesJson);
          // Sauvegarder l'état actuel comme état précédent (pour restauration future)
          _previousHoursState = List<MerchantHours>.from(_config.hours);
        } else {
          // Aucun horaire enregistré, utiliser les valeurs par défaut
          _config = MerchantServiceConfig.getDefault();
          _previousHoursState = List<MerchantHours>.from(_config.hours);
        }
        
        // Charger le statut "isManuallyOffline" depuis SharedPreferences (géré localement)
        // Par défaut, le contrôle manuel est actif (suit les heures) donc isManuallyOffline = false
        final prefs = await SharedPreferences.getInstance();
        final isManuallyOffline = prefs.getBool('merchant_manually_offline') ?? false;
        _config = _config.copyWith(isManuallyOffline: isManuallyOffline);
        
        // Si le contrôle manuel est désactivé (hors ligne), s'assurer que tous les jours sont désactivés localement
        if (isManuallyOffline) {
          final updatedHours = _config.hours.map((h) => 
            h.copyWith(isEnabled: false)
          ).toList();
          _config = _config.copyWith(hours: updatedHours);
        }
      } else {
        // En cas d'erreur, utiliser les valeurs par défaut
        _config = MerchantServiceConfig.getDefault();
        if (mounted && result['error'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _config = MerchantServiceConfig.getDefault();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Méthode commentée car le bouton "Enregistrer les modifications" a été désactivé
  // Chaque jour a maintenant son propre bouton "Enregistrer"
  // Future<void> _saveConfig() async {
  //   // Vérifier que toutes les heures sont valides
  //   final allValid = _config.hours.every((h) => _validateHours(h));
  //   if (!allValid) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Veuillez corriger les heures invalides (heure d\'ouverture doit être avant l\'heure de fermeture)'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //     return;
  //   }

  //   if (!mounted) return;
  //   setState(() => _isLoading = true);
    
  //   try {
  //     int successCount = 0;
  //     int errorCount = 0;
  //     String? lastError;

  //     // Sauvegarder chaque jour via l'API
  //     for (var dayHours in _config.hours) {
  //       Map<String, dynamic> result;
        
  //       // Si l'horaire existe déjà, utiliser PUT (update), sinon POST (create)
  //       if (_existingHoraires[dayHours.jourApi] == true) {
  //         result = await _hoursService.updateHoraire(
  //           jour: dayHours.jourApi,
  //           heureOuverture: dayHours.isEnabled ? dayHours.openTime : null,
  //           heureFermeture: dayHours.isEnabled ? dayHours.closeTime : null,
  //           estOuvert: dayHours.isEnabled,
  //         );
  //       } else {
  //         result = await _hoursService.createOrUpdateHoraire(
  //           jour: dayHours.jourApi,
  //           heureOuverture: dayHours.isEnabled ? dayHours.openTime : null,
  //           heureFermeture: dayHours.isEnabled ? dayHours.closeTime : null,
  //           estOuvert: dayHours.isEnabled,
  //         );
  //       }

  //       if (result['success'] == true) {
  //         successCount++;
  //         // Marquer comme existant après création/mise à jour réussie
  //         _existingHoraires[dayHours.jourApi] = true;
  //       } else {
  //         errorCount++;
  //         lastError = result['error']?.toString();
  //       }
  //     }

  //     // Sauvegarder le statut "isManuallyOffline" localement
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.setBool('merchant_manually_offline', _config.isManuallyOffline);

  //     if (mounted) {
  //       setState(() => _isLoading = false);
        
  //       if (errorCount == 0) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Configuration enregistrée avec succès'),
  //             backgroundColor: AppColors.success,
  //           ),
  //         );
  //       } else if (successCount > 0) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('$successCount horaire(s) enregistré(s), $errorCount erreur(s): $lastError'),
  //             backgroundColor: Colors.orange,
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           SnackBar(
  //             content: Text('Erreur lors de l\'enregistrement: $lastError'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() => _isLoading = false);
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Erreur lors de l\'enregistrement: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  Future<void> _selectTime(BuildContext context, MerchantHours dayHours, bool isOpenTime) async {
    final initialTime = isOpenTime && dayHours.openTime != null
        ? TimeOfDay(
            hour: int.parse(dayHours.openTime!.split(':')[0]),
            minute: int.parse(dayHours.openTime!.split(':')[1]),
          )
        : dayHours.closeTime != null
            ? TimeOfDay(
                hour: int.parse(dayHours.closeTime!.split(':')[0]),
                minute: int.parse(dayHours.closeTime!.split(':')[1]),
              )
            : const TimeOfDay(hour: 8, minute: 0);

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
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

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        final index = _config.hours.indexWhere((h) => h.day == dayHours.day);
        if (index != -1) {
          final updatedHours = List<MerchantHours>.from(_config.hours);
          updatedHours[index] = updatedHours[index].copyWith(
            openTime: isOpenTime ? timeString : updatedHours[index].openTime,
            closeTime: !isOpenTime ? timeString : updatedHours[index].closeTime,
          );
          _config = _config.copyWith(hours: updatedHours);
        }
      });
    }
  }

  bool _validateHours(MerchantHours hours) {
    if (!hours.isEnabled || hours.openTime == null || hours.closeTime == null) {
      return true; // Pas besoin de validation si le jour est désactivé
    }

    final openParts = hours.openTime!.split(':');
    final closeParts = hours.closeTime!.split(':');
    
    final openMinutes = int.parse(openParts[0]) * 60 + int.parse(openParts[1]);
    final closeMinutes = int.parse(closeParts[0]) * 60 + int.parse(closeParts[1]);

    return openMinutes < closeMinutes;
  }

  /// Sauvegarde un horaire individuel (Create ou Update)
  Future<void> _saveSingleHoraire(MerchantHours dayHours) async {
    if (!_validateHours(dayHours)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('L\'heure d\'ouverture doit être avant l\'heure de fermeture'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _loadingDays[dayHours.jourApi] = true;
    });

    try {
      Map<String, dynamic> result;
      
      // Si l'horaire existe déjà, utiliser PUT (update), sinon POST (create)
      if (_existingHoraires[dayHours.jourApi] == true) {
        result = await _hoursService.updateHoraire(
          jour: dayHours.jourApi,
          heureOuverture: dayHours.isEnabled ? dayHours.openTime : null,
          heureFermeture: dayHours.isEnabled ? dayHours.closeTime : null,
          estOuvert: dayHours.isEnabled,
        );
      } else {
        result = await _hoursService.createOrUpdateHoraire(
          jour: dayHours.jourApi,
          heureOuverture: dayHours.isEnabled ? dayHours.openTime : null,
          heureFermeture: dayHours.isEnabled ? dayHours.closeTime : null,
          estOuvert: dayHours.isEnabled,
        );
      }

      if (mounted) {
        setState(() {
          _loadingDays[dayHours.jourApi] = false;
        });
        
        if (result['success'] == true) {
          // Marquer comme existant après création/mise à jour réussie
          _existingHoraires[dayHours.jourApi] = true;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Horaire du ${dayHours.day} enregistré avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingDays[dayHours.jourApi] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Supprime un horaire pour un jour spécifique (sans confirmation)
  Future<void> _deleteHoraire(MerchantHours dayHours, {bool showConfirmation = false}) async {
    if (_existingHoraires[dayHours.jourApi] != true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun horaire enregistré pour ce jour'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Demander confirmation seulement si demandé explicitement
    if (showConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer l\'horaire'),
          content: Text('Êtes-vous sûr de vouloir supprimer l\'horaire du ${dayHours.day} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _loadingDays[dayHours.jourApi] = true;
    });

    try {
      final result = await _hoursService.deleteHoraire(dayHours.jourApi);

      if (mounted) {
        setState(() {
          _loadingDays[dayHours.jourApi] = false;
        });
        
        if (result['success'] == true) {
          // Retirer de la map des horaires existants
          _existingHoraires.remove(dayHours.jourApi);
          
          // Mettre à jour la config locale : désactiver le jour
          final index = _config.hours.indexWhere((h) => h.day == dayHours.day);
          if (index != -1) {
            final updatedHours = List<MerchantHours>.from(_config.hours);
            updatedHours[index] = updatedHours[index].copyWith(
              isEnabled: false,
              openTime: null,
              closeTime: null,
            );
            _config = _config.copyWith(hours: updatedHours);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Horaire du ${dayHours.day} supprimé avec succès'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingDays[dayHours.jourApi] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Sauvegarde le statut du contrôle manuel
  Future<void> _saveManualControl(bool isManuallyOffline) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('merchant_manually_offline', isManuallyOffline);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isManuallyOffline
                  ? 'Boutique mise hors ligne - tous les jours désactivés'
                  : 'Boutique en ligne - disponibilités restaurées',
            ),
            backgroundColor: isManuallyOffline ? Colors.orange : AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Désactive tous les jours dans l'API (en parallèle pour réduire le temps)
  Future<void> _deactivateAllDays() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Faire tous les appels API en parallèle pour réduire le temps de chargement
      final futures = _config.hours.map((dayHours) async {
        if (_existingHoraires[dayHours.jourApi] == true) {
          return await _hoursService.updateHoraire(
            jour: dayHours.jourApi,
            estOuvert: false,
          );
        } else {
          return await _hoursService.createOrUpdateHoraire(
            jour: dayHours.jourApi,
            estOuvert: false,
          );
        }
      }).toList();

      final results = await Future.wait(futures);
      
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < results.length; i++) {
        if (results[i]['success'] == true) {
          successCount++;
          _existingHoraires[_config.hours[i].jourApi] = true;
        } else {
          errorCount++;
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (errorCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount jour(s) désactivé(s), $errorCount erreur(s)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la désactivation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Restaure l'état précédent des heures (en parallèle pour réduire le temps)
  Future<void> _restorePreviousHours() async {
    if (_previousHoursState == null || !mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Faire tous les appels API en parallèle pour réduire le temps de chargement
      final futures = _previousHoursState!.map((previousDayHours) async {
        if (_existingHoraires[previousDayHours.jourApi] == true) {
          return await _hoursService.updateHoraire(
            jour: previousDayHours.jourApi,
            heureOuverture: previousDayHours.isEnabled ? previousDayHours.openTime : null,
            heureFermeture: previousDayHours.isEnabled ? previousDayHours.closeTime : null,
            estOuvert: previousDayHours.isEnabled,
          );
        } else {
          return await _hoursService.createOrUpdateHoraire(
            jour: previousDayHours.jourApi,
            heureOuverture: previousDayHours.isEnabled ? previousDayHours.openTime : null,
            heureFermeture: previousDayHours.isEnabled ? previousDayHours.closeTime : null,
            estOuvert: previousDayHours.isEnabled,
          );
        }
      }).toList();

      final results = await Future.wait(futures);
      
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < results.length; i++) {
        if (results[i]['success'] == true) {
          successCount++;
          _existingHoraires[_previousHoursState![i].jourApi] = true;
        } else {
          errorCount++;
        }
      }

      // Mettre à jour la config avec l'état restauré
      if (mounted) {
        setState(() {
          _config = _config.copyWith(hours: _previousHoursState!);
          _isLoading = false;
        });
        
        if (errorCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount jour(s) restauré(s), $errorCount erreur(s)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la restauration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Active les heures par défaut (si pas d'état précédent) - en parallèle pour réduire le temps
  Future<void> _activateDefaultHours() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);

    try {
      // Utiliser les heures par défaut
      final defaultConfig = MerchantServiceConfig.getDefault();
      
      // Faire tous les appels API en parallèle pour réduire le temps de chargement
      final futures = defaultConfig.hours.map((dayHours) async {
        return await _hoursService.createOrUpdateHoraire(
          jour: dayHours.jourApi,
          heureOuverture: dayHours.isEnabled ? dayHours.openTime : null,
          heureFermeture: dayHours.isEnabled ? dayHours.closeTime : null,
          estOuvert: dayHours.isEnabled,
        );
      }).toList();

      final results = await Future.wait(futures);
      
      int successCount = 0;
      int errorCount = 0;

      for (int i = 0; i < results.length; i++) {
        if (results[i]['success'] == true) {
          successCount++;
          _existingHoraires[defaultConfig.hours[i].jourApi] = true;
        } else {
          errorCount++;
        }
      }

      // Mettre à jour la config avec les heures par défaut
      if (mounted) {
        setState(() {
          _config = _config.copyWith(hours: defaultConfig.hours);
          _isLoading = false;
        });
        
        if (errorCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$successCount jour(s) activé(s), $errorCount erreur(s)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'activation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Récupère un horaire spécifique pour un jour
  Future<void> _loadSingleHoraire(String jour) async {
    if (!mounted) return;
    
    try {
      final result = await _hoursService.getHoraireByDay(jour);
      
      if (result['success'] == true && mounted) {
        final horaireJson = result['horaire'] as Map<String, dynamic>;
        final horaire = MerchantHours.fromJson(horaireJson);
        
        // Mettre à jour la config avec cet horaire
        final index = _config.hours.indexWhere((h) => h.jourApi == jour);
        if (index != -1) {
          final updatedHours = List<MerchantHours>.from(_config.hours);
          updatedHours[index] = horaire;
          _config = _config.copyWith(hours: updatedHours);
          _existingHoraires[jour] = true;
          
          setState(() {});
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Horaire du ${horaire.day} rechargé'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rechargement: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculer le statut actuel : si manuellement offline, toujours fermé
    // Sinon, vérifier selon les heures programmées
    // final isCurrentlyOpen = _config.isCurrentlyOpen();
    // final statusMessage = _config.isManuallyOffline
    //     ? 'Boutique fermée manuellement'
    //     : (isCurrentlyOpen
    //         ? 'Boutique ouverte selon les heures programmées'
    //         : 'Boutique fermée selon les heures programmées');
    
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Heures de service',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: _isLoading && _loadingDays.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConfig,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Statut de la boutique
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  //   decoration: BoxDecoration(
                  //     color: isCurrentlyOpen ? Colors.green.shade50 : Colors.red.shade50,
                  //     borderRadius: BorderRadius.circular(12),
                  //     border: Border.all(
                  //       color: isCurrentlyOpen ? Colors.green.shade300 : Colors.red.shade300,
                  //       width: 1,
                  //     ),
                  //   ),
                  //   child: Row(
                  //     children: [
                  //       Icon(
                  //         isCurrentlyOpen ? Icons.check_circle : Icons.cancel,
                  //         color: isCurrentlyOpen ? Colors.green.shade700 : Colors.red.shade700,
                  //         size: 24,
                  //       ),
                  //       const SizedBox(width: 10),
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text(
                  //               isCurrentlyOpen ? 'Boutique ouverte' : 'Boutique fermée',
                  //               style: TextStyle(
                  //                 fontSize: 15,
                  //                 fontWeight: FontWeight.w600,
                  //                 color: isCurrentlyOpen ? Colors.green.shade900 : Colors.red.shade900,
                  //               ),
                  //             ),
                  //             const SizedBox(height: 2),
                  //             Text(
                  //               statusMessage,
                  //               style: TextStyle(
                  //                 fontSize: 12,
                  //                 color: isCurrentlyOpen ? Colors.green.shade700 : Colors.red.shade700,
                  //               ),
                  //             ),
                  //           ],
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  
                  // const SizedBox(height: 14),
                  
                  // Bouton pour mettre hors ligne/en ligne manuellement
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contrôle manuel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _config.isManuallyOffline
                              ? 'Votre boutique est fermée manuellement, peu importe les heures configurées'
                              : 'Votre boutique suit automatiquement les heures d\'ouverture configurées pour chaque jour',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Switch(
                              value: !_config.isManuallyOffline,
                              onChanged: (value) async {
                                // value = true signifie "En ligne" (suit les heures)
                                // value = false signifie "Hors ligne" (indisponible)
                                
                                if (!value) {
                                  // On désactive le contrôle manuel (mise hors ligne)
                                  // Sauvegarder l'état actuel avant de tout désactiver
                                  _previousHoursState = List<MerchantHours>.from(_config.hours);
                                  
                                  // Désactiver tous les jours dans l'API
                                  await _deactivateAllDays();
                                  
                                  // Mettre à jour la config locale
                                  setState(() {
                                    final updatedHours = _config.hours.map((h) => 
                                      h.copyWith(isEnabled: false)
                                    ).toList();
                                    _config = _config.copyWith(
                                      isManuallyOffline: true,
                                      hours: updatedHours,
                                    );
                                  });
                                } else {
                                  // On active le contrôle manuel (suit les heures)
                                  // Restaurer l'état précédent si disponible
                                  if (_previousHoursState != null) {
                                    await _restorePreviousHours();
                                  } else {
                                    // Si pas d'état précédent, activer les jours par défaut
                                    await _activateDefaultHours();
                                  }
                                  
                                  setState(() {
                                    _config = _config.copyWith(isManuallyOffline: false);
                                  });
                                }
                                
                                // Sauvegarder le statut du contrôle manuel
                                await _saveManualControl(!value);
                              },
                              activeColor: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _config.isManuallyOffline ? 'Hors ligne' : 'En ligne',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _config.isManuallyOffline ? Colors.red.shade700 : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _config.isManuallyOffline
                                        ? 'Boutique fermée manuellement'
                                        : 'Suit les heures programmées',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
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
                  
                  const SizedBox(height: 18),
                  
                  // Configuration des heures par jour
                  const Text(
                    'Heures d\'ouverture par jour',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ..._config.hours.map((dayHours) {
                    final isValid = _validateHours(dayHours);
                    final hasExistingHoraire = _existingHoraires[dayHours.jourApi] == true;
                    final isLoading = _loadingDays[dayHours.jourApi] == true;
                    return _DayHoursCard(
                      dayHours: dayHours,
                      hasExistingHoraire: hasExistingHoraire,
                      isLoading: isLoading,
                      onEnabledChanged: (enabled) async {
                        // Si on désactive un horaire qui existe déjà, exécuter la même action que delete (sans confirmation)
                        if (!enabled && hasExistingHoraire) {
                          await _deleteHoraire(dayHours, showConfirmation: false);
                        } else {
                          // Sinon, juste mettre à jour l'état local
                          setState(() {
                            final index = _config.hours.indexWhere((h) => h.day == dayHours.day);
                            if (index != -1) {
                              final updatedHours = List<MerchantHours>.from(_config.hours);
                              updatedHours[index] = updatedHours[index].copyWith(isEnabled: enabled);
                              _config = _config.copyWith(hours: updatedHours);
                            }
                          });
                        }
                      },
                      onOpenTimeTap: () => _selectTime(context, dayHours, true),
                      onCloseTimeTap: () => _selectTime(context, dayHours, false),
                      onSave: () => _saveSingleHoraire(dayHours),
                      // onDelete: () => _deleteHoraire(dayHours), // Commenté : la désactivation fait la même action
                      onDelete: null, // Désactivé car la désactivation fait la même action
                      onRefresh: () => _loadSingleHoraire(dayHours.jourApi),
                      isValid: isValid,
                    );
                  }).toList(),
                  
                  const SizedBox(height: 18),
                  
                  // Bouton de sauvegarde (commenté car chaque jour a son propre bouton)
                  // SizedBox(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: _isLoading ? null : _saveConfig,
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: AppColors.primary,
                  //       foregroundColor: Colors.white,
                  //       padding: const EdgeInsets.symmetric(vertical: 14),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: const Text(
                  //       'Enregistrer les modifications',
                  //       style: TextStyle(
                  //         fontSize: 14,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
    );
  }
}

class _DayHoursCard extends StatelessWidget {
  final MerchantHours dayHours;
  final Function(bool) onEnabledChanged;
  final VoidCallback onOpenTimeTap;
  final VoidCallback onCloseTimeTap;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final VoidCallback? onRefresh;
  final bool isValid;
  final bool hasExistingHoraire;
  final bool isLoading;

  const _DayHoursCard({
    required this.dayHours,
    required this.onEnabledChanged,
    required this.onOpenTimeTap,
    required this.onCloseTimeTap,
    this.onSave,
    this.onDelete,
    this.onRefresh,
    required this.isValid,
    required this.hasExistingHoraire,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isValid ? Colors.grey.shade200 : Colors.red.shade300,
          width: isValid ? 1 : 1.5,
        ),
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: isLoading ? 0.6 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            dayHours.day,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (hasExistingHoraire) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Enregistré',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onRefresh != null && !isLoading)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 16),
                        color: AppColors.primary,
                        onPressed: onRefresh,
                        tooltip: 'Recharger',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: dayHours.isEnabled,
                        onChanged: isLoading ? null : onEnabledChanged,
                        activeColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (dayHours.isEnabled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _TimeButton(
                          label: 'Ouverture',
                          time: dayHours.openTime ?? '08:00',
                          onTap: isLoading ? () {} : onOpenTimeTap,
                          icon: Icons.access_time,
                          enabled: !isLoading,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TimeButton(
                          label: 'Fermeture',
                          time: dayHours.closeTime ?? '18:00',
                          onTap: isLoading ? () {} : onCloseTimeTap,
                          icon: Icons.access_time,
                          enabled: !isLoading,
                        ),
                      ),
                    ],
                  ),
                  if (!isValid) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 12),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'L\'heure d\'ouverture doit être avant l\'heure de fermeture',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Boutons d'action (Save/Delete)
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (onSave != null)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : onSave,
                            icon: isLoading
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary.withOpacity(0.7),
                                      ),
                                    ),
                                  )
                                : Icon(Icons.save, size: 14, color: AppColors.primary.withOpacity(0.7)),
                            label: Text(
                              isLoading ? 'Enregistrement...' : 'Enregistrer',
                              style: TextStyle(fontSize: 11, color: AppColors.primary.withOpacity(0.8)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      // Bouton delete commenté : la désactivation fait la même action
                      // if (onDelete != null && hasExistingHoraire) ...[
                      //   const SizedBox(width: 6),
                      //   IconButton(
                      //     icon: const Icon(Icons.delete_outline, size: 18),
                      //     color: Colors.red,
                      //     onPressed: onDelete,
                      //     tooltip: 'Supprimer',
                      //     padding: EdgeInsets.zero,
                      //     constraints: const BoxConstraints(),
                      //   ),
                      // ],
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Fermé ce jour',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      // Bouton delete commenté : la désactivation fait la même action
                      // if (onDelete != null && hasExistingHoraire)
                      //   IconButton(
                      //     icon: const Icon(Icons.delete_outline, size: 18),
                      //     color: Colors.red,
                      //     onPressed: onDelete,
                      //     tooltip: 'Supprimer l\'horaire',
                      //     padding: EdgeInsets.zero,
                      //     constraints: const BoxConstraints(),
                      //   ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Indicateur de chargement
          if (isLoading)
            Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;
  final IconData icon;
  final bool enabled;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
    required this.icon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 12, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

