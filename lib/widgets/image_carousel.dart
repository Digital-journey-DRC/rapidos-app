import 'package:flutter/material.dart';

/// Widget carrousel d'images avec swipe, indicateurs et support responsive
class ImageCarousel extends StatefulWidget {
  final List<String> images;
  final double height;
  final BoxFit fit;
  final Color indicatorColor;
  final Color indicatorActiveColor;

  const ImageCarousel({
    Key? key,
    required this.images,
    this.height = 250,
    this.fit = BoxFit.cover,
    this.indicatorColor = Colors.grey,
    this.indicatorActiveColor = Colors.white,
  }) : super(key: key);

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        // PageView pour le swipe
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return _buildImage(widget.images[index]);
            },
          ),
        ),
        // Indicateurs (dots) en bas
        if (widget.images.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.images.length,
                (index) => _buildIndicator(index == _currentPage),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
      ),
      child: Image.network(
        imageUrl,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(
                Icons.image_not_supported,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.green,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? widget.indicatorActiveColor : widget.indicatorColor,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}


