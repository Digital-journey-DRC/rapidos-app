import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../constants.dart';

/// Widget de chargement professionnel pour e-commerce utilisant Lottie
/// Animation optimisée et rapide pour une meilleure UX
class EcommerceLoading extends StatelessWidget {
  final double? size;
  final String? message;
  final Color? color;
  final bool useNetwork;

  const EcommerceLoading({
    Key? key,
    this.size,
    this.message,
    this.color,
    this.useNetwork = false,
  }) : super(key: key);

  /// Loading simple sans message
  const EcommerceLoading.simple({
    Key? key,
    double? size,
    Color? color,
  }) : this(
          key: key,
          size: size,
          color: color,
        );

  /// Loading avec message
  const EcommerceLoading.withMessage({
    Key? key,
    required String message,
    double? size,
    Color? color,
  }) : this(
          key: key,
          message: message,
          size: size,
          color: color,
        );

  /// Loading inline (petit, pour les boutons)
  const EcommerceLoading.inline({
    Key? key,
    Color? color,
  }) : this(
          key: key,
          size: 20,
          color: color,
        );

  /// Loading overlay (plein écran)
  const EcommerceLoading.overlay({
    Key? key,
    String? message,
    Color? color,
  }) : this(
          key: key,
          size: 120,
          message: message,
          color: color,
        );

  @override
  Widget build(BuildContext context) {
    final loadingSize = size ?? 80.0;
    final loadingColor = color ?? AppColors.primary;

    // Animation Lottie inline (shopping bag/cart animation)
    // Si le fichier local n'existe pas, on utilise une URL en ligne
    Widget lottieWidget;

    if (useNetwork) {
      // Utiliser une animation Lottie depuis une URL
      lottieWidget = Lottie.network(
        'https://lottie.host/embed/8c5a3f4e-3f4e-4c5a-9b2d-1a2b3c4d5e6f/xyz123.json',
        width: loadingSize,
        height: loadingSize,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLoading(loadingSize, loadingColor);
        },
      );
    } else {
      // Essayer de charger depuis les assets locaux
      try {
        lottieWidget = Lottie.asset(
          'assets/lottie/shopping_loading.json',
          width: loadingSize,
          height: loadingSize,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackLoading(loadingSize, loadingColor);
          },
        );
      } catch (e) {
        lottieWidget = _buildFallbackLoading(loadingSize, loadingColor);
      }
    }

    if (message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          lottieWidget,
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Center(child: lottieWidget);
  }

  /// Fallback vers une animation simple si Lottie n'est pas disponible
  Widget _buildFallbackLoading(double size, Color color) {
    return _FallbackLoading(size: size, color: color);
  }
}

/// Widget de fallback avec animation de rotation
class _FallbackLoading extends StatefulWidget {
  final double size;
  final Color color;

  const _FallbackLoading({
    Key? key,
    required this.size,
    required this.color,
  }) : super(key: key);

  @override
  State<_FallbackLoading> createState() => _FallbackLoadingState();
}

class _FallbackLoadingState extends State<_FallbackLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Cercle de base
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.1),
            ),
          ),
          // Animation de rotation avec icône shopping
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * 3.14159,
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: widget.size * 0.5,
                  color: widget.color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Widget de chargement pour les images
class EcommerceImageLoading extends StatelessWidget {
  final double? size;
  final Color? color;

  const EcommerceImageLoading({
    Key? key,
    this.size,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingSize = size ?? 60.0;
    final loadingColor = color ?? AppColors.primary;

    return Center(
      child: SizedBox(
        width: loadingSize,
        height: loadingSize,
        child: Lottie.asset(
          'assets/lottie/shopping_loading.json',
          width: loadingSize,
          height: loadingSize,
          fit: BoxFit.contain,
          repeat: true,
          errorBuilder: (context, error, stackTrace) {
            return CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(loadingColor),
            );
          },
        ),
      ),
    );
  }
}

