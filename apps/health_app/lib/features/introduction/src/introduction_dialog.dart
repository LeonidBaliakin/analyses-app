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
    final closed = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _IntroductionDialog(
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

class _IntroductionDialog extends StatelessWidget {
  const _IntroductionDialog({
    required this.model,
    required this.onStepChanged,
    this.onFinish,
    this.onOpenStep,
  });

  final IntroductionViewModel model;
  final VoidCallback? onFinish;
  final Future<void> Function(IntroductionStep)? onOpenStep;
  final ValueChanged<IntroductionStep> onStepChanged;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final l = AppLocalizations.of(context), p = OrangePalette.of(context);
      final (title, body, icon) = switch (model.step) {
        IntroductionStep.profile => (
          l.introductionProfileTitle,
          l.introductionProfileBody,
          Icons.person_outline,
        ),
        IntroductionStep.reports => (
          l.introductionReportsTitle,
          l.introductionReportsBody,
          Icons.note_add_outlined,
        ),
        IntroductionStep.summary => (
          l.introductionSummaryTitle,
          l.introductionSummaryBody,
          Icons.assessment_outlined,
        ),
        IntroductionStep.laboratories => (
          l.introductionLabsTitle,
          l.introductionLabsBody,
          Icons.science_outlined,
        ),
        IntroductionStep.specialists => (
          l.introductionDoctorsTitle,
          l.introductionDoctorsBody,
          Icons.medical_services_outlined,
        ),
        IntroductionStep.appointment => (
          l.tourShareTitle,
          l.tourShareBody,
          Icons.qr_code_2,
        ),
      };
      Future<void> finish({bool add = false}) async {
        if (await model.finish() && context.mounted) {
          Navigator.of(context).pop();
          if (add) onFinish?.call();
        }
      }

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) finish();
        },
        child: AlertDialog(
          key: const Key('app-introduction'),
          scrollable: true,
          insetPadding: const EdgeInsets.all(16),
          title: Text(l.appIntroduction),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    l.introductionStep(
                      model.index + 1,
                      IntroductionStep.values.length,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: (model.index + 1) / IntroductionStep.values.length,
                    color: p.accent,
                    backgroundColor: p.accentSoft,
                  ),
                ),
                const SizedBox(height: 24),
                ExcludeSemantics(child: Icon(icon, color: p.accent, size: 36)),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Text(body),
                const SizedBox(height: 20),
                Text(
                  l.introductionNotice,
                  style: TextStyle(color: p.secondary, fontSize: 12),
                ),
                if (model.saveFailed) ...[
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l.introductionSaveError,
                      style: TextStyle(color: p.red),
                    ),
                  ),
                ],
                if (model.isSaving) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(semanticsLabel: l.savingPreferences),
                ],
              ],
            ),
          ),
          actions: [
            if (onOpenStep != null && model.index < 3)
              TextButton(
                key: const Key('introduction-try'),
                onPressed: model.isSaving
                    ? null
                    : () => onOpenStep!(model.step),
                child: Text(switch (model.step) {
                  IntroductionStep.profile => l.localEditProfile,
                  IntroductionStep.reports => l.addAnalysis,
                  _ => l.historyOpen,
                }),
              ),
            TextButton(
              key: const Key('introduction-skip'),
              onPressed: model.isSaving ? null : () => finish(),
              child: Text(l.introductionSkip),
            ),
            if (model.index > 0)
              TextButton(
                key: const Key('introduction-back'),
                onPressed: model.isSaving
                    ? null
                    : () {
                        model.previous();
                        onStepChanged(model.step);
                      },
                child: Text(l.introductionBack),
              ),
            FilledButton(
              key: const Key('introduction-next'),
              onPressed: model.isSaving
                  ? null
                  : () {
                      if (model.isLast) {
                        finish(add: true);
                      } else {
                        model.next();
                        onStepChanged(model.step);
                      }
                    },
              child: Text(
                model.isLast ? l.tourAddAnalysis : l.introductionNext,
              ),
            ),
          ],
        ),
      );
    },
  );
}
