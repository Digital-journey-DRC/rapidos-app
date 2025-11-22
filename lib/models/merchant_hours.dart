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
    return MerchantHours(
      day: json['day'],
      isEnabled: json['isEnabled'] ?? false,
      openTime: json['openTime'],
      closeTime: json['closeTime'],
    );
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
    const days = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[weekday - 1];
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
      isManuallyOffline: false,
    );
  }
}

