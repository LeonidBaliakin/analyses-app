import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../presentation/record_fields.dart';
import 'sync_view_model.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({required this.model, required this.onClose, super.key});
  final SyncViewModel model;
  final VoidCallback onClose;
  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final endpoint = TextEditingController(text: 'http://127.0.0.1:18088/'),
      token = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.model.refresh();
  }

  @override
  void dispose() {
    endpoint.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model,
          l = AppLocalizations.of(context),
          error = m.error ?? m.scope?.error;
      return Scaffold(
        appBar: AppBar(
          title: Text(l.syncTitle),
          leading: IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.arrow_back),
            tooltip: l.localBack,
          ),
        ),
        body: UnobstructedPane(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.syncScope),
                    const SizedBox(height: 16),
                    if (!m.connected) ...[
                      TextField(
                        key: const Key('sync-endpoint'),
                        controller: endpoint,
                        enabled: !m.busy,
                        decoration: InputDecoration(
                          labelText: l.originalsEndpoint,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('sync-token'),
                        controller: token,
                        enabled: !m.busy,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l.originalsToken,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        key: const Key('sync-connect'),
                        onPressed: m.busy
                            ? null
                            : () async {
                                if (await m.connect(
                                  endpoint.text,
                                  token.text,
                                )) {
                                  token.clear();
                                }
                              },
                        child: Text(l.syncConnect),
                      ),
                    ] else ...[
                      Text(l.syncConnected),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            key: const Key('sync-now'),
                            onPressed: m.busy
                                ? null
                                : () => m.synchronize(force: true),
                            child: Text(l.syncNow),
                          ),
                          TextButton(
                            onPressed: m.disconnect,
                            child: Text(l.syncDisconnect),
                          ),
                        ],
                      ),
                    ],
                    if (m.busy) const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(l.syncPending(m.pending)),
                    Text(l.syncConflictCount(m.conflicts.length)),
                    if (m.scope?.lastSuccess != null)
                      Text(
                        l.syncLast(m.scope!.lastSuccess!.toLocal().toString()),
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            switch (error) {
                              'unauthorized' => l.syncUnauthorized,
                              'access' => l.syncAccess,
                              'sync_denied' ||
                              'cloud_disabled' => l.cloudSyncDenied,
                              'sync_quota_exceeded' => l.cloudSyncQuota,
                              'cloud_access_unavailable' => l.cloudUnavailable,
                              'account' => l.syncAccount,
                              'server_changed' ||
                              'cursor' => l.syncServerChanged,
                              'conflict_changed' => l.syncConflictChanged,
                              _ => l.syncFailed,
                            },
                            style: TextStyle(
                              color: OrangePalette.of(context).red,
                            ),
                          ),
                        ),
                      ),
                    if (m.scope?.retryAt != null)
                      Text(
                        l.syncRetryAt(m.scope!.retryAt!.toLocal().toString()),
                      ),
                    for (final conflict in m.conflicts)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: PaperCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                recordName(conflict.local.record),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l.syncLocalVersion,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (conflict.local.deleted) Text(l.syncDeleted),
                              for (final f in recordFields(
                                l,
                                conflict.local.record,
                              ))
                                if (f.$2.isNotEmpty) Text('${f.$1}: ${f.$2}'),
                              const Divider(),
                              Text(
                                l.syncRemoteVersion,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (conflict.remote.deleted) Text(l.syncDeleted),
                              for (final f in recordFields(
                                l,
                                conflict.remote.record,
                              ))
                                if (f.$2.isNotEmpty) Text('${f.$1}: ${f.$2}'),
                              const SizedBox(height: 12),
                              Text(l.syncResolveHint),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  OutlinedButton(
                                    key: Key(
                                      'keep-local-${conflict.local.record.id}',
                                    ),
                                    onPressed: m.busy
                                        ? null
                                        : () => m.resolve(conflict, true),
                                    child: Text(l.syncKeepLocal),
                                  ),
                                  OutlinedButton(
                                    key: Key(
                                      'use-server-${conflict.local.record.id}',
                                    ),
                                    onPressed: m.busy
                                        ? null
                                        : () => m.resolve(conflict, false),
                                    child: Text(l.syncUseServer),
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
          ),
        ),
      );
    },
  );
}
