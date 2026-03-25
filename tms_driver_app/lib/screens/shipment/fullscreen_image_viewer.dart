import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullscreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final bool isLocal;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.isLocal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: PhotoView(
          imageProvider: isLocal
              ? FileImage(File(imageUrl))
              : NetworkImage(imageUrl) as ImageProvider,
          loadingBuilder: (context, _) => const CircularProgressIndicator(),
          errorBuilder: (context, _, __) =>
              const Icon(Icons.broken_image, color: Colors.white),
        ),
      ),
    );
  }
}
