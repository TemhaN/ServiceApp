import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FullScreenImage extends StatefulWidget {
  final String imageUrl;
  final bool isNetworkImage;
  final String heroTag;

  const FullScreenImage({
    Key? key,
    required this.imageUrl,
    this.isNetworkImage = true,
    required this.heroTag,
  }) : super(key: key);

  @override
  _FullScreenImageState createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<FullScreenImage>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final newScale = scale >= 2.0 ? 1.0 : 2.0;

    final position = _doubleTapDetails!.localPosition;
    final Matrix4 endMatrix = Matrix4.identity()
      ..translate(-position.dx * (newScale - 1), -position.dy * (newScale - 1))
      ..scale(newScale);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // Закрытие при нажатии в любом месте
      },
      child: Stack(
        children: [
          // Размытие фона
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Усиленное размытие
              child: Container(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
          ),
          // Основное содержимое
          SafeArea(
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                boundaryMargin: const EdgeInsets.all(100),
                panEnabled: true,
                scaleEnabled: true,
                onInteractionEnd: (_) {
                  _animationController.reset();
                },
                child: GestureDetector(
                  onDoubleTapDown: (details) => _doubleTapDetails = details,
                  onDoubleTap: _handleDoubleTap,
                  // Убрано onTap, чтобы нажатие на изображение закрывало экран
                  child: Hero(
                    tag: widget.heroTag,
                    child: widget.isNetworkImage
                        ? CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7B3BEA),
                          strokeWidth: 3,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                      ),
                    )
                        : Image.asset(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                      const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Кнопка закрытия
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          // Индикатор загрузки
          if (widget.isNetworkImage)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.none,
                placeholder: (context, url) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const CircularProgressIndicator(
                      color: Color(0xFF7B3BEA),
                      strokeWidth: 3,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox.shrink(),
                imageBuilder: (context, imageProvider) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}