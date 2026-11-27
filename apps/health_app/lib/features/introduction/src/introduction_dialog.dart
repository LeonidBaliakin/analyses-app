import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'introduction_view_model.dart';

Future<void> showAppIntroduction(
  BuildContext context, {
  required Future<bool> Function() onComplete,
  required ValueChanged<IntroductionStep> onStepChanged,
  VoidCallback? onFinish,
  Future<void> Function(IntroductionStep)? onOpenStep,
}) async {
  final model = IntroductionViewModel(complete: onComplete);
  try {
    final closed = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) => _IntroductionDialog(
        model: model,
        onStepChanged: onStepChanged,
        onFinish: onFinish,
        onOpenStep: onOpenStep,
      ),
    );
    onStepChanged(model.step);
    await closed;
  } finally {
    model.dispose();
  }
}

class _IntroductionDialog extends StatefulWidget {
  const _IntroductionDialog({
    required this.model,
    required this.onStepChanged,
    this.onFinish,
    this.onOpenStep,
  });
  final IntroductionViewModel model;
  final ValueChanged<IntroductionStep> onStepChanged;
  final VoidCallback? onFinish;
  final Future<void> Function(IntroductionStep)? onOpenStep;
  @override
  State<_IntroductionDialog> createState() => _IntroductionDialogState();
}

class _IntroductionDialogState extends State<_IntroductionDialog> {
  Rect? _target;
  bool _aligning = false;
  void _locate() {
    final anchors = SpotlightScope.maybeOf(context), index = widget.model.index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.model.index != index) return;
      final rect = anchors?.rectFor(
        [
          'profile-1',
          'add-analysis',
          'analysis-history',
          'lab-search',
          'doctor-search',
          'share-access',
        ][index],
      );
      final box = context.findRenderObject();
      final local = rect == null || box is! RenderBox
          ? null
          : rect.shift(-box.localToGlobal(Offset.zero));
      if (local != null &&
          box is RenderBox &&
          !_aligning &&
          (local.bottom < 0 ||
              local.top > box.size.height ||
              local.top < 0 ||
              local.bottom > box.size.height)) {
        _aligning = true;
        anchors
            ?.ensureVisible(
              [
                'profile-1',
                'add-analysis',
                'analysis-history',
                'lab-search',
                'doctor-search',
                'share-access',
              ][index],
            )
            .whenComplete(() {
              _aligning = false;
              if (mounted) setState(() {});
            });
      }

      if (local != _target) setState(() => _target = local);
    });
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model, l = AppLocalizations.of(context);
      Widget accessibleAction(Widget child) =>
          MediaQuery.textScalerOf(context).scale(14) > 19
          ? Flexible(child: child)
          : child;
      _locate();
      final (title, body) = switch (m.step) {
        IntroductionStep.profile => (
          l.introductionProfileTitle,
          l.introductionProfileBody,
        ),
        IntroductionStep.reports => (
          l.introductionReportsTitle,
          l.introductionReportsBody,
        ),
        IntroductionStep.summary => (
          l.introductionSummaryTitle,
          l.introductionSummaryBody,
        ),
        IntroductionStep.laboratories => (
          l.introductionLabsTitle,
          l.introductionLabsBody,
        ),
        IntroductionStep.specialists => (
          l.introductionDoctorsTitle,
          l.introductionDoctorsBody,
        ),
        IntroductionStep.appointment => (l.tourShareTitle, l.tourShareBody),
      };
      Future<void> finish({bool add = false}) async {
        if (await m.finish() && context.mounted) {
          Navigator.of(context).pop();
          if (add) widget.onFinish?.call();
        }
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) finish();
        },
        child: LayoutBuilder(
          builder: (context, c) {
            final screen = Offset.zero & Size(c.maxWidth, c.maxHeight);
            final intersection = _target?.intersect(screen);
            final target = intersection == null || intersection.isEmpty
                ? null
                : intersection;
            final width = math.min(350.0, math.max(0, c.maxWidth - 16));
            final left = target == null
                ? (c.maxWidth - width) / 2
                : (target.center.dx - width / 2).clamp(
                    8.0,
                    math.max(8, c.maxWidth - width - 8),
                  );
            final top = target == null
                ? math.max(8, (c.maxHeight - 280) / 2)
                : target.top > c.maxHeight * .5
                ? math.max(8, target.top - 290)
                : math.min(target.bottom + 12, math.max(8, c.maxHeight - 290));
            final buttonStyle = OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF392E4C),
              side: const BorderSide(color: Color(0xFF7E6992)),
              minimumSize: const Size(0, 40),
            );
            return Material(
              key: const Key('app-introduction'),
              type: MaterialType.transparency,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipPath(
                      clipper: _SpotlightClipper(target?.inflate(5)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                        child: const ColoredBox(color: Color(0xB3100D1D)),
                      ),
                    ),
                  ),
                  if (target != null && !target.isEmpty)
                    Positioned.fromRect(
                      rect: target.inflate(5),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFFA45E),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: left.toDouble(),
                    top: top.toDouble(),
                    width: width.toDouble(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(
                          80,
                          math.min(c.maxHeight * .65, c.maxHeight - top - 8),
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF252034),
                          border: Border.all(color: const Color(0xFF625669)),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: DefaultTextStyle(
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(color: Colors.white, fontSize: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    l.introductionStep(
                                      m.index + 1,
                                      IntroductionStep.values.length,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFCEC4DA),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 7),
                                ExcludeSemantics(
                                  child: Row(
                                    children: [
                                      for (var i = 0; i < 6; i++)
                                        Container(
                                          width: 16,
                                          height: 3,
                                          margin: const EdgeInsets.only(
                                            right: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: i == m.index
                                                ? const Color(0xFFFFAC65)
                                                : const Color(0xFF766D81),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(body),
                                const SizedBox(height: 12),
                                if (widget.onOpenStep != null && m.index < 3)
                                  OutlinedButton(
                                    key: const Key('introduction-try'),
                                    style: buttonStyle,
                                    onPressed: m.isSaving
                                        ? null
                                        : () async {
                                            await widget.onOpenStep!(m.step);
                                            if (mounted) setState(() {});
                                          },
                                    child: Text(switch (m.step) {
                                      IntroductionStep.profile =>
                                        l.tourOpenBasics,
                                      IntroductionStep.reports =>
                                        l.tourOpenUpload,
                                      _ => l.historyOpen,
                                    }),
                                  ),
                                if (m.saveFailed)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Text(
                                        l.introductionSaveError,
                                        style: const TextStyle(
                                          color: Color(0xFFFFAAA9),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (m.isSaving) const LinearProgressIndicator(),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    accessibleAction(
                                      OutlinedButton(
                                        key: const Key('introduction-skip'),
                                        style: buttonStyle,
                                        onPressed: m.isSaving
                                            ? null
                                            : () => finish(),
                                        child: Text(l.close),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (m.index > 0)
                                      accessibleAction(
                                        OutlinedButton(
                                          key: const Key('introduction-back'),
                                          style: buttonStyle,
                                          onPressed: m.isSaving
                                              ? null
                                              : () {
                                                  m.previous();
                                                  widget.onStepChanged(m.step);
                                                },
                                          child: Text(l.introductionBack),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: FilledButton(
                                        key: const Key('introduction-next'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFFFAC65,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF321900,
                                          ),
                                          minimumSize: const Size(0, 40),
                                        ),
                                        onPressed: m.isSaving
                                            ? null
                                            : () {
                                                if (m.isLast) {
                                                  finish(add: true);
                                                } else {
                                                  m.next();
                                                  widget.onStepChanged(m.step);
                                                }
                                              },
                                        child: Text(
                                          m.isLast
                                              ? l.tourAddAnalysis
                                              : l.introductionNext,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _SpotlightClipper extends CustomClipper<Path> {
  const _SpotlightClipper(this.target);
  final Rect? target;
  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Offset.zero & size);
    if (target != null && !target!.isEmpty) {
      path
        ..addRRect(RRect.fromRectAndRadius(target!, const Radius.circular(12)))
        ..fillType = PathFillType.evenOdd;
    }
    return path;
  }

  @override
  bool shouldReclip(_SpotlightClipper oldClipper) =>
      target != oldClipper.target;
}
