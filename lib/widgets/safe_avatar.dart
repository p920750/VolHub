import 'package:flutter/material.dart';

class SafeAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;

  const SafeAvatar({
    Key? key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: ClipOval(
        child: Image.network(
          imageUrl!,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(context);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Text(
        initials,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8,
        ),
      ),
    );
  }
}
