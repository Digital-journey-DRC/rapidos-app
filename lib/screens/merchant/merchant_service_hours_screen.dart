import 'package:flutter/material.dart';
import 'package:immo/constants.dart';
import 'package:immo/widgets/app_logo.dart';
import 'package:immo/models/merchant_hours.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MerchantServiceHoursScreen extends StatefulWidget {
  const MerchantServiceHoursScreen({Key? key}) : super(key: key);

  @override
  State<MerchantServiceHoursScreen> createState() => _MerchantServiceHoursScreenState();
}

class _MerchantServiceHoursScreenState extends State<MerchantServiceHoursScreen> {
  late MerchantServiceConfig _config;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString('merchant_service_config');
      
      if (configJson != null) {
        _config = MerchantServiceConfig.fromJson(jsonDecode(configJson));
      } else {
        _config = MerchantServiceConfig.getDefault();
      }
    } catch (e) {
      _config = MerchantServiceConfig.getDefault();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveConfig() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('merchant_service_config', jsonEncode(_config.toJson()));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration enregistrée avec succès'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'enregistrement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isLoading = false);
  }

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

  @override
  Widget build(BuildContext context) {
    final isCurrentlyOpen = _config.isCurrentlyOpen();
    
    return Scaffold(
      appBar: AppBarWithLogo(
        title: 'Heures de service',
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF7F8FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut de la boutique
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrentlyOpen ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCurrentlyOpen ? Colors.green.shade300 : Colors.red.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isCurrentlyOpen ? Icons.check_circle : Icons.cancel,
                          color: isCurrentlyOpen ? Colors.green.shade700 : Colors.red.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isCurrentlyOpen ? 'Boutique ouverte' : 'Boutique fermée',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isCurrentlyOpen ? Colors.green.shade900 : Colors.red.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isCurrentlyOpen
                                    ? 'Votre boutique est actuellement ouverte'
                                    : 'Votre boutique est actuellement fermée',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isCurrentlyOpen ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 14),
                  
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
                              ? 'Votre boutique est mise hors ligne manuellement'
                              : 'Votre boutique suit les heures programmées',
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
                              onChanged: (value) {
                                setState(() {
                                  _config = _config.copyWith(isManuallyOffline: !value);
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _config.isManuallyOffline ? 'Hors ligne' : 'En ligne',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
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
                    return _DayHoursCard(
                      dayHours: dayHours,
                      onEnabledChanged: (enabled) {
                        setState(() {
                          final index = _config.hours.indexWhere((h) => h.day == dayHours.day);
                          if (index != -1) {
                            final updatedHours = List<MerchantHours>.from(_config.hours);
                            updatedHours[index] = updatedHours[index].copyWith(isEnabled: enabled);
                            _config = _config.copyWith(hours: updatedHours);
                          }
                        });
                      },
                      onOpenTimeTap: () => _selectTime(context, dayHours, true),
                      onCloseTimeTap: () => _selectTime(context, dayHours, false),
                      isValid: isValid,
                    );
                  }).toList(),
                  
                  const SizedBox(height: 18),
                  
                  // Bouton de sauvegarde
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Vérifier que toutes les heures sont valides
                        final allValid = _config.hours.every((h) => _validateHours(h));
                        if (!allValid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez corriger les heures invalides (heure d\'ouverture doit être avant l\'heure de fermeture)'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        _saveConfig();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Enregistrer les modifications',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                ],
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
  final bool isValid;

  const _DayHoursCard({
    required this.dayHours,
    required this.onEnabledChanged,
    required this.onOpenTimeTap,
    required this.onCloseTimeTap,
    required this.isValid,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayHours.day,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: dayHours.isEnabled,
                  onChanged: onEnabledChanged,
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
                    onTap: onOpenTimeTap,
                    icon: Icons.access_time,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TimeButton(
                    label: 'Fermeture',
                    time: dayHours.closeTime ?? '18:00',
                    onTap: onCloseTimeTap,
                    icon: Icons.access_time,
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
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Fermé ce jour',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

