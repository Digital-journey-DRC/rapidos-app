import 'package:flutter/material.dart';

/// Custom skeleton implementation to fix compatibility issues with newer Flutter versions
/// Based on the original skeletons package but with fixes for Theme.backgroundColor

class SkeletonAvatarStyle {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? color;
  final bool isCircle;
  final BoxShape shape;

  const SkeletonAvatarStyle({
    this.width = 48.0,
    this.height = 48.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.color,
    this.isCircle = false,
    this.shape = BoxShape.rectangle,
  });
}

class SkeletonLineStyle {
  final double height;
  final double width;
  final BorderRadius borderRadius;
  final AlignmentGeometry alignment;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const SkeletonLineStyle({
    this.height = 12.0,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(4.0)),
    this.alignment = Alignment.centerLeft,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
  });
}

class SkeletonItem extends StatelessWidget {
  final Widget child;

  const SkeletonItem({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class SkeletonAvatar extends StatelessWidget {
  final SkeletonAvatarStyle style;

  const SkeletonAvatar({
    Key? key,
    this.style = const SkeletonAvatarStyle(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: style.width,
      height: style.height,
      decoration: BoxDecoration(
        // Using Theme.scaffoldBackgroundColor instead of Theme.backgroundColor
        color: style.color ?? Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: style.isCircle ? null : style.borderRadius,
        shape: style.isCircle ? BoxShape.circle : style.shape,
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  final SkeletonLineStyle style;

  const SkeletonLine({
    Key? key,
    this.style = const SkeletonLineStyle(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: style.padding,
      alignment: style.alignment,
      child: Container(
        width: style.width,
        height: style.height,
        decoration: BoxDecoration(
          // Using Theme.scaffoldBackgroundColor instead of Theme.backgroundColor
          color: style.color ?? Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: style.borderRadius,
        ),
      ),
    );
  }
}

class SkeletonParagraph extends StatelessWidget {
  final int lines;
  final SkeletonLineStyle style;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const SkeletonParagraph({
    Key? key,
    this.lines = 3,
    this.style = const SkeletonLineStyle(),
    this.padding = const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (index) => Column(
            children: [
              SkeletonLine(
                style: style,
              ),
              if (index != lines - 1) SizedBox(height: spacing),
            ],
          ),
        ),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final SkeletonAvatarStyle? leadingStyle;
  final bool hasTitle;
  final SkeletonLineStyle? titleStyle;
  final bool hasSubtitle;
  final SkeletonLineStyle? subtitleStyle;
  final EdgeInsetsGeometry padding;
  final double verticalSpacing;

  const SkeletonListTile({
    Key? key,
    this.hasLeading = true,
    this.leadingStyle,
    this.hasTitle = true,
    this.titleStyle,
    this.hasSubtitle = false,
    this.subtitleStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.verticalSpacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (hasLeading) ...[
            SkeletonAvatar(
              style: leadingStyle ?? const SkeletonAvatarStyle(),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasTitle)
                  SkeletonLine(
                    style: titleStyle ?? const SkeletonLineStyle(),
                  ),
                if (hasTitle && hasSubtitle) SizedBox(height: verticalSpacing),
                if (hasSubtitle)
                  SkeletonLine(
                    style: subtitleStyle ??
                        const SkeletonLineStyle(width: 0.6, height: 10),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Additional reusable skeleton components for different screens

/// Button with loading skeleton
class SkeletonButton extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? color;

  const SkeletonButton({
    Key? key,
    this.width = 120.0,
    this.height = 36.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.primaryContainer,
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SkeletonLine(
          style: SkeletonLineStyle(
            height: height * 0.4,
            width: width * 0.7,
            borderRadius: BorderRadius.circular(4),
            color: Colors.white.withOpacity(0.2),
          ),
        ),
      ),
    );
  }
}

/// Card skeleton for property listings
class SkeletonPropertyCard extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonPropertyCard({
    Key? key,
    this.width = 300.0,
    this.height = 200.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12.0)),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image part
          SkeletonAvatar(
            style: SkeletonAvatarStyle(
              width: width,
              height: height * 0.6,
              borderRadius: BorderRadius.only(
                topLeft: borderRadius.topLeft,
                topRight: borderRadius.topRight,
              ),
            ),
          ),
          // Content part
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(
                  style: SkeletonLineStyle(
                    width: width * 0.7,
                    height: 16,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                SkeletonLine(
                  style: SkeletonLineStyle(
                    width: width * 0.5,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                SkeletonLine(
                  style: SkeletonLineStyle(
                    width: width * 0.3,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment card skeleton
class SkeletonPaymentCard extends StatelessWidget {
  final double width;
  
  const SkeletonPaymentCard({
    Key? key,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reference and status row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reference skeleton
                SkeletonLine(
                  style: SkeletonLineStyle(
                    width: 150,
                    height: 16,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Status tag skeleton
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SkeletonLine(
                    style: SkeletonLineStyle(
                      width: 60,
                      height: 12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Payment method and amount row
            Row(
              children: [
                // Payment method icon skeleton
                SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                // Payment amount and method skeletons
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        width: 120,
                        height: 18,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 5),
                    SkeletonLine(
                      style: SkeletonLineStyle(
                        width: 160,
                        height: 14,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Date and comment skeletons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonLine(
                  style: SkeletonLineStyle(
                    width: 180,
                    height: 13,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SkeletonAvatar(
                  style: SkeletonAvatarStyle(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
