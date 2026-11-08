import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    this.photoUrl,
    this.radius = 24,
    this.selected = false,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double radius;
  final bool selected;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      ClipOval(
        child: SizedBox.square(
          dimension: radius * 2,
          child: photoUrl == null || photoUrl!.trim().isEmpty
              ? _fallback(context)
              : Image.network(
                  photoUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _fallback(context),
                ),
        ),
      ),
      if (selected)
        Positioned(
          right: -2,
          bottom: -2,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Padding(
              padding: EdgeInsets.all(radius >= 40 ? 5 : 3),
              child: Icon(
                Icons.check,
                size: radius >= 40 ? 18 : 13,
                color: Colors.white,
              ),
            ),
          ),
        ),
    ],
  );

  Widget _fallback(BuildContext context) => ColoredBox(
    color: AppColors.secondaryLight,
    child: Center(
      child: Text(
        _initials(name),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.65,
        ),
      ),
    ),
  );

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty || value.trim() == 'Cadastro Pendente') return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return '$first$last'.toUpperCase();
  }
}
