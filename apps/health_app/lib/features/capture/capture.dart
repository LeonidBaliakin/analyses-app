import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../presentation/reference_widgets.dart';
import '../device_access/device_access.dart';

Future<void> showAddAnalysis(
  BuildContext context, {
  VoidCallback? onManualEntry,
}) {
  final model = DeviceAccessScope.of(context);
  return showReferenceSheet(
    context,
    AppLocalizations.of(context).addAnalysis,
    _CaptureOptions(model: model, onManualEntry: onManualEntry),
  );
}

class _CaptureOptions extends StatelessWidget {
  const _CaptureOptions({required this.model, this.onManualEntry});
  final DeviceAccessViewModel model;
  final VoidCallback? onManualEntry;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => _buildOptions(context),
  );

  Widget _buildOptions(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RecordActions(),
        if (onManualEntry != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FilledButton.icon(
              onPressed: model.isBusy
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      onManualEntry!();
                    },
              icon: const Icon(Icons.edit_outlined),
              label: Text(l.addManually),
            ),
          ),
        for (final option in [
          (
            Icons.photo_camera_outlined,
            l.addPhotoTitle,
            l.photoAdvice,
            AttachmentSource.camera,
          ),
          (
            Icons.photo_library_outlined,
            l.addGalleryTitle,
            l.addGalleryHint,
            AttachmentSource.gallery,
          ),
          (
            Icons.description_outlined,
            l.filePdf,
            l.addFilesHint,
            AttachmentSource.files,
          ),
          (Icons.mail_outline, l.addMailTitle, l.demoEmail, null),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(14),
                alignment: Alignment.centerLeft,
              ),
              onPressed:
                  model.isBusy ||
                      (option.$4 == AttachmentSource.camera &&
                          !model.supportsCamera)
                  ? null
                  : () => option.$4 == null
                        ? showUnavailable(context, option.$2)
                        : model.pick(option.$4!),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: p.accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(option.$1, color: p.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.$2,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.$3,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: p.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!model.supportsCamera)
          Text(l.cameraUnavailable, style: TextStyle(color: p.secondary)),
        if (model.isBusy)
          LinearProgressIndicator(semanticsLabel: l.deviceAccessBusy),
        AttachmentSelectionStatus(model: model),
        const SizedBox(height: 10),
        Text(l.previewOnly, style: TextStyle(color: p.muted, fontSize: 12)),
      ],
    );
  }
}
