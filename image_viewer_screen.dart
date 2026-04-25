import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';

class ImageViewerScreen extends StatefulWidget {
  final String url;
  final String title;

  const ImageViewerScreen({super.key, required this.url, required this.title});

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  bool _showAppBar = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black.withOpacity(0.5),
              title: Text(
                widget.title,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _showAppBar = !_showAppBar),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 6.0,
            child: CachedNetworkImage(
              imageUrl: widget.url,
              fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
              errorWidget: (_, __, ___) => const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image_rounded, color: AppTheme.textSecondary, size: 64),
                  SizedBox(height: 8),
                  Text('Failed to load image', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
