import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String propertyDetail = '/property-detail';
  static const String addProperty = '/add-property';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String payments = '/payments';
}

class AppAssets {
  static const String backgroundImage = 'assets/images/logo-trans.png';
  static const String house1 = 'assets/images/house1.jpg';
  static const String house2 = 'assets/images/house2.jpg';
  static const String house3 = 'assets/images/house3.jpg';
}

class AppColors {
  static const Color primary = Color(0xFF2B2D42);
  static const Color buttonColor = Color(0xFF2B2D42);
  static const Color secondary = Color(0xFF8D99AE);
  static const Color accent = Color(0xFFEF233C);
  static const Color background = Color(0xFFF8F9FA);
  static const Color text = Color(0xFF2B2D42);
  static const Color textLight = Color(0xFF8D99AE);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFFFA000);
}

class AppStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    color: AppColors.textLight,
  );
}
