import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../platform/device_access.dart';
import '../../../presentation/reference_widgets.dart';
import 'device_access_view_model.dart';

class DeviceAccessScope extends InheritedWidget {
  const DeviceAccessScope({
    required this.model,
    required super.child,
    super.key,
  });
  final DeviceAccessViewModel model;

  static DeviceAccessViewModel of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeviceAccessScope>()!.model;

  @override
  bool updateShouldNotify(DeviceAccessScope oldWidget) =>
      model != oldWidget.model;
}

/// Presents the introduction once, after a navigator is available.
class DeviceAccessIntroduction extends StatefulWidget {
  const DeviceAccessIntroduction({
    required this.child,
    this.onReady,
    super.key,
  });
  final Widget child;
  final Future<void> Function()? onReady;
  @override
  State<DeviceAccessIntroduction> createState() =>
      _DeviceAccessIntroductionState();
}

class _DeviceAccessIntroductionState extends State<DeviceAccessIntroduction> {
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    final model = DeviceAccessScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (model.introductionRequired) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => ListenableBuilder(
            listenable: model,
            builder: (context, _) {
              final l = AppLocalizations.of(context);
              return PopScope(
                canPop: false,
                child: AlertDialog(
                  scrollable: true,
                  title: Text(l.deviceAccessWelcome),
                  content: SizedBox(
                    width: 480,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(l.deviceAccessIntro),
                        const SizedBox(height: 16),
                        Text(l.fileAccessExplanation),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: model.isBusy
                              ? null
                              : () => model.pick(AttachmentSource.files),
                          icon: const Icon(Icons.folder_open_outlined),
                          label: Text(l.chooseAttachment),
                        ),
                        AttachmentSelectionStatus(model: model),
                        const SizedBox(height: 16),
                        LocationControls(model: model),
                        if (model.introductionIssue != null)
                          Text(l.accessIntroSaveError),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      key: const Key('access-continue'),
                      onPressed: model.isBusy
                          ? null
                          : () async {
                              if (await model.finishIntroduction() &&
                                  context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                      child: Text(l.continueToApp),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
      if (mounted) await widget.onReady?.call();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

String accessIssueText(AppLocalizations l, AccessIssue issue) =>
    switch (issue) {
      AccessIssue.denied => l.deviceAccessDenied,
      AccessIssue.permanentlyDenied => l.deviceAccessPermanentlyDenied,
      AccessIssue.restricted => l.deviceAccessRestricted,
      AccessIssue.serviceDisabled => l.locationServicesDisabled,
      AccessIssue.unsupported => l.deviceAccessUnsupported,
      AccessIssue.cancelled => l.attachmentCancelled,
      AccessIssue.timeout => l.locationTimedOut,
      AccessIssue.failed => l.deviceAccessFailed,
    };

String locationLabel(AppLocalizations l, DeviceAccessViewModel model) {
  if (model.manualLocation case final address?) return address;
  if (model.coordinates case final position?) {
    return l.locationCoordinates(
      position.latitude.toStringAsFixed(4),
      position.longitude.toStringAsFixed(4),
    );
  }
  return l.locationNotSelected;
}

class _IssueMessage extends StatelessWidget {
  const _IssueMessage({
    required this.issue,
    required this.model,
    this.location = true,
  });
  final AccessIssue issue;
  final DeviceAccessViewModel model;
  final bool location;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(liveRegion: true, child: Text(accessIssueText(l, issue))),
        if (model.supportsSettings &&
            (issue == AccessIssue.denied ||
                issue == AccessIssue.permanentlyDenied ||
                issue == AccessIssue.serviceDisabled))
          TextButton(
            onPressed: model.isBusy
                ? null
                : () => model.openSettings(location: location),
            child: Text(l.openDeviceSettings),
          ),
      ],
    );
  }
}

class AttachmentSelectionStatus extends StatelessWidget {
  const AttachmentSelectionStatus({required this.model, super.key});
  final DeviceAccessViewModel model;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final l = AppLocalizations.of(context), p = OrangePalette.of(context);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (model.attachmentIssue case final issue?)
            _IssueMessage(issue: issue, model: model, location: false),
          if (model.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              l.selectedAttachments,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            for (final attachment in model.attachments)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  attachment.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: l.removeAttachment,
                  onPressed: model.isBusy
                      ? null
                      : () => model.removeAttachment(attachment),
                  icon: const Icon(Icons.close),
                ),
              ),
            Text(
              l.attachmentSessionOnly,
              style: TextStyle(color: p.secondary, fontSize: 12),
            ),
          ],
        ],
      );
    },
  );
}

Future<void> showLocationSelection(BuildContext context) => showReferenceSheet(
  context,
  AppLocalizations.of(context).chooseLocation,
  LocationControls(model: DeviceAccessScope.of(context)),
);

class LocationControls extends StatefulWidget {
  const LocationControls({required this.model, super.key});
  final DeviceAccessViewModel model;

  @override
  State<LocationControls> createState() => _LocationControlsState();
}

class _LocationControlsState extends State<LocationControls> {
  late final _address = TextEditingController(
    text: widget.model.manualLocation,
  );
  bool _empty = false;

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final l = AppLocalizations.of(context), model = widget.model;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.locationAccessExplanation),
          const SizedBox(height: 8),
          Semantics(liveRegion: true, child: Text(locationLabel(l, model))),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('locate-device'),
            onPressed: model.isBusy ? null : model.locate,
            icon: const Icon(Icons.my_location),
            label: Text(l.useCurrentLocation),
          ),
          if (model.isBusy)
            LinearProgressIndicator(semanticsLabel: l.deviceAccessBusy),
          if (model.locationIssue case final issue?)
            _IssueMessage(issue: issue, model: model),
          const SizedBox(height: 16),
          TextField(
            key: const Key('manual-location'),
            controller: _address,
            enabled: !model.isBusy,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: l.manualLocation,
              hintText: l.manualLocationHint,
              errorText: _empty ? l.locationRequired : null,
            ),
            onChanged: (_) {
              if (_empty) setState(() => _empty = false);
            },
          ),
          FilledButton(
            key: const Key('apply-manual-location'),
            onPressed: model.isBusy
                ? null
                : () {
                    setState(
                      () => _empty = !model.setManualLocation(_address.text),
                    );
                  },
            child: Text(l.useThisLocation),
          ),
        ],
      );
    },
  );
}

/// Public settings entry; the same commands are used by capture and directory.
class DeviceAccessSettings extends StatelessWidget {
  const DeviceAccessSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final model = DeviceAccessScope.of(context),
        l = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.fileAccessExplanation),
          for (final option in [
            (AttachmentSource.camera, Icons.photo_camera_outlined, l.takePhoto),
            (
              AttachmentSource.gallery,
              Icons.photo_library_outlined,
              l.fromGallery,
            ),
            (AttachmentSource.files, Icons.folder_outlined, l.filePdf),
          ])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(option.$2),
              title: Text(option.$3),
              enabled:
                  !model.isBusy &&
                  (option.$1 != AttachmentSource.camera ||
                      model.supportsCamera),
              onTap: () => model.pick(option.$1),
            ),
          if (!model.supportsCamera) Text(l.cameraUnavailable),
          AttachmentSelectionStatus(model: model),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_on_outlined),
            title: Text(l.chooseLocation),
            subtitle: Text(locationLabel(l, model)),
            onTap: () => showLocationSelection(context),
          ),
        ],
      ),
    );
  }
}
