import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;

import 'package:document_domain/document_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/documents/documents.dart';
import 'package:health_app/l10n/generated/app_localizations.dart';
import 'package:health_app/platform/device_access.dart';
import 'package:material_ui/material_ui.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:design_system/design_system.dart';

import 'support/fake_device_access.dart';

final fixture = Uint8List.fromList(
  utf8.encode('%PDF-1.7\nSynthetic fixture\n%%EOF'),
);

class MemoryOriginals implements OriginalRepository {
  OriginalDocument? original;
  bool failAfterCommit = false;
  int inserts = 0;
  @override
  Future<void> importOriginal(OriginalDocument o, Uint8List bytes) async {
    o.verify(bytes);
    if (original == null) {
      original = o;
      inserts++;
    }
    if (failAfterCommit) {
      failAfterCommit = false;
      throw StateError('synthetic lost response');
    }
  }

  @override
  Future<List<OriginalDocument>> listOriginals(String profile) async =>
      original == null ? [] : [original!];
  @override
  Future<Uint8List> readOriginal(String profile, String id) async =>
      Uint8List.fromList(fixture);
  @override
  Future<void> setOriginalCloudState(
    String profile,
    String id,
    OriginalCloudState state, {
    String? destinationId,
  }) async {
    final o = original!;
    original = OriginalDocument(
      documentId: o.documentId,
      originalId: o.originalId,
      profileId: o.profileId,
      fileName: o.fileName,
      mime: o.mime,
      size: o.size,
      sha256: o.sha256,
      importedAt: o.importedAt,
      importSource: o.importSource,
      cloudState: state,
      cloudDestination: destinationId,
    );
  }
}

class FakeDocuments implements DocumentsGateway {
  @override
  String destinationId = 'synthetic-storage';
  bool failUpload = false, corruptDownload = false, closed = false;
  final ids = <String>[];
  @override
  Future<void> upload(OriginalDocument o, Uint8List bytes) async {
    o.verify(bytes);
    ids.add(o.originalId);
    if (failUpload) {
      failUpload = false;
      throw const OriginalFailure('cloud');
    }
  }

  @override
  Future<Uint8List> download(OriginalDocument o) async =>
      corruptDownload ? Uint8List.fromList([0]) : fixture;
  @override
  void close() {
    closed = true;
  }
}

OriginalsViewModel model(
  MemoryOriginals repo,
  FakeDocuments cloud, {
  FakeDeviceAccess? device,
}) {
  var n = 0;
  return OriginalsViewModel(
    repository: repo,
    profileId: 'p',
    newId: () => 'id-${n++}',
    clock: () => DateTime.utc(2026, 11, 24),
    device: device ?? FakeDeviceAccess(),
    gateway: cloud,
    gatewayFactory: (_, _) => cloud,
    saveCopy: (o, b) async {
      o.verify(b);
    },
  );
}

SelectedAttachment selection() => SelectedAttachment(
  name: 'synthetic.pdf',
  size: fixture.length,
  readBytes: () async => fixture,
);

void main() {
  test(
    'a different cloud connection cannot inherit a previous ready receipt',
    () async {
      final repo = MemoryOriginals(), cloud = FakeDocuments();
      final vm = model(repo, cloud);
      addTearDown(vm.dispose);
      await vm.importSelected(selection(), 'files');
      await vm.upload(vm.originals.single);
      expect(vm.isCurrentDestination(vm.originals.single), isTrue);
      final other = FakeDocuments()..destinationId = 'different-storage';
      vm.connect(other);
      expect(vm.isCurrentDestination(vm.originals.single), isFalse);
      await vm.verifyCloud(vm.originals.single);
      expect(vm.error, 'connection');
      await vm.upload(vm.originals.single);
      expect(vm.isCurrentDestination(vm.originals.single), isTrue);
      expect(repo.original!.cloudDestination, 'different-storage');
    },
  );
  test(
    'lost local response retries the same import; pending upload can resume',
    () async {
      final repo = MemoryOriginals()..failAfterCommit = true;
      final cloud = FakeDocuments()..failUpload = true;
      final vm = model(repo, cloud);
      addTearDown(vm.dispose);
      await vm.importSelected(selection(), 'files');
      expect(vm.error, 'failed');
      expect(vm.canRetryImport, isTrue);
      await vm.retryImport();
      expect(repo.inserts, 1);
      expect(vm.originals, hasLength(1));
      await vm.upload(vm.originals.single);
      expect(vm.error, 'cloud');
      expect(repo.original!.cloudState, OriginalCloudState.pending);
      await vm.upload(vm.originals.single);
      expect(repo.original!.cloudState, OriginalCloudState.ready);
      expect(cloud.ids.toSet(), hasLength(1));
      cloud.corruptDownload = true;
      await vm.verifyCloud(vm.originals.single);
      expect(vm.error, 'integrity');
      expect(vm.notice, isNull);
    },
  );
  test(
    'oversized and unsupported selection do not create an original',
    () async {
      final repo = MemoryOriginals();
      final vm = model(repo, FakeDocuments());
      addTearDown(vm.dispose);
      var read = false;
      await vm.importSelected(
        SelectedAttachment(
          name: 'large.pdf',
          size: maxOriginalBytes + 1,
          readBytes: () async {
            read = true;
            return fixture;
          },
        ),
        'files',
      );
      expect(read, isFalse);
      expect(vm.error, 'too_large');
      expect(repo.original, isNull);
      await vm.importSelected(
        SelectedAttachment(
          name: 'not-a-pdf.pdf',
          size: 3,
          readBytes: () async => Uint8List.fromList([1, 2, 3]),
        ),
        'files',
      );
      expect(vm.error, 'unsupported');
      expect(repo.original, isNull);
    },
  );
  for (final ru in [false, true]) {
    testWidgets(
      'import, explicit cloud upload and verification ${ru ? 'RU dark' : 'EN light'}',
      (tester) async {
        tester.view.physicalSize = const Size(375, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = MemoryOriginals();
        final cloud = FakeDocuments();
        final device = FakeDeviceAccess()..selection = selection();
        final vm = model(repo, cloud, device: device);
        addTearDown(vm.dispose);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(ru ? 'ru' : 'en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            builder: (context, child) => UnobstructedPane(child: child!),
            supportedLocales: AppLocalizations.supportedLocales,
            theme: ru ? AppTheme.dark : AppTheme.light,
            home: OriginalsPage(model: vm),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('import-original')));
        await tester.pumpAndSettle();
        expect(find.text('synthetic.pdf'), findsOneWidget);
        expect(cloud.ids, isEmpty);
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.displayFeatures = const [
          DisplayFeature(
            bounds: Rect.fromLTWH(490, 0, 20, 800),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ];
        await tester.pumpAndSettle();
        tester.view.displayFeatures = const [];
        tester.view.physicalSize = const Size(844, 390);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        final upload = find.text(ru ? 'Загрузить в облако' : 'Upload to cloud');
        await tester.ensureVisible(upload);
        await tester.tap(upload);
        await tester.pumpAndSettle();
        expect(repo.original!.cloudState, OriginalCloudState.ready);
        final verify = find.text(
          ru ? 'Скачать и проверить' : 'Download and verify',
        );
        await tester.ensureVisible(verify);
        await tester.tap(verify);
        await tester.pumpAndSettle();
        expect(
          find.text(
            ru
                ? 'Скачанные байты совпадают с SHA-256 оригинала.'
                : 'Downloaded bytes match the original SHA-256.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
