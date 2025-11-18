import 'package:flutter/material.dart';
import '../constants.dart';

/// Widget réutilisable pour afficher le logo de l'application
/// avec un dimensionnement responsive et un alignement cohérent
class AppLogo extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;
  final bool useWhiteLogo;

  const AppLogo({
    Key? key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.color,
    this.useWhiteLogo = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dimensionnement responsive par défaut
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultSize = screenWidth < 600 ? 60.0 : 80.0;
    
    final logoWidth = width ?? defaultSize;
    final logoHeight = height ?? defaultSize;
    
    return Image.asset(
      useWhiteLogo ? AppAssets.logoWhite : AppAssets.logo,
      width: logoWidth,
      height: logoHeight,
      fit: fit,
      color: color,
      errorBuilder: (context, error, stackTrace) {
        // Fallback si l'image ne charge pas
        return Container(
          width: logoWidth,
          height: logoHeight,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.shopping_bag,
            size: logoWidth * 0.6,
            color: AppColors.primary,
          ),
        );
      },
    );
  }
}

/// Widget helper pour créer un AppBar avec le logo
class AppBarWithLogo extends PreferredSize {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final double elevation;
  final bool useWhiteLogo;
  final bool automaticallyImplyLeading;

  AppBarWithLogo({
    Key? key,
    this.title,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.backgroundColor = Colors.white,
    this.elevation = 0,
    this.useWhiteLogo = false,
    this.automaticallyImplyLeading = true,
  }) : super(
          key: key,
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            leading: leading,
            automaticallyImplyLeading: automaticallyImplyLeading,
            title: centerTitle && title != null
                ? Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: useWhiteLogo ? Colors.white : Colors.black,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppLogo(useWhiteLogo: useWhiteLogo),
                      if (title != null) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: useWhiteLogo ? Colors.white : Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
            actions: actions,
            centerTitle: centerTitle,
            backgroundColor: backgroundColor,
            elevation: elevation,
            iconTheme: IconThemeData(color: useWhiteLogo ? Colors.white : AppColors.primary),
          ),
        );
}

