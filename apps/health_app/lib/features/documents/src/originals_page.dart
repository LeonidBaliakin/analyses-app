import 'package:design_system/design_system.dart';
import 'package:document_domain/document_domain.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../platform/device_access.dart';
import 'originals_view_model.dart';
import '../../processing/processing.dart';

class OriginalsPage extends StatefulWidget {
  const OriginalsPage({
    required this.model,
    this.onClose,
    this.processing,
    super.key,
  });
  final OriginalsViewModel model;
  final VoidCallback? onClose;
  final ProcessingViewModel? processing;
  @override
  State<OriginalsPage> createState() => _OriginalsPageState();
}

class _OriginalsPageState extends State<OriginalsPage> {
  @override
  void initState() {
    super.initState();
    widget.model.load();
  }

  Future<void> _connect() async {
    final endpoint = TextEditingController();
    final token = TextEditingController();
    final l = AppLocalizations.of(context);
    var invalid = false;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: Text(l.originalsConnect),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.originalsConnectionHint),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('documents-endpoint'),
                  controller: endpoint,
                  decoration: InputDecoration(labelText: l.originalsEndpoint),
                ),
                TextField(
                  key: const Key('documents-token'),
                  controller: token,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l.originalsToken),
                ),
                if (invalid) Text(l.originalsConnectionError),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.localCancel),
            ),
            FilledButton(
              onPressed: () {
                if (widget.model.configure(endpoint.text, token.text)) {
                  Navigator.pop(context);
                } else {
                  setState(() => invalid = true);
                }
              },
              child: Text(l.originalsConnect),
            ),
          ],
        ),
      ),
    );
    // Allow the dialog's closing transition to release its text fields.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    endpoint.dispose();
    token.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.originalsTitle),
        leading: widget.onClose == null
            ? null
            : IconButton(
                tooltip: l.localBack,
                onPressed: widget.onClose,
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: ListenableBuilder(
        listenable: widget.model,
        builder: (context, _) {
          final model = widget.model;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.originalsHint),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const Key('import-original'),
                          onPressed: model.busy
                              ? null
                              : () => model.pick(AttachmentSource.files),
                          icon: const Icon(Icons.file_open_outlined),
                          label: Text(l.originalsImport),
                        ),
                        OutlinedButton(
                          onPressed: model.busy
                              ? null
                              : () => model.pick(AttachmentSource.gallery),
                          child: Text(l.addGalleryTitle),
                        ),
                        if (model.device.supportsCamera)
                          OutlinedButton(
                            onPressed: model.busy
                                ? null
                                : () => model.pick(AttachmentSource.camera),
                            child: Text(l.addPhotoTitle),
                          ),
                        OutlinedButton(
                          onPressed: model.busy
                              ? null
                              : (model.connected ? model.disconnect : _connect),
                          child: Text(
                            model.connected
                                ? l.originalsDisconnect
                                : l.originalsConnect,
                          ),
                        ),
                        IconButton(
                          tooltip: l.localRefresh,
                          onPressed: model.busy ? null : model.load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (model.busy) const LinearProgressIndicator(),
                    if (model.error != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          switch (model.error) {
                            'too_large' => l.originalsTooLarge,
                            'unsupported' => l.originalsUnsupported,
                            'integrity' => l.originalsIntegrityError,
                            'quota' => l.originalsQuota,
                            'cloud_access_unavailable' => l.cloudUnavailable,
                            'access' || 'unauthorized' => l.originalsAccess,
                            'connection' => l.originalsConnectionError,
                            'profile' => l.originalsProfileRequired,
                            _ => l.originalsFailed,
                          },
                          style: TextStyle(
                            color: OrangePalette.of(context).red,
                          ),
                        ),
                      ),
                    if (model.error != null && model.canRetryImport)
                      TextButton(
                        onPressed: model.busy ? null : model.retryImport,
                        child: Text(l.retry),
                      ),
                    if (model.notice != null)
                      Semantics(
                        liveRegion: true,
                        child: Text(switch (model.notice) {
                          'local' => l.originalsLocalSaved,
                          'uploaded' => l.originalsCloudSaved,
                          _ => l.originalsVerified,
                        }),
                      ),
                    if (model.originals.isEmpty && !model.busy)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(l.originalsEmpty),
                      ),
                    for (final original in model.originals)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: PaperCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                original.fileName,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text('${original.mime} · ${original.size} B'),
                              Text(
                                model.connected &&
                                        original.cloudState !=
                                            OriginalCloudState.local &&
                                        !model.isCurrentDestination(original)
                                    ? l.originalsOtherConnection
                                    : switch (original.cloudState) {
                                        OriginalCloudState.local =>
                                          l.originalsLocal,
                                        OriginalCloudState.pending =>
                                          l.originalsPending,
                                        OriginalCloudState.ready =>
                                          l.originalsCloudSaved,
                                      },
                              ),
                              ExpansionTile(
                                title: Text(l.originalsIntegrity),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SelectableText(
                                      'SHA-256: ${original.sha256}',
                                    ),
                                  ),
                                ],
                              ),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (widget.processing != null)
                                    TextButton(
                                      onPressed: model.busy
                                          ? null
                                          : () => showProcessing(
                                              context,
                                              widget.processing!,
                                              original,
                                            ),
                                      child: Text(l.processingOpen),
                                    ),
                                  TextButton(
                                    onPressed: model.busy
                                        ? null
                                        : () => model.export(original),
                                    child: Text(l.originalsExport),
                                  ),
                                  TextButton(
                                    onPressed: model.busy || !model.connected
                                        ? null
                                        : () => model.upload(original),
                                    child: Text(
                                      original.cloudState ==
                                              OriginalCloudState.pending
                                          ? l.retry
                                          : l.originalsUpload,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        model.busy ||
                                            !model.connected ||
                                            !model.isCurrentDestination(
                                              original,
                                            ) ||
                                            original.cloudState !=
                                                OriginalCloudState.ready
                                        ? null
                                        : () => model.verifyCloud(original),
                                    child: Text(l.originalsDownloadVerify),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
