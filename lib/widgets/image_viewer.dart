// ignore_for_file: unnecessary_this

import 'package:flutter/material.dart';

class ImageViewerWidget extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Border? border;
  final BoxFit? imageFit;
  final double? marginLeft;
  static const String defaultImageUrl = 'https://ability2access.com/wp-content/plugins/ecommerce-product-catalog/img/no-default-thumbnail.png';

  const ImageViewerWidget({
    Key? key,
    required this.url,
    this.width = 100,
    this.height = 100,
    this.borderRadius,
    this.border,
    this.imageFit,
    this.marginLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: Image.network(
        url.isEmpty ? defaultImageUrl : url,
        width: width,
        height: height,
        fit: imageFit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Image.network(
            defaultImageUrl,
            width: width,
            height: height,
            fit: imageFit ?? BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  borderRadius: borderRadius, 
                  border: border ?? Border.all(color: Colors.transparent, width: 1),
                ),
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: width * 0.5,
                ),
              );
            },
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ShimmerLoading(
            width: width,
            height: height,
            borderRadius: borderRadius,
            border: border,
            marginLeft: marginLeft,
          );
        },
      ),
    );
  }
}

class ShimmerLoading extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Border? border;
  final double? marginLeft;

  const ShimmerLoading({
    required this.width,
    required this.height,
    this.borderRadius,
    this.border,
    this.marginLeft,
  });

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();

    _animation = Tween<double>(begin: -2.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      margin: EdgeInsets.only(right: widget.marginLeft ?? 0),
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        border: widget.border ?? Border.all(color: Colors.transparent, width: 1),
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              gradient: LinearGradient(
                begin: Alignment(_animation.value - 1, 0),
                end: Alignment(_animation.value + 1, 0),
                colors: const [
                  Color(0xFFEBEBF4),
                  Color(0xFFF4F4F4),
                  Color(0xFFEBEBF4),
                ],
                stops: const [0.1, 0.3, 0.4],
              ),
            ),
          );
        },
      ),
    );
  }
}
