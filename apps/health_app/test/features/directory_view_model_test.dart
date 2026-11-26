import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/features/directory/directory.dart';
import 'package:provider_directory/provider_directory.dart';

void main() {
  test(
    'specialty IDs filter doctors, retain aliases and clear on a city change',
    () {
      final model = DirectoryViewModel(catalog: bundledDirectory());
      addTearDown(model.dispose);
      model.selectSpecialty('specialty.surgery');
      expect(model.hits(doctors: true), hasLength(3));
      model.setQuery('Митин А.В.', doctors: true);
      expect(model.hits(doctors: true), hasLength(3));
      model.selectSpecialty('unknown');
      expect(model.specialtyId, 'specialty.surgery');
      model.selectCity(DirectoryCity.voronezh);
      expect(model.specialtyId, isNull);
      model.setQuery('гинекология', doctors: true);
      expect(
        model.hits(doctors: true).single.doctor!.name,
        'Дейнекина Юлия Михайловна',
      );
    },
  );
  test(
    'every test option selects reviewed source offers and clears independently',
    () {
      final model = DirectoryViewModel(catalog: bundledDirectory());
      addTearDown(model.dispose);
      for (final city in DirectoryCity.values) {
        model.selectCity(city);
        for (final option in model.availableTests('ru')) {
          model.toggleTest(option.id);
          expect(model.testIds, {option.id});
          final hits = model.hits(doctors: false);
          expect(hits, isNotEmpty, reason: option.id);
          expect(
            hits.every(
              (h) =>
                  h.tests.isNotEmpty &&
                  h.tests.every((t) => model.catalog.testId(t) == option.id),
            ),
            isTrue,
          );
          model.toggleTest(option.id);
          expect(model.testIds, isEmpty);
        }
      }
    },
  );
  test('confirmed point switches city and clearing coordinates removes old distances', () {
    final model = DirectoryViewModel(catalog: bundledDirectory());
    addTearDown(model.dispose);
    model.setOrigin(
      'Воронеж, Никитинская, 52',
      GeoPoint(51.663161383652, 39.189740436175),
    );
    expect(model.city, DirectoryCity.voronezh);
    expect(model.hits(doctors: false).first.branch.id, 'sova-nikitinskaya');
    expect(model.hits(doctors: false).first.distanceMeters, 0);
    model.setOrigin('Another unlocated address', null);
    expect(
      model.hits(doctors: false).every((h) => h.distanceMeters == null),
      isTrue,
    );
    expect(model.originLabel, 'Another unlocated address');
  });
  test('source-scoped selection, changing city and distant origin have explicit states', () {
    final model = DirectoryViewModel(catalog: bundledDirectory());
    addTearDown(model.dispose);
    model.toggleTest('test.ferritin');
    expect(model.hits(doctors: false), isNotEmpty);
    expect(
      model.hits(doctors: false).every((h) => h.needsConfirmation),
      isTrue,
    );
    model.selectCity(DirectoryCity.voronezh);
    expect(model.testIds, isEmpty);
    model.setQuery('невролог', doctors: true);
    expect(model.hits(doctors: true), isNotEmpty);
    model.setOrigin('Outside coverage', GeoPoint(55.75, 37.61));
    expect(model.outsideCoverage, isTrue);
    expect(model.hits(doctors: true), isEmpty);
  });
  test(
    'URL commands expose launch failures and reject unrelated schemes',
    () async {
      final opened = <Uri>[];
      final model = DirectoryViewModel(
        catalog: bundledDirectory(),
        openUrl: (uri) async {
          opened.add(uri);
          return false;
        },
      );
      addTearDown(model.dispose);
      await model.open(Uri.parse('https://example.org'));
      expect(model.linkFailed, isTrue);
      await model.open(Uri.parse('file:///private/test'));
      expect(opened, hasLength(1));
    },
  );
}
