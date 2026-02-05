import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/expansion_tile_parts.dart';

/// An adaptive expansion tile that provides platform-appropriate styling.
///
/// Uses [ExpansionTile] as base with platform-specific adjustments.
class AdaptiveExpansionTile extends StatelessWidget
    with AdaptiveExpansionTileMixin {
  final Widget title;
  final Widget? leading;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;

  const AdaptiveExpansionTile({
    super.key,
    required this.title,
    this.leading,
    required this.children,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return buildCupertino(context);
    }

    return buildMaterial(context);
  }
}

mixin AdaptiveExpansionTileMixin {
  Widget buildCupertino(BuildContext context) {
    final tile = this as AdaptiveExpansionTile;
    return _CupertinoExpansionTileWidget(
      title: tile.title,
      leading: tile.leading,
      children: tile.children,
      onExpansionChanged: tile.onExpansionChanged,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final tile = this as AdaptiveExpansionTile;
    return _MaterialExpansionTileWidget(
      title: tile.title,
      leading: tile.leading,
      children: tile.children,
      onExpansionChanged: tile.onExpansionChanged,
    );
  }
}
