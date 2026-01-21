import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants.dart';
import '../cubit/auth_cubit.dart';
import '../screens/dashboard/setting_screen.dart';

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

/// Widget réutilisable pour le bouton de profil dans l'AppBar
class ProfileButton extends StatelessWidget {
  const ProfileButton({Key? key}) : super(key: key);

  /// Vérifie si on est actuellement dans l'écran de profil
  bool _isInProfileScreen(BuildContext context) {
    // Vérifier via la route actuelle
    final route = ModalRoute.of(context);
    if (route != null) {
      // Vérifier le type du widget dans la route
      final builder = route.settings.arguments;
      if (builder is Widget && builder.runtimeType.toString().contains('SettingScreen')) {
        return true;
      }
      
      // Vérifier aussi le nom de la route
      final routeName = route.settings.name ?? '';
      if (routeName.contains('SettingScreen') || routeName.contains('setting') || routeName.contains('Setting')) {
        return true;
      }
      
      // Vérifier le widget actuel dans l'arbre
      try {
        final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
        if (scaffold != null) {
          // Si on trouve un AppBarWithLogo avec le titre "Paramètres du compte", on est probablement dans SettingScreen
          final appBar = scaffold.appBar;
          if (appBar is AppBar) {
            final title = appBar.title;
            if (title is Text && title.data == 'Paramètres du compte') {
              return true;
            }
          }
        }
      } catch (e) {
        // Ignorer les erreurs
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Ne pas afficher le bouton si on est déjà dans l'écran de profil
    if (_isInProfileScreen(context)) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthSuccess && state.user != null && state.user!['media'] != null) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  backgroundImage: NetworkImage(state.user!['media']),
                  onBackgroundImageError: (_, __) {},
                ),
              ),
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingScreen(),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        }
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
  final bool showProfileButton;

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
    this.showProfileButton = true,
  }) : super(
          key: key,
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Builder(
            builder: (context) {
              // Combiner les actions personnalisées avec le bouton de profil
              List<Widget> finalActions = [];
              if (actions != null) {
                finalActions.addAll(actions);
              }
              if (showProfileButton) {
                finalActions.add(const ProfileButton());
              }
              
              return AppBar(
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
                actions: finalActions,
                centerTitle: centerTitle,
                backgroundColor: backgroundColor,
                elevation: elevation,
                iconTheme: IconThemeData(color: useWhiteLogo ? Colors.white : AppColors.primary),
              );
            },
          ),
        );
}

