import 'dart:math' as math;
import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:material_ui/material_ui.dart';

abstract final class AppLayout {
  static const railBreakpoint = 760.0;
  static const extendedRailBreakpoint = 1100.0;
  static const contentWidth = 1180.0;
  static const spacing = 24.0;
}

/// Avoids physical hinges and half-open folds; a flat fold uses the full window.
/// The child stays in the same element position across display changes.
class UnobstructedPane extends StatelessWidget {
  const UnobstructedPane({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    var pane = Offset.zero & media.size;
    for (final feature in media.displayFeatures) {
      final bounds = feature.bounds;
      final separates =
          feature.type == DisplayFeatureType.hinge ||
          (feature.type == DisplayFeatureType.fold &&
              feature.state == DisplayFeatureState.postureHalfOpened);
      if (!separates) continue;
      if (bounds.height >= pane.height &&
          bounds.left > pane.left &&
          bounds.right < pane.right) {
        final left = Rect.fromLTRB(
          pane.left,
          pane.top,
          bounds.left,
          pane.bottom,
        );
        final right = Rect.fromLTRB(
          bounds.right,
          pane.top,
          pane.right,
          pane.bottom,
        );
        pane = left.width >= right.width ? left : right;
      } else if (bounds.width >= pane.width &&
          bounds.top > pane.top &&
          bounds.bottom < pane.bottom) {
        final top = Rect.fromLTRB(pane.left, pane.top, pane.right, bounds.top);
        final bottom = Rect.fromLTRB(
          pane.left,
          bounds.bottom,
          pane.right,
          pane.bottom,
        );
        pane = top.height >= bottom.height ? top : bottom;
      }
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        pane.left,
        pane.top,
        math.max(0, media.size.width - pane.right),
        math.max(0, media.size.height - pane.bottom),
      ),
      // Descendants (including dialog routes) already live in this pane.
      // Remove the consumed feature so they do not avoid the hinge twice.
      child: MediaQuery(data: media.removeDisplayFeatures(pane), child: child),
    );
  }
}

class PageContent extends StatelessWidget {
  const PageContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.contentWidth),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppLayout.spacing),
        child: SizedBox(width: double.infinity, child: child),
      ),
    ),
  );
}
