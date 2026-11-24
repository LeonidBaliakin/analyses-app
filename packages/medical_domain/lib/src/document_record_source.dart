/// Original extracted fields remain distinct from the user's reviewed values.
final class DocumentRecordSource {
  DocumentRecordSource({
    required this.documentId,
    required this.originalId,
    required this.originalSha256,
    required this.jobId,
    required this.draftRevision,
    required this.rowId,
    required Map<String, String> fields,
    required Map<String, String> versions,
  }) : fields = Map.unmodifiable(fields),
       versions = Map.unmodifiable(versions);
  final String documentId, originalId, originalSha256, jobId, rowId;
  final int draftRevision;
  final Map<String, String> fields, versions;
}
