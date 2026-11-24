import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:document_domain/document_domain.dart';
import 'package:document_processing/document_processing.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/processing/processing.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:local_store/local_store.dart';
import 'package:medical_domain/medical_domain.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:design_system/design_system.dart';

class Engine implements ProcessingEngine {
  String? runtime = 'r1', failure;
  int calls = 0;
  bool cancelled = false;
  Completer<void>? barrier;
  @override
  Future<String?> runtimeId() async => runtime;
  @override
  Future<Map<String, dynamic>> run(
    ProcessingJob job,
    Uint8List bytes,
    Cancellation cancellation,
    Future<void> Function(ProcessingStatus, Map<String, dynamic>?) progress,
  ) async {
    calls++;
    final artifact = <String, dynamic>{
      'runtimeId': 'r1',
      'versions': {'ocr': 'o1', 'model': 'm1', 'prompt': 'p1', 'worker': 'w1'},
      'pages': [
        {'number': 1, 'text': 'Гемоглобин 140 г/л 100-200'},
      ],
    };
    await progress(ProcessingStatus.extracting, artifact);
    if (barrier != null) await barrier!.future;
    cancellation.check();
    if (failure != null) throw ProcessingFailure(failure!);
    return {
      ...artifact,
      'schemaVersion': 1,
      'rows': [
        {
          'page': 1,
          'evidence': 'Гемоглобин 140 г/л 100-200',
          'name': 'Гемоглобин',
          'value': '140',
          'unit': 'г/л',
          'reference': '100-200',
          'date': '',
          'laboratory': '',
          'specimen': '',
          'method': '',
        },
      ],
    };
  }

  @override
  Future<void> cancel(ProcessingJob j) async {
    cancelled = true;
    barrier?.complete();
    barrier = null;
  }

  @override
  void close() {}
}

class LostConfirmation implements DraftRepository {
  LostConfirmation(this.db);
  final RecordsDatabase db;
  bool lose = true;
  @override
  Future<void> createProcessingJob(ProcessingJob j) =>
      db.createProcessingJob(j);
  @override
  Future<List<ProcessingJob>> processingJobs(String p, String o) =>
      db.processingJobs(p, o);
  @override
  Future<void> setProcessingStatus(
    String p,
    String j,
    ProcessingStatus s, {
    String? error,
    Map<String, dynamic>? artifact,
  }) => db.setProcessingStatus(p, j, s, error: error, artifact: artifact);
  @override
  Future<ProcessingDraft> storeGeneratedDraft(ProcessingDraft d) =>
      db.storeGeneratedDraft(d);
  @override
  Future<ProcessingDraft?> readDraft(String p, String j) => db.readDraft(p, j);
  @override
  Future<ProcessingDraft> saveDraft(ProcessingDraft d, int rev) =>
      db.saveDraft(d, rev);
  @override
  Future<List<String>> confirmDraft(
    ProcessingDraft d,
    String id,
    int rev,
  ) async {
    final result = await db.confirmDraft(d, id, rev);
    if (lose) {
      lose = false;
      throw StateError('synthetic lost response');
    }
    return result;
  }
}

void main() {
  late RecordsDatabase db;
  late OriginalDocument original;
  late Engine local, remote;
  late ProcessingViewModel vm;
  var id = 0;
  final bytes = Uint8List.fromList(utf8.encode('%PDF-1.7 Synthetic'));
  setUp(() async {
    db = RecordsDatabase(NativeDatabase.memory());
    await db.commit(
      const RecordMutation(
        operationId: 'profile',
        record: MedicalProfile(id: 'p', name: 'Synthetic'),
        expectedRevision: 0,
      ),
    );
    original = OriginalDocument(
      documentId: 'd',
      originalId: 'o',
      profileId: 'p',
      fileName: 'synthetic.pdf',
      mime: 'application/pdf',
      size: bytes.length,
      sha256: originalSha256(bytes),
      importedAt: DateTime.utc(2026),
      importSource: 'files',
    );
    await db.importOriginal(original, bytes);
    id = 0;
    local = Engine();
    remote = Engine();
    vm = ProcessingViewModel(
      repository: db,
      originals: db,
      local: local,
      server: () => remote,
      serverOriginalReady: (_) => true,
      newId: () => 'id-${id++}',
      onConfirmed: () async {},
    );
    await vm.open(original);
  });
  tearDown(() async {
    vm.dispose();
    await db.close();
  });
  ProcessingDraft dated(ProcessingDraft d) => d.edited([
    d.rows.single.edit({...d.rows.single.review, 'date': '2026-11-25'}),
  ]);
  test('explicit modes share draft/normalization; unavailable local never contacts server', () async {
    local.runtime = null;
    await vm.start(ProcessingMode.local);
    expect(vm.error, 'unavailable');
    expect(remote.calls, 0);
    expect((await db.read('p')).where((e) => e.record is LabResult), isEmpty);
    await vm.start(ProcessingMode.ownServer);
    expect(vm.draft!.mode, ProcessingMode.ownServer);
    expect(vm.draft!.rows.single.coding, isNull);
    expect(remote.calls, 1);
    expect(local.calls, 0);
    final a = encodeDraft(vm.draft!);
    local.runtime = 'r1';
    await vm.start(ProcessingMode.local);
    final b = encodeDraft(vm.draft!);
    expect(a['rows'], b['rows']);
    expect(a['versions'], b['versions']);
    expect((await db.read('p')).where((e) => e.record is LabResult), isEmpty);
  });
  test('missing date blocks confirmation; edits keep raw OCR; repeated confirm is harmless', () async {
    await vm.start(ProcessingMode.local);
    expect(await vm.confirm(vm.draft!), isFalse);
    expect(vm.error, 'date');
    final corrected = dated(vm.draft!);
    expect(await vm.confirm(corrected), isTrue);
    final entries = (await db.read('p'))
        .where((e) => e.record is LabResult)
        .toList();
    expect(entries, hasLength(1));
    final r = entries.single.record as LabResult;
    expect(r.date, CalendarDate(2026, 11, 25));
    expect(r.documentSource!.fields['date'], '');
    expect(r.documentSource!.fields['value'], '140');
  });
  test('lost confirmation response is replayed; user correction cannot silently change committed result', () async {
    vm.dispose();
    vm = ProcessingViewModel(
      repository: LostConfirmation(db),
      originals: db,
      local: local,
      server: () => remote,
      serverOriginalReady: (_) => true,
      newId: () => 'id-${id++}',
      onConfirmed: () async {},
    );
    await vm.open(original);
    await vm.start(ProcessingMode.local);
    final d = dated(vm.draft!);
    expect(await vm.confirm(d), isFalse);
    expect(await vm.confirm(vm.draft!), isTrue);
    expect(
      (await db.read('p')).where((e) => e.record is LabResult),
      hasLength(1),
    );
  });
  test('lost confirmation from another original cannot be replayed against the open draft', () async {
    vm.dispose();
    vm = ProcessingViewModel(
      repository: LostConfirmation(db),
      originals: db,
      local: local,
      server: () => remote,
      serverOriginalReady: (_) => true,
      newId: () => 'id-${id++}',
      onConfirmed: () async {},
    );
    final other = OriginalDocument(
      documentId: 'd2',
      originalId: 'o2',
      profileId: 'p',
      fileName: 'other.pdf',
      mime: original.mime,
      size: bytes.length,
      sha256: original.sha256,
      importedAt: original.importedAt,
      importSource: 'files',
    );
    await db.importOriginal(other, bytes);
    await vm.open(other);
    await vm.start(ProcessingMode.local);
    await vm.save(dated(vm.draft!));
    await vm.open(original);
    await vm.start(ProcessingMode.local);
    expect(await vm.confirm(dated(vm.draft!)), isFalse);
    await vm.open(other);
    expect(await vm.confirm(vm.draft!), isTrue);
    final results = (await db.read('p'))
        .map((e) => e.record)
        .whereType<LabResult>();
    expect(results.map((r) => r.documentSource!.originalId).toSet(), {
      'o',
      'o2',
    });
  });
  test('cancel and changed runtime prevent late draft; OCR survives LLM failure for manual review', () async {
    local.barrier = Completer<void>();
    final run = vm.start(ProcessingMode.local);
    while (vm.activeJob == null) {
      await Future<void>.delayed(Duration.zero);
    }
    await vm.cancel();
    await run;
    expect(local.cancelled, isTrue);
    expect(vm.draft, isNull);
    local.failure = 'llm_timeout';
    await vm.start(ProcessingMode.local);
    expect(vm.jobs.first.artifact, isNotNull);
    final failed = vm.jobs.firstWhere(
      (j) => j.status == ProcessingStatus.failed,
    );
    await vm.manualFromOcr(failed);
    expect(vm.draft!.rows.single.source, isEmpty);
    expect(vm.draft!.pages.single['text'], contains('Гемоглобин'));
  });
  testWidgets(
    'review edits survive resize/hinge; save draft and explicit confirmation RU/EN',
    (tester) async {
      await vm.start(ProcessingMode.local);
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget app(Locale locale) => MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            displayFeatures: [
              const DisplayFeature(
                bounds: Rect.fromLTWH(580, 0, 40, 900),
                type: DisplayFeatureType.hinge,
                state: DisplayFeatureState.postureHalfOpened,
              ),
            ],
          ),
          child: child!,
        ),
        home: ProcessingPage(model: vm),
      );
      await tester.pumpWidget(app(const Locale('ru')));
      await tester.pumpAndSettle();
      final name = find.byKey(const Key('draft-row-0-name'));
      await tester.enterText(name, 'Исправленный показатель');
      tester.view.physicalSize = const Size(700, 1000);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(name).controller!.text,
        'Исправленный показатель',
      );
      expect(tester.takeException(), isNull);
      final date = find.byKey(const Key('draft-row-0-date'));
      await tester.ensureVisible(date);
      await tester.enterText(date, '2026-11-25');
      final save = find.byKey(const Key('draft-save'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect((await db.read('p')).where((e) => e.record is LabResult), isEmpty);
      await tester.pumpWidget(app(const Locale('en')));
      await tester.pumpAndSettle();
      final confirm = find.byKey(const Key('draft-confirm'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(
        (await db.read('p')).where((e) => e.record is LabResult),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
