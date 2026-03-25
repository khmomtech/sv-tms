import 'package:flutter/material.dart';

class LoadingPlaceholder extends StatelessWidget {
  final double height;
  final double width;
  const LoadingPlaceholder(
      {this.height = 80, this.width = double.infinity, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
