import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class StoreService {
  // URLs des stores - à modifier selon votre application
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.rapidos.app';
  static const String _appStoreUrl = 'https://apps.apple.com/app/rapidos/id123456789';
  
  // URLs alternatives pour le développement
  static const String _playStoreDevUrl = 'https://play.google.com/store/apps/details?id=com.rapidos.app.dev';
  static const String _appStoreDevUrl = 'https://apps.apple.com/app/rapidos-dev/id123456789';
  
  /// Ouvre le store approprié selon la plateforme
  static Future<void> openStore({bool isDev = false}) async {
    String url;
    
    if (Platform.isAndroid) {
      url = isDev ? _playStoreDevUrl : _playStoreUrl;
    } else if (Platform.isIOS) {
      url = isDev ? _appStoreDevUrl : _appStoreUrl;
    } else {
      print('Plateforme non supportée pour l\'ouverture du store');
      return;
    }
    
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('Impossible d\'ouvrir l\'URL: $url');
      }
    } catch (e) {
      print('Erreur lors de l\'ouverture du store: $e');
    }
  }
  
  /// Retourne l'URL du store approprié
  static String getStoreUrl({bool isDev = false}) {
    if (Platform.isAndroid) {
      return isDev ? _playStoreDevUrl : _playStoreUrl;
    } else if (Platform.isIOS) {
      return isDev ? _appStoreDevUrl : _appStoreUrl;
    } else {
      return '';
    }
  }
  
  /// Vérifie si l'URL du store peut être ouverte
  static Future<bool> canOpenStore({bool isDev = false}) async {
    String url = getStoreUrl(isDev: isDev);
    if (url.isEmpty) return false;
    
    try {
      return await canLaunchUrl(Uri.parse(url));
    } catch (e) {
      return false;
    }
  }
}
