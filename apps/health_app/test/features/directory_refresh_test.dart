import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/directory/directory.dart';
import 'package:provider_directory/provider_directory.dart';

void main() {
  test(
    'refresh preserves city, selected tests, query and confirmed origin',
    () async {
      final initial = bundledDirectory();
      final model = DirectoryViewModel(
        catalog: initial,
        refreshCatalog: () async => bundledDirectory(),
      );
      addTearDown(model.dispose);
      model.selectCity(DirectoryCity.voronezh);
      final selected = model.availableTests('ru').first.id;
      model.toggleTest(selected);
      model.setQuery('Хеликс', doctors: false);
      model.selectNetwork('helix');
      model.setOrigin('Synthetic origin', GeoPoint(51.7, 39.2));
      await model.refresh();
      expect(model.city, DirectoryCity.voronezh);
      expect(model.testIds, {selected});
      expect(model.labQuery, 'Хеликс');
      expect(model.networkId, 'helix');
      expect(model.originLabel, 'Synthetic origin');
      expect(model.refreshFailed, isFalse);
    },
  );
  test('network failure retains usable cached data and dispose fences asynchronous updates', () async {
    final cached = bundledDirectory();
    final model = DirectoryViewModel(
      catalog: cached,
      loadCachedCatalog: () async => cached,
      refreshCatalog: () async => throw const FormatException('offline'),
    );
    await model.refresh();
    expect(model.catalog, same(cached));
    expect(model.refreshFailed, isTrue);
    model.dispose();
    final pending = Completer<ProviderCatalog?>();
    final disposed = DirectoryViewModel(
      catalog: cached,
      refreshCatalog: () => pending.future,
    );
    final running = disposed.refresh();
    await Future<void>.delayed(Duration.zero);
    disposed.dispose();
    pending.complete(cached);
    await running;
  });
}
