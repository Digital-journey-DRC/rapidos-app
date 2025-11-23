import 'package:flutter/material.dart';

/// Modèle de données pour les heures de service du marchand
class MerchantHours {
  final String day;
  final bool isEnabled;
  final String? openTime;
  final String? closeTime;

  MerchantHours({
    required this.day,
    this.isEnabled = false,
    this.openTime,
    this.closeTime,
  });

  MerchantHours copyWith({
    String? day,
    bool? isEnabled,
    String? openTime,
    String? closeTime,
  }) {
    return MerchantHours(
      day: day ?? this.day,
      isEnabled: isEnabled ?? this.isEnabled,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'isEnabled': isEnabled,
      'openTime': openTime,
      'closeTime': closeTime,
    };
  }

  factory MerchantHours.fromJson(Map<String, dynamic> json) {
    // L'API utilise "jour" (en minuscules) et "estOuvert"
    // Convertir "jour" en format avec première lettre majuscule pour l'affichage
    String day = json['jour']?.toString() ?? json['day']?.toString() ?? '';
    if (day.isNotEmpty) {
      day = day[0].toUpperCase() + day.substring(1).toLowerCase();
    }
    
    // L'API peut retourner les heures avec des secondes (HH:MM:SS) ou sans (HH:MM)
    String? parseTime(dynamic timeValue) {
      if (timeValue == null) return null;
      final timeStr = timeValue.toString();
      if (timeStr.contains(':')) {
        // Prendre seulement HH:MM
        final parts = timeStr.split(':');
        if (parts.length >= 2) {
          return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
        }
      }
      return timeStr;
    }
    
    final estOuvert = json['estOuvert'] ?? json['isEnabled'] ?? false;
    
    return MerchantHours(
      day: day,
      isEnabled: estOuvert is bool ? estOuvert : (estOuvert.toString().toLowerCase() == 'true'),
      openTime: parseTime(json['heureOuverture'] ?? json['openTime']),
      closeTime: parseTime(json['heureFermeture'] ?? json['closeTime']),
    );
  }

  /// Convertit le jour en format API (minuscules)
  String get jourApi {
    return day.toLowerCase();
  }
}

/// Modèle pour la configuration complète des heures de service
class MerchantServiceConfig {
  final List<MerchantHours> hours;
  final bool isManuallyOffline;

  MerchantServiceConfig({
    required this.hours,
    this.isManuallyOffline = false,
  });

  MerchantServiceConfig copyWith({
    List<MerchantHours>? hours,
    bool? isManuallyOffline,
  }) {
    return MerchantServiceConfig(
      hours: hours ?? this.hours,
      isManuallyOffline: isManuallyOffline ?? this.isManuallyOffline,
    );
  }

  /// Vérifier si la boutique est actuellement ouverte
  bool isCurrentlyOpen() {
    if (isManuallyOffline) return false;

    final now = DateTime.now();
    final currentDay = _getDayName(now.weekday);
    final currentTime = TimeOfDay.fromDateTime(now);

    final dayHours = hours.firstWhere(
      (h) => h.day == currentDay,
      orElse: () => MerchantHours(day: currentDay, isEnabled: false),
    );

    if (!dayHours.isEnabled || dayHours.openTime == null || dayHours.closeTime == null) {
      return false;
    }

    final openTime = _parseTime(dayHours.openTime!);
    final closeTime = _parseTime(dayHours.closeTime!);

    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final openMinutes = openTime.hour * 60 + openTime.minute;
    final closeMinutes = closeTime.hour * 60 + closeTime.minute;

    return currentMinutes >= openMinutes && currentMinutes <= closeMinutes;
  }

  String _getDayName(int weekday) {
    const days = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    final dayName = days[weekday - 1];
    // Retourner avec première lettre majuscule pour l'affichage
    return dayName[0].toUpperCase() + dayName.substring(1);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hours': hours.map((h) => h.toJson()).toList(),
      'isManuallyOffline': isManuallyOffline,
    };
  }

  factory MerchantServiceConfig.fromJson(Map<String, dynamic> json) {
    return MerchantServiceConfig(
      hours: (json['hours'] as List)
          .map((h) => MerchantHours.fromJson(h))
          .toList(),
      isManuallyOffline: json['isManuallyOffline'] ?? false,
    );
  }

  /// Créer une configuration par défaut
  /// Par défaut, le contrôle manuel est actif (suit les heures) donc isManuallyOffline = false
  static MerchantServiceConfig getDefault() {
    return MerchantServiceConfig(
      hours: [
        MerchantHours(day: 'Lundi', isEnabled: true, openTime: '08:00', closeTime: '18:00'),
        MerchantHours(day: 'Mardi', isEnabled: true, openTime: '08:00', closeTime: '18:00'),
        MerchantHours(day: 'Mercredi', isEnabled: true, openTime: '08:00', closeTime: '18:00'),
        MerchantHours(day: 'Jeudi', isEnabled: true, openTime: '08:00', closeTime: '18:00'),
        MerchantHours(day: 'Vendredi', isEnabled: true, openTime: '08:00', closeTime: '18:00'),
        MerchantHours(day: 'Samedi', isEnabled: true, openTime: '09:00', closeTime: '17:00'),
        MerchantHours(day: 'Dimanche', isEnabled: false),
      ],
      isManuallyOffline: false, // Par défaut, suit les heures (contrôle manuel actif)
    );
  }

  /// Convertit depuis les données API
  static MerchantServiceConfig fromApiHoraires(List<dynamic> horairesJson) {
    final Map<String, MerchantHours> hoursMap = {};
    
    // Jours de la semaine en ordre
    const daysOrder = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];
    
    // Convertir les horaires de l'API
    for (var horaireJson in horairesJson) {
      final horaire = MerchantHours.fromJson(horaireJson);
      hoursMap[horaire.jourApi] = horaire;
    }
    
    // Créer la liste complète avec tous les jours
    final hours = daysOrder.map((dayApi) {
      final dayDisplay = dayApi[0].toUpperCase() + dayApi.substring(1);
      if (hoursMap.containsKey(dayApi)) {
        return hoursMap[dayApi]!;
      } else {
        return MerchantHours(day: dayDisplay, isEnabled: false);
      }
    }).toList();
    
    return MerchantServiceConfig(
      hours: hours,
      isManuallyOffline: false, // Ce champ n'est pas dans l'API, on le gère localement
    );
  }
}

