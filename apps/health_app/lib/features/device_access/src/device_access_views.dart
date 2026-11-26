import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
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
  return model.location?.address ?? l.locationNotSelected;
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

Future<void> showLocationSelection(
  BuildContext context, {
  bool prepareSession = false,
}) async {
  final model = DeviceAccessScope.of(context);
  if (model.locationSelectionOpen ||
      (prepareSession && model.locationConfirmed)) {
    return;
  }
  model.locationSelectionOpen = true;
  final l = AppLocalizations.of(context);
  if (prepareSession) {
    unawaited(model.prepareLocationForSession(language: l.localeName));
  }
  try {
    await showReferenceSheet(
      context,
      l.chooseLocation,
      LocationControls(
        model: model,
        onConfirmed: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  } finally {
    model.locationSelectionOpen = false;
    model.cancelAddressSearch();
  }
}

class LocationControls extends StatefulWidget {
  const LocationControls({required this.model, this.onConfirmed, super.key});
  final DeviceAccessViewModel model;
  final VoidCallback? onConfirmed;

  @override
  State<LocationControls> createState() => _LocationControlsState();
}

class _LocationControlsState extends State<LocationControls> {
  late final _address = TextEditingController(
    text: widget.model.location?.address ?? widget.model.lastLocation?.address,
  );
  late final _focus = FocusNode(onKeyEvent: _handleAddressKeys);
  final _optionKeys = List.generate(5, (_) => GlobalKey());
  int _highlighted = -1;
  AddressLevel? _addressLevel;
  DeviceLocation? _suggestion;
  bool _empty = false;

  KeyEventResult _handleAddressKeys(FocusNode node, KeyEvent event) {
    final options = widget.model.addressSuggestions;
    if (options.isEmpty ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final delta = event.logicalKey == LogicalKeyboardKey.arrowDown
        ? 1
        : event.logicalKey == LogicalKeyboardKey.arrowUp
        ? -1
        : 0;
    if (delta == 0) return KeyEventResult.ignored;
    setState(
      () => _highlighted = (_highlighted + delta).clamp(0, options.length - 1),
    );
    final highlighted = _highlighted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final optionContext = _optionKeys[highlighted].currentContext;
      if (mounted && optionContext != null) {
        Scrollable.ensureVisible(optionContext, alignment: .8);
      }
    });
    return KeyEventResult.handled;
  }

  void _selectAddress(DeviceLocation option) {
    widget.model.cancelAddressSearch();
    _address.text = option.inputText;
    _address.selection = TextSelection.collapsed(offset: _address.text.length);
    setState(() {
      _suggestion = option;
      _addressLevel = option.level;
      _highlighted = -1;
    });
    _focus.requestFocus();
  }

  @override
  void dispose() {
    widget.model.cancelAddressSearch();
    _focus.dispose();
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
          if (model.pendingLocation case final candidate?) ...[
            const SizedBox(height: 16),
            Text(
              l.confirmCurrentLocation,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(
                candidate.address,
                key: const Key('location-candidate'),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const Key('confirm-location'),
                  onPressed: model.isBusy
                      ? null
                      : () async {
                          final accepted = await model.confirmLocation(
                            language: l.localeName,
                          );
                          if (mounted &&
                              accepted &&
                              !model.locationSaveFailed) {
                            widget.onConfirmed?.call();
                          }
                        },
                  child: Text(l.confirmLocationYes),
                ),
                TextButton(
                  key: const Key('edit-location'),
                  onPressed: model.isBusy
                      ? null
                      : () {
                          model.editLocation();
                          _address.selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: _address.text.length,
                          );
                          _focus.requestFocus();
                        },
                  child: Text(l.enterAnotherLocation),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(l.locationAccessExplanation),
          const SizedBox(height: 8),
          Semantics(liveRegion: true, child: Text(locationLabel(l, model))),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('locate-device'),
            onPressed: model.isBusy
                ? null
                : () => model.locate(language: l.localeName),
            icon: const Icon(Icons.my_location),
            label: Text(l.useCurrentLocation),
          ),
          if (model.isBusy)
            LinearProgressIndicator(semanticsLabel: l.deviceAccessBusy),
          if (model.locationIssue case final issue?)
            _IssueMessage(issue: issue, model: model),
          if (model.addressLookupFailed) Text(l.locationAddressUnavailable),
          if (model.locationSaveFailed) Text(l.locationSaveFailed),
          const SizedBox(height: 16),
          TextField(
            key: const Key('manual-location'),
            controller: _address,
            focusNode: _focus,
            enabled: !model.isBusy,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: l.manualLocation,
              hintText: l.manualLocationHint,
              errorText: _empty ? l.locationRequired : null,
            ),
            onChanged: (value) {
              setState(() {
                _suggestion = null;
                _empty = false;
                _highlighted = -1;
                if (!value.contains(',')) _addressLevel = null;
              });
              unawaited(model.searchAddresses(value, language: l.localeName));
            },
            onSubmitted: (_) {
              final options = model.addressSuggestions;
              if (options.isNotEmpty) {
                _selectAddress(
                  options[_highlighted.clamp(0, options.length - 1)],
                );
              }
            },
          ),
          if (model.addressSuggestions.isNotEmpty)
            Material(
              key: const Key('address-suggestions'),
              color: OrangePalette.of(context).card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: OrangePalette.of(context).line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (
                    var index = 0;
                    index < model.addressSuggestions.length;
                    index++
                  )
                    ListTile(
                      key: _optionKeys[index],
                      selected: _highlighted == index,
                      leading: const Icon(Icons.location_on_outlined),
                      title: Text(model.addressSuggestions[index].address),
                      onTap: () =>
                          _selectAddress(model.addressSuggestions[index]),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(switch (_addressLevel) {
              AddressLevel.city => l.addressEnterStreet,
              AddressLevel.street => l.addressEnterBuilding,
              AddressLevel.building => l.addressReady,
              null => l.addressEntrySequence,
            }),
          ),
          if (model.isSearchingAddresses)
            LinearProgressIndicator(semanticsLabel: l.searchingAddresses),
          if (model.addressSearchFailed) Text(l.addressSuggestionsUnavailable),
          if (model.addressSearchEmpty) Text(l.addressSuggestionsEmpty),
          Text(
            l.addressSearchProvider,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (model.lastLocation case final saved?)
            TextButton.icon(
              key: const Key('use-last-location'),
              onPressed: model.isBusy
                  ? null
                  : () {
                      _selectAddress(saved);
                    },
              icon: const Icon(Icons.history),
              label: Text(l.lastLocationAddress(saved.address)),
            ),
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('apply-manual-location'),
            onPressed: model.isBusy
                ? null
                : () async {
                    final accepted = await model.setManualLocation(
                      _address.text,
                      suggestion: _suggestion,
                      language: l.localeName,
                    );
                    if (!mounted) return;
                    setState(() => _empty = _address.text.trim().isEmpty);
                    if (accepted && !model.locationSaveFailed) {
                      widget.onConfirmed?.call();
                    }
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
