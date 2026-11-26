import 'dart:convert';
import 'dart:math' as math;

import 'package:medical_terminology/medical_terminology.dart';

enum DirectoryCity { spb, voronezh }

/// WGS84 coordinates; never substitute missing coordinates with zeroes.
final class GeoPoint {
  GeoPoint(this.latitude, this.longitude) {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180) {
      throw ArgumentError('Invalid coordinates');
    }
  }
  final double latitude;
  final double longitude;

  double distanceTo(GeoPoint other) {
    const radians = math.pi / 180;
    final dLat = (other.latitude - latitude) * radians;
    final dLon = (other.longitude - longitude) * radians;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(latitude * radians) *
            math.cos(other.latitude * radians) *
            math.pow(math.sin(dLon / 2), 2);
    return 6371008.8 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
  }
}

String directorySearchText(String value) => value
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

final class ProviderBranch {
  ProviderBranch.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      network = j['network'] as String,
      city = DirectoryCity.values.byName(j['city'] as String),
      name = j['name'] as String,
      address = j['address'] as String,
      phone = j['phone'] as String,
      website = _web(j['website']),
      source = _web(j['source']),
      checkedAt = DateTime.parse(j['checkedAt'] as String),
      point = j['lat'] == null || j['lon'] == null
          ? null
          : GeoPoint(
              (j['lat'] as num).toDouble(),
              (j['lon'] as num).toDouble(),
            ),
      coordinateSource = j['coordinateSource'] == null
          ? null
          : _web(j['coordinateSource']),
      testsUrl = j['testsUrl'] == null ? null : _web(j['testsUrl']);

  final String id, network, name, address, phone;
  final DirectoryCity city;
  final Uri website, source;
  final Uri? coordinateSource, testsUrl;
  final DateTime checkedAt;
  final GeoPoint? point;
}

final class ProviderDoctor {
  ProviderDoctor.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      name = j['name'] as String,
      specialty = j['specialty'] as String,
      network = j['network'] as String?,
      sourceId = j['sourceId'] as String?,
      checkedAt = j['checkedAt'] == null
          ? null
          : DateTime.parse(j['checkedAt'] as String),
      sourceSpecialties = List.unmodifiable(
        (j['sourceSpecialties'] as List? ?? [j['specialty']]).cast<String>(),
      ),
      familyName = j['familyName'] as String?,
      givenName = j['givenName'] as String?,
      patronymic = j['patronymic'] as String?,
      branchIds = List.unmodifiable((j['branchIds'] as List).cast<String>()),
      source = _web(j['source']);
  final String id, name, specialty;
  final String? network, sourceId, familyName, givenName, patronymic;
  final DateTime? checkedAt;
  final List<String> sourceSpecialties;
  final List<String> branchIds;
  final Uri source;

  /// Query forms within this identity; never used to merge people.
  String get nameSearchText =>
      givenName == null || patronymic == null || familyName == null
      ? name
      : '$name $familyName ${givenName![0]}.${patronymic![0]}. $familyName ${givenName![0]}. ${patronymic![0]}.';
}

/// A source-specific offering. City/network scope is not branch availability.
final class ProviderTest {
  ProviderTest.fromJson(Map<String, dynamic> j)
    : id = j['id'] as String,
      network = j['network'] as String,
      city = DirectoryCity.values.byName(j['city'] as String),
      name = j['name'] as String,
      sourceCode = j['sourceCode'] as String?,
      branchIds = List.unmodifiable(
        (j['branchIds'] as List? ?? []).cast<String>(),
      ),
      source = _web(j['source']);
  final String id, network, name;
  final String? sourceCode;
  final DirectoryCity city;
  final List<String> branchIds;
  final Uri source;
  bool appliesTo(ProviderBranch branch) => branchIds.isNotEmpty
      ? branchIds.contains(branch.id)
      : network == branch.network && city == branch.city;
}

final class DirectoryHit {
  const DirectoryHit(
    this.branch,
    this.distanceMeters,
    this.tests, {
    this.doctor,
    this.needsConfirmation = false,
  });
  final ProviderBranch branch;
  final ProviderDoctor? doctor;
  final double? distanceMeters;
  final List<ProviderTest> tests;
  final bool needsConfirmation;
  String get id => '${branch.id}:${doctor?.id ?? ''}';
}

final class DirectoryTestOption {
  const DirectoryTestOption(this.id, this.label);
  final String id;
  final TerminologyLabel label;
}

final class ProviderCatalog {
  ProviderCatalog.fromJson(
    Map<String, dynamic> j, {
    LaboratoryTestRelease? terminology,
    MedicalSpecialtyRelease? specialties,
  }) : terminology = terminology ?? bundledLaboratoryTests,
       specialties = specialties ?? bundledMedicalSpecialties,
       version = j['version'] as String,
       checkedAt = DateTime.parse(j['checkedAt'] as String),
       branches = List.unmodifiable(
         (j['branches'] as List).map(
           (v) => ProviderBranch.fromJson(v as Map<String, dynamic>),
         ),
       ),
       doctors = List.unmodifiable(
         (j['doctors'] as List).map(
           (v) => ProviderDoctor.fromJson(v as Map<String, dynamic>),
         ),
       ),
       tests = List.unmodifiable(
         (j['tests'] as List).map(
           (v) => ProviderTest.fromJson(v as Map<String, dynamic>),
         ),
       ) {
    final ids = branches.map((b) => b.id).toSet();
    if (j['schemaVersion'] != 1 ||
        (j['terminologyReleaseId'] != null &&
            j['terminologyReleaseId'] != this.terminology.id) ||
        (j['specialtyReleaseId'] != null &&
            j['specialtyReleaseId'] != this.specialties.id) ||
        ids.length != branches.length ||
        doctors.map((d) => d.id).toSet().length != doctors.length ||
        doctors
                .where((d) => d.sourceId != null)
                .map((d) => '${d.network}:${d.source}')
                .toSet()
                .length !=
            doctors.where((d) => d.sourceId != null).length ||
        tests.map((t) => t.id).toSet().length != tests.length ||
        doctors.any(
          (d) =>
              d.branchIds.isEmpty ||
              d.branchIds.any((id) => !ids.contains(id)) ||
              d.sourceSpecialties.isEmpty ||
              d.sourceSpecialties.any((s) => s.trim().isEmpty) ||
              [
                d.familyName,
                d.givenName,
                d.patronymic,
              ].any((s) => s != null && s.trim().isEmpty),
        ) ||
        tests.any((t) => t.branchIds.any((id) => !ids.contains(id)))) {
      throw const FormatException('Invalid directory snapshot');
    }
  }

  factory ProviderCatalog.decode(String text) =>
      ProviderCatalog.fromJson(jsonDecode(text) as Map<String, dynamic>);
  final String version;
  final LaboratoryTestRelease terminology;
  final MedicalSpecialtyRelease specialties;
  final DateTime checkedAt;
  final List<ProviderBranch> branches;
  final List<ProviderDoctor> doctors;
  final List<ProviderTest> tests;

  String _doctorNetwork(ProviderDoctor doctor) =>
      doctor.network ??
      branches.firstWhere((b) => doctor.branchIds.contains(b.id)).network;
  String specialtyId(ProviderDoctor doctor, String text) =>
      specialties
          .resolve(sourceSystem: _doctorNetwork(doctor), sourceText: text)
          ?.conceptId ??
      'source-specialty:${_doctorNetwork(doctor)}:$text';
  Set<String> doctorSpecialtyIds(ProviderDoctor doctor) => Set.unmodifiable(
    doctor.sourceSpecialties.map((s) => specialtyId(doctor, s)),
  );

  List<DirectoryTestOption> specialtyOptions(DirectoryCity city) {
    final branchIds = branches
        .where((b) => b.city == city)
        .map((b) => b.id)
        .toSet();
    final options = <String, DirectoryTestOption>{};
    for (final doctor in doctors.where(
      (d) => d.branchIds.any(branchIds.contains),
    )) {
      for (final text in doctor.sourceSpecialties) {
        final id = specialtyId(doctor, text);
        options[id] = DirectoryTestOption(
          id,
          specialties.concept(id)?.label ??
              TerminologyLabel(ru: text, en: text),
        );
      }
    }
    return List.unmodifiable(options.values);
  }

  LaboratoryTestMapping? mappingFor(ProviderTest test) => terminology.resolve(
    sourceSystem: test.network,
    sourceText: test.name,
    sourceCode: test.sourceCode,
  );

  /// Unreviewed formulations stay selectable without acquiring an inferred type.
  String testId(ProviderTest test) =>
      mappingFor(test)?.conceptId ?? 'source:${test.id}';

  List<DirectoryTestOption> testOptions(DirectoryCity city) {
    final options = <String, DirectoryTestOption>{};
    for (final test in tests.where((t) => t.city == city)) {
      final id = testId(test);
      options[id] = DirectoryTestOption(
        id,
        terminology.concept(id)?.label ??
            TerminologyLabel(ru: test.name, en: test.name),
      );
    }
    return List.unmodifiable(options.values);
  }

  String _testSearchText(ProviderTest test) =>
      '${test.name} ${terminology.searchText(testId(test))}';

  List<DirectoryHit> search({
    required DirectoryCity city,
    GeoPoint? origin,
    bool doctorsOnly = false,
    String query = '',
    Set<String> testIds = const {},
    String? specialtyId,
  }) {
    final words = directorySearchText(query)
        .split(' ')
        .where((w) => w.isNotEmpty);
    final wanted = testIds;
    final hits = <DirectoryHit>[];
    for (final branch in branches.where((b) => b.city == city)) {
      final offered = tests.where((t) => t.appliesTo(branch)).toList();
      final found = offered.map(testId).toSet();
      if (!wanted.every(found.contains)) continue;
      final distance = origin == null || branch.point == null
          ? null
          : origin.distanceTo(branch.point!);
      final people = doctorsOnly
          ? doctors.where((d) => d.branchIds.contains(branch.id)).toList()
          : <ProviderDoctor?>[null];
      for (final doctor in people) {
        final specialtyIds = doctor == null
            ? <String>{}
            : doctorSpecialtyIds(doctor);
        if (doctorsOnly &&
            specialtyId != null &&
            !specialtyIds.contains(specialtyId)) {
          continue;
        }
        final haystack = directorySearchText(
          [
            branch.name,
            branch.address,
            branch.network,
            if (doctor != null)
              '${doctor.nameSearchText} ${doctor.specialty} ${specialtyIds.map(specialties.searchText).join(' ')}',
            if (!doctorsOnly) ...offered.map(_testSearchText),
          ].join(' '),
        );
        if (!words.every(haystack.contains)) continue;
        final filtered = offered
            .where(
              (t) =>
                  wanted.contains(testId(t)) ||
                  (words.isNotEmpty &&
                      words.every(
                        directorySearchText(_testSearchText(t)).contains,
                      )),
            )
            .toList();
        hits.add(
          DirectoryHit(
            branch,
            distance,
            filtered,
            doctor: doctor,
            needsConfirmation:
                !doctorsOnly && filtered.any((t) => t.branchIds.isEmpty),
          ),
        );
      }
    }
    hits.sort((a, b) {
      final distance = (a.distanceMeters ?? double.infinity).compareTo(
        b.distanceMeters ?? double.infinity,
      );
      return distance != 0 ? distance : a.id.compareTo(b.id);
    });
    return List.unmodifiable(hits);
  }
}

Uri _web(Object? value) {
  final uri = Uri.parse(value as String);
  if (uri.scheme != 'https' || uri.host.isEmpty || uri.userInfo.isNotEmpty) {
    throw const FormatException('Invalid public source URL');
  }
  return uri;
}
