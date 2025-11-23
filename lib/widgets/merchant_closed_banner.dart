import 'dart:async';
import 'package:flutter/material.dart';
import 'package:immo/models/merchant_hours.dart';
import 'package:immo/services/merchant_hours_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget pour afficher un message quand la boutique est fermée
/// Synchronisé en temps réel avec l'API et le statut manuel
class MerchantClosedBanner extends StatefulWidget {
  const MerchantClosedBanner({Key? key}) : super(key: key);

  @override
  State<MerchantClosedBanner> createState() => _MerchantClosedBannerState();
}

class _MerchantClosedBannerState extends State<MerchantClosedBanner> with WidgetsBindingObserver {
  MerchantServiceConfig? _config;
  bool _isLoading = true;
  Timer? _refreshTimer;
  Timer? _checkTimer;
  final MerchantHoursService _hoursService = MerchantHoursService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadConfig();
    // Démarrer un timer pour mettre à jour toutes les minutes
    _startRefreshTimer();
    // Démarrer un timer pour vérifier le statut toutes les 30 secondes
    _startCheckTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _checkTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharger quand l'app revient au premier plan
    if (state == AppLifecycleState.resumed && mounted) {
      _loadConfig();
    }
  }

  void _startRefreshTimer() {
    // Mettre à jour toutes les minutes pour vérifier si les heures ont changé
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _loadConfig();
      } else {
        timer.cancel();
      }
    });
  }

  void _startCheckTimer() {
    // Vérifier le statut toutes les 30 secondes pour une mise à jour plus rapide
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _checkStatus();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkStatus() async {
    // Vérifier rapidement le statut manuel depuis SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final isManuallyOffline = prefs.getBool('merchant_manually_offline') ?? false;
      
      if (mounted && _config != null) {
        // Si le statut manuel a changé, recharger complètement
        if (_config!.isManuallyOffline != isManuallyOffline) {
          _loadConfig();
        } else {
          // Sinon, juste mettre à jour le statut local pour recalculer isCurrentlyOpen
          setState(() {
            _config = _config!.copyWith(isManuallyOffline: isManuallyOffline);
            if (isManuallyOffline) {
              // Si manuellement offline, désactiver tous les jours localement
              final updatedHours = _config!.hours.map((h) => 
                h.copyWith(isEnabled: false)
              ).toList();
              _config = _config!.copyWith(hours: updatedHours);
            }
          });
        }
      }
    } catch (e) {
      // Ignorer les erreurs silencieusement
    }
  }

  Future<void> _loadConfig() async {
    try {
      // Charger depuis l'API
      final result = await _hoursService.getAllHoraires();
      
      if (result['success'] == true && mounted) {
        final horairesJson = result['horaires'] as List<dynamic>;
        
        if (horairesJson.isNotEmpty) {
          // Convertir depuis l'API
          _config = MerchantServiceConfig.fromApiHoraires(horairesJson);
        } else {
          // Aucun horaire enregistré, utiliser les valeurs par défaut
          _config = MerchantServiceConfig.getDefault();
        }
        
        // Charger le statut "isManuallyOffline" depuis SharedPreferences (géré localement)
        final prefs = await SharedPreferences.getInstance();
        final isManuallyOffline = prefs.getBool('merchant_manually_offline') ?? false;
        _config = _config!.copyWith(isManuallyOffline: isManuallyOffline);
        
        // Si le contrôle manuel est désactivé, s'assurer que tous les jours sont désactivés localement
        if (isManuallyOffline) {
          final updatedHours = _config!.hours.map((h) => 
            h.copyWith(isEnabled: false)
          ).toList();
          _config = _config!.copyWith(hours: updatedHours);
        }
      } else {
        // En cas d'erreur, utiliser les valeurs par défaut
        _config = MerchantServiceConfig.getDefault();
      }
    } catch (e) {
      // En cas d'erreur, utiliser les valeurs par défaut
      _config = MerchantServiceConfig.getDefault();
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _config == null) {
      return const SizedBox.shrink();
    }

    // Vérifier si la boutique est fermée
    final isClosed = !_config!.isCurrentlyOpen();

    if (!isClosed) {
      return const SizedBox.shrink();
    }

    // Déterminer le message selon le type de fermeture
    final message = _config!.isManuallyOffline
        ? 'Ce marchand est actuellement fermé manuellement et ne peut pas effectuer de livraison pour le moment.'
        : 'Ce marchand est actuellement fermé et ne peut pas effectuer de livraison pour le moment.';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade700,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

