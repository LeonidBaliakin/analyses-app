import 'package:material_ui/material_ui.dart';

/// Layout-only anchors. Features publish stable visual IDs without depending on
/// the tour, navigation or medical services.
class SpotlightAnchors {
  final _keys = <String, GlobalKey>{};
  GlobalKey keyFor(String id) => _keys.putIfAbsent(id, GlobalKey.new);
  Future<void> ensureVisible(String id) async {
    final context = _keys[id]?.currentContext;
    if (context == null) return;
    await Scrollable.ensureVisible(
      context,
      alignment: .5,
      duration: Duration.zero,
    );
  }

  Rect? rectFor(String id) {
    final box = _keys[id]?.currentContext?.findRenderObject();
    return box is RenderBox && box.attached && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
  }
}

class SpotlightScope extends InheritedWidget {
  const SpotlightScope({
    required this.anchors,
    required super.child,
    super.key,
  });
  final SpotlightAnchors anchors;
  static SpotlightAnchors? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SpotlightScope>()?.anchors;
  @override
  bool updateShouldNotify(SpotlightScope oldWidget) =>
      anchors != oldWidget.anchors;
}

class SpotlightAnchor extends StatelessWidget {
  const SpotlightAnchor({required this.id, required this.child, super.key});
  final String id;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final anchors = SpotlightScope.maybeOf(context);
    return anchors == null
        ? child
        : KeyedSubtree(key: anchors.keyFor(id), child: child);
  }
}
