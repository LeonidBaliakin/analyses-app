import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'records_view_model.dart';
import '../../../presentation/record_fields.dart';
export '../../../presentation/record_fields.dart';

Future<void> showRecordHistory(
  BuildContext context,
  RecordsViewModel model,
  String id,
) {
  var future = model.history(id);
  final l = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.localHistory),
        content: SizedBox(
          width: 600,
          child: FutureBuilder<List<RecordEntry>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.localHistoryError),
                    TextButton(
                      onPressed: () => setState(() {
                        future = model.history(id);
                      }),
                      child: Text(l.retry),
                    ),
                  ],
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final entry in snapshot.data!) ...[
                      Text(
                        '${l.localRevision} ${entry.revision}${entry.deleted ? ' · ${l.localDeleted}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      for (final (label, value) in recordFields(
                        l,
                        entry.record,
                        terminology: model.terminology,
                      ))
                        if (value.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('$label: $value'),
                          ),
                      const Divider(height: 24),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.localClose),
          ),
        ],
      ),
    ),
  );
}
