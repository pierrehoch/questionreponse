import 'package:flutter/material.dart';

/// App logo: a flat rounded tile carrying the ballot icon.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(
          Icons.how_to_vote_rounded,
          size: size * 0.5,
          color: colorScheme.onPrimary,
        ),
      ),
    );
  }
}
