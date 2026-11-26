import 'package:provider_directory/provider_directory.dart';
import 'package:test/test.dart';

Map<String, dynamic> branch(
  String id,
  double? lat,
  double? lon, {
  String city = 'spb',
}) => {
  'id': id,
  'network': 'synthetic',
  'city': city,
  'name': 'Synthetic $id',
  'address': 'Synthetic address $id',
  'phone': '+7 000 000 00 00',
  'website': 'https://example.org/$id',
  'source': 'https://example.org/$id',
  'checkedAt': '2026-11-26',
  'lat': lat,
  'lon': lon,
};
Map<String, dynamic> fixture() => {
  'schemaVersion': 1,
  'version': 'synthetic-v1',
  'checkedAt': '2026-11-26',
  'branches': [
    branch('z-near', 59.93, 30.330001),
    branch('a-further', 59.93, 30.330002),
    branch('unknown', null, null),
    branch('voronezh', 51.67, 39.2, city: 'voronezh'),
  ],
  'doctors': [
    {
      'id': 'd',
      'name': 'Synthetic Doctor',
      'specialty': 'specialist',
      'branchIds': ['z-near', 'a-further'],
      'source': 'https://example.org/doctor',
    },
  ],
  'tests': [
    {
      'id': 't',
      'network': 'synthetic',
      'city': 'spb',
      'name': 'Ферритин',
      'branchIds': <String>[],
      'source': 'https://example.org/test',
    },
    {
      'id': 't2',
      'network': 'synthetic',
      'city': 'spb',
      'name': 'Глюкоза',
      'branchIds': ['z-near'],
      'source': 'https://example.org/test2',
    },
  ],
};

void main() {
  test(
    'verified specialties and initials find all practices of the same doctor',
    () {
      final catalog = bundledDirectory();
      final hits = catalog.search(
        city: DirectoryCity.spb,
        doctorsOnly: true,
        specialtyId: 'specialty.traumatology-orthopedics',
        query: 'Митин А.В.',
      );
      expect(hits, hasLength(3));
      expect(hits.map((h) => h.doctor!.id).toSet(), {'sm-mitin'});
      expect(catalog.doctorSpecialtyIds(hits.first.doctor!), {
        'specialty.surgery',
        'specialty.traumatology-orthopedics',
        'specialty.plastic-surgery',
        'specialty.arthrology',
      });
      expect(
        catalog.search(
          city: DirectoryCity.spb,
          doctorsOnly: true,
          query: 'ортопедия',
        ),
        hasLength(3),
      );
      expect(
        catalog.search(
          city: DirectoryCity.voronezh,
          doctorsOnly: true,
          query: 'Neurologist',
        ),
        hasLength(2),
      );
      for (final doctor in catalog.doctors) {
        expect(doctor.checkedAt, DateTime(2026, 11, 27));
        expect(doctor.sourceId, isNotEmpty);
        expect(
          catalog
              .doctorSpecialtyIds(doctor)
              .every((id) => id.startsWith('specialty.')),
          isTrue,
        );
      }
    },
  );
  test('same names stay separate identities and plastic surgery is not general surgery', () {
    final data = fixture();
    data['doctors'] = [
      for (final (id, role) in [
        ('general', 'Хирург'),
        ('plastic', 'Пластический хирург'),
      ])
        {
          'id': id,
          'network': 'smclinic',
          'sourceId': id,
          'name': 'Synthetic Doctor Name',
          'familyName': 'Synthetic',
          'givenName': 'Doctor',
          'patronymic': 'Name',
          'specialty': role,
          'sourceSpecialties': [role],
          'branchIds': ['z-near'],
          'source': 'https://example.org/$id',
        },
    ];
    final catalog = ProviderCatalog.fromJson(data);
    expect(
      catalog.search(
        city: DirectoryCity.spb,
        doctorsOnly: true,
        query: 'Synthetic D.N.',
      ),
      hasLength(2),
    );
    expect(
      catalog
          .search(
            city: DirectoryCity.spb,
            doctorsOnly: true,
            specialtyId: 'specialty.surgery',
          )
          .single
          .doctor!
          .id,
      'general',
    );
    (data['doctors'] as List)[1]['source'] = 'https://example.org/general';
    expect(() => ProviderCatalog.fromJson(data), throwsFormatException);
  });
  for (final type in [
    'test.tsh',
    'test.free-t4',
    'test.hba1c',
    'test.crp',
    'test.anti-hcv-total',
    'test.vitamin-d-25-oh',
  ]) {
    test('$type finds reviewed offers across laboratories in both cities', () {
      final catalog = bundledDirectory();
      for (final city in DirectoryCity.values) {
        final hits = catalog.search(city: city, testIds: {type});
        expect(
          hits.map((h) => h.branch.network).toSet(),
          city == DirectoryCity.spb
              ? {'helix', 'invitro'}
              : {'helix', 'invitro', 'sova'},
        );
        expect(
          catalog.testOptions(city).where((o) => o.id == type),
          hasLength(1),
        );
        expect(
          hits.every((h) => h.tests.every((t) => catalog.testId(t) == type)),
          isTrue,
        );
      }
    });
  }
  test(
    'every bundled offering has a reviewed type and every type filters by ID',
    () {
      final catalog = bundledDirectory();
      for (final city in DirectoryCity.values) {
        final options = catalog.testOptions(city);
        expect(options.map((o) => o.id).toSet(), hasLength(options.length));
        for (final option in options) {
          final expected = catalog.tests
              .where((t) => t.city == city && catalog.testId(t) == option.id)
              .toList();
          expect(expected, isNotEmpty);
          final selected = catalog.search(city: city, testIds: {option.id});
          expect(selected, isNotEmpty, reason: option.id);
          for (final offer in expected) {
            final mapping = catalog.mappingFor(offer);
            expect(mapping, isNotNull, reason: offer.id);
            expect(mapping!.sourceText, offer.name);
            expect(mapping.sourceCode, offer.sourceCode);
            final expectedBranches = catalog.branches
                .where(offer.appliesTo)
                .map((b) => b.id)
                .toSet();
            expect(
              selected.map((h) => h.branch.id).toSet(),
              containsAll(expectedBranches),
            );
            // A provider's own formulation must also discover the other reviewed variants.
            final queryHits = catalog
                .search(city: city, query: offer.name)
                .map((h) => h.branch.id)
                .toSet();
            expect(
              queryHits,
              containsAll(selected.map((h) => h.branch.id)),
              reason: offer.name,
            );
          }
          expect(
            selected.every(
              (h) => h.tests.every((t) => catalog.testId(t) == option.id),
            ),
            isTrue,
          );
        }
      }
      expect(
        catalog
            .search(city: DirectoryCity.voronezh, testIds: {'test.ferritin'})
            .map((h) => h.branch.network)
            .toSet(),
        {'helix', 'invitro'},
      );
      expect(
        catalog
            .search(
              city: DirectoryCity.voronezh,
              testIds: {'test.cbc-differential-no-esr'},
            )
            .map((h) => h.branch.network)
            .toSet(),
        {'helix', 'sova'},
      );
    },
  );

  test('all selected types must be offered; source-specific panels remain separate', () {
    final catalog = bundledDirectory();
    expect(
      catalog
          .search(
            city: DirectoryCity.voronezh,
            testIds: {'test.ferritin', 'test.hba1c'},
          )
          .map((h) => h.branch.network)
          .toSet(),
      {'helix', 'invitro'},
    );
    expect(
      catalog
          .search(
            city: DirectoryCity.voronezh,
            testIds: {
              'test.sova.coagulation',
              'test.sova.coagulation-expanded',
            },
          )
          .map((h) => h.branch.network)
          .toSet(),
      {'sova'},
    );
    expect(
      catalog.search(
        city: DirectoryCity.spb,
        testIds: {
          'test.scandinavia.cbc-expanded',
          'test.cbc-differential-no-esr',
        },
      ),
      isEmpty,
    );
  });
  test('one urinalysis selection finds different provider formulations', () {
    final hits = bundledDirectory().search(
      city: DirectoryCity.spb,
      testIds: {'test.urinalysis'},
    );
    expect(hits.map((h) => h.branch.network).toSet(), {
      'scandinavia',
      'smclinic',
      'helix',
      'invitro',
    });
    final catalog = bundledDirectory();
    for (final city in DirectoryCity.values) {
      final selected = catalog.search(
        city: city,
        testIds: {'test.urinalysis'},
        origin: GeoPoint(51.67, 39.2),
      );
      expect(selected, hasLength(city == DirectoryCity.spb ? 27 : 10));
      expect(selected.every((h) => h.needsConfirmation), isTrue);
      expect(
        selected.every(
          (h) => h.tests.every((t) => catalog.testId(t) == 'test.urinalysis'),
        ),
        isTrue,
      );
      expect(
        catalog.testOptions(city).where((o) => o.id == 'test.urinalysis'),
        hasLength(1),
      );
      for (final query in [
        'ОАМ',
        'Клинический анализ мочи',
        'Анализ мочи общий',
        'Urinalysis',
      ]) {
        expect(
          catalog
              .search(city: city, query: query)
              .map((h) => h.branch.id)
              .toSet(),
          selected.map((h) => h.branch.id).toSet(),
          reason: query,
        );
      }
      expect(
        selected.map((h) => h.distanceMeters).toList(),
        orderedEquals(
          selected.map((h) => h.distanceMeters).toList()
            ..sort((a, b) => a!.compareTo(b!)),
        ),
      );
    }
    expect(catalog.tests.every((t) => catalog.mappingFor(t) != null), isTrue);
    expect(
      catalog
          .search(city: DirectoryCity.spb, testIds: {'test.ferritin'})
          .map((h) => h.branch.network)
          .toSet(),
      {'helix', 'invitro'},
    );
  });
  test(
    'great-circle distance is symmetric and crosses date line correctly',
    () {
      final a = GeoPoint(0, 0), b = GeoPoint(0, 1);
      expect(a.distanceTo(a), 0);
      expect(a.distanceTo(b), closeTo(111195, 1));
      expect(a.distanceTo(b), b.distanceTo(a));
      expect(
        GeoPoint(0, 179).distanceTo(GeoPoint(0, -179)),
        closeTo(222390, 1),
      );
      expect(GeoPoint(0, 0).distanceTo(GeoPoint(0, 180)), closeTo(20015114, 1));
    },
  );
  test('invalid coordinates are rejected in release mode', () {
    for (final pair in [
      (double.nan, 0.0),
      (double.infinity, 0.0),
      (91.0, 0.0),
      (0.0, 181.0),
    ]) {
      expect(() => GeoPoint(pair.$1, pair.$2), throwsArgumentError);
    }
  });
  test(
    'sorts unrounded distances, city filters, unknowns last, stable ties',
    () {
      final catalog = ProviderCatalog.fromJson(fixture());
      final hits = catalog.search(
        city: DirectoryCity.spb,
        origin: GeoPoint(59.93, 30.33),
      );
      expect(hits.map((h) => h.branch.id), ['z-near', 'a-further', 'unknown']);
      expect(hits.first.distanceMeters, lessThan(1));
      expect(
        catalog.search(city: DirectoryCity.voronezh).single.branch.id,
        'voronezh',
      );
      expect(catalog.search(city: DirectoryCity.spb).map((h) => h.branch.id), [
        'a-further',
        'unknown',
        'z-near',
      ]);
    },
  );
  test('each physician practice is a separate proximity result', () {
    final hits = ProviderCatalog.fromJson(fixture()).search(
      city: DirectoryCity.spb,
      origin: GeoPoint(59.93, 30.33),
      doctorsOnly: true,
      query: 'doctor specialist',
    );
    expect(hits.map((h) => h.branch.id), ['z-near', 'a-further']);
    expect(hits.map((h) => h.id).toSet().length, 2);
    expect(hits.every((h) => h.doctor != null), isTrue);
  });
  test('network test is discoverable but never asserted at a branch', () {
    final catalog = ProviderCatalog.fromJson(fixture());
    final hits = catalog.search(city: DirectoryCity.spb, query: 'ферритин');
    expect(hits, hasLength(3));
    expect(hits.every((h) => h.needsConfirmation), isTrue);
    final confirmed = catalog.search(city: DirectoryCity.spb, query: 'глюкоза');
    expect(confirmed.single.branch.id, 'z-near');
    expect(confirmed.single.needsConfirmation, isFalse);
    expect(
      catalog
          .search(city: DirectoryCity.spb, testIds: {'source:t', 'source:t2'})
          .single
          .branch
          .id,
      'z-near',
    );
    expect(
      catalog.search(city: DirectoryCity.spb, testIds: {'source:t', 'Missing'}),
      isEmpty,
    );
  });
  test('broken references and unsafe public URLs reject the snapshot', () {
    final bad = fixture();
    (bad['doctors'] as List).first['branchIds'] = ['missing'];
    expect(() => ProviderCatalog.fromJson(bad), throwsFormatException);
    final unsafe = fixture();
    (unsafe['branches'] as List).first['website'] = 'javascript:alert(1)';
    expect(() => ProviderCatalog.fromJson(unsafe), throwsFormatException);
    final wrongRelease = fixture()
      ..['terminologyReleaseId'] = 'missing-release';
    expect(() => ProviderCatalog.fromJson(wrongRelease), throwsFormatException);
  });
  test('bundled public facts have both cities, sources, contacts and plausible points', () {
    final catalog = bundledDirectory();
    for (final city in DirectoryCity.values) {
      final branches = catalog.branches.where((b) => b.city == city).toList();
      expect(branches, isNotEmpty);
      expect(catalog.search(city: city, doctorsOnly: true), isNotEmpty);
      expect(catalog.tests.where((t) => t.city == city), isNotEmpty);
      for (final branch in branches) {
        expect(branch.address, isNotEmpty);
        expect(branch.phone, isNotEmpty);
        if (branch.point == null) {
          expect(branch.coordinateSource, isNull);
          expect({'medexpert', 'csp'}, contains(branch.network));
          continue;
        }
        expect(branch.coordinateSource, isNotNull);
        final point = branch.point!;
        expect(
          point.latitude,
          inInclusiveRange(
            city == DirectoryCity.spb ? 59.5 : 51.5,
            city == DirectoryCity.spb ? 60.3 : 51.9,
          ),
        );
        expect(
          point.longitude,
          inInclusiveRange(
            city == DirectoryCity.spb ? 29.5 : 39.0,
            city == DirectoryCity.spb ? 30.8 : 39.4,
          ),
        );
      }
    }
  });
}
