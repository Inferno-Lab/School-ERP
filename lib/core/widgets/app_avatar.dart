import 'package:cached_network_image/cached_network_image.dart';
import 'package:edunest/core/utils/extensions.dart';
import 'package:edunest/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.name,
    this.url,
    this.size = 44,
    this.heroTag,
    super.key,
  });

  final String name;
  final String? url;
  final double size;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [context.app.gradientStart, context.app.gradientEnd],
        ),
      ),
      child: Text(
        Formatters.initials(name),
        style: context.text.titleSmall?.copyWith(color: Colors.white),
      ),
    );
    final image = url == null || url!.isEmpty
        ? fallback
        : ClipOval(
            child: CachedNetworkImage(
              imageUrl: url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) => fallback,
              errorWidget: (_, _, _) => fallback,
            ),
          );
    if (heroTag == null) return image;
    return Hero(tag: heroTag!, child: image);
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({required this.people, this.size = 32, super.key});

  final List<({String name, String? url})> people;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = people.take(4).toList();
    return SizedBox(
      width: size + (shown.length - 1) * (size * 0.65),
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * size * 0.65,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.colors.surface, width: 2),
                ),
                child: AppAvatar(name: shown[i].name, url: shown[i].url, size: size - 4),
              ),
            ),
        ],
      ),
    );
  }
}
