import 'package:design_system/design_system.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider_directory/provider_directory.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../presentation/reference_widgets.dart';
import '../device_access/device_access.dart';
import 'src/directory_view_model.dart';

export 'src/directory_view_model.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({
    this.doctors = false,
    this.model,
    this.requestLocationOnOpen = true,
    super.key,
  });
  final bool doctors;
  final DirectoryViewModel? model;

  /// The app shell handles session prompts after onboarding and navigation.
  final bool requestLocationOnOpen;
  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  late final model =
      widget.model ?? DirectoryViewModel(catalog: bundledDirectory());
  late final searchController = TextEditingController(
    text: widget.doctors ? model.doctorQuery : model.labQuery,
  );
  DeviceAccessViewModel? _device;
  bool _locationScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final device = DeviceAccessScope.of(context);
    if (_device != device) {
      _device?.removeListener(_syncLocation);
      _device = device;
      device.addListener(_syncLocation);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncLocation();
      });
    }
    if (_locationScheduled || !widget.requestLocationOnOpen) return;
    _locationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) showLocationSelection(context, prepareSession: true);
    });
  }

  void _syncLocation() {
    final location = _device?.location;
    final coordinates = location?.coordinates;
    GeoPoint? point;
    if (coordinates != null &&
        (location!.source == LocationSource.gps || location.isAddressPoint)) {
      try {
        point = GeoPoint(coordinates.latitude, coordinates.longitude);
      } on ArgumentError {
        /* An invalid platform point has no distance. */
      }
    }
    model.setOrigin(location?.address, point);
  }

  @override
  void dispose() {
    _device?.removeListener(_syncLocation);
    searchController.dispose();
    if (widget.model == null) model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final l = AppLocalizations.of(context), p = OrangePalette.of(context);
      final hits = model.hits(doctors: widget.doctors);
      return ReferencePage(
        children: [
          PaperCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(widget.doctors ? l.nearbyDoctors : l.labsTitle),
                ListenableBuilder(
                  listenable: _device!,
                  builder: (context, _) => Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: p.accent,
                        size: 20,
                      ),
                      Text(
                        locationLabel(l, _device!),
                        style: TextStyle(color: p.secondary),
                      ),
                      TextButton.icon(
                        key: const Key('choose-directory-location'),
                        onPressed: () => showLocationSelection(context),
                        icon: const Icon(
                          Icons.edit_location_alt_outlined,
                          size: 20,
                        ),
                        label: Text(l.change),
                      ),
                    ],
                  ),
                ),

                if (model.origin == null)
                  Text(
                    l.directoryNeedPoint,
                    style: TextStyle(fontSize: 11, color: p.secondary),
                  ),
                SpotlightAnchor(
                  id: widget.doctors ? 'doctor-search' : 'lab-search',
                  child: TextField(
                    key: Key(
                      widget.doctors
                          ? 'directory-doctor-search'
                          : 'directory-lab-search',
                    ),
                    controller: searchController,
                    onChanged: (v) =>
                        model.setQuery(v, doctors: widget.doctors),
                    decoration: InputDecoration(
                      hintText: widget.doctors
                          ? l.directoryDoctorSearch
                          : l.directoryLabSearch,
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l.close,
                              onPressed: () {
                                searchController.clear();
                                model.setQuery('', doctors: widget.doctors);
                              },
                              icon: const Icon(Icons.close, size: 18),
                            ),
                    ),
                  ),
                ),
                if (!widget.doctors && model.labQuery.isNotEmpty) ...[
                  for (final test in model.suggestTests(l.localeName).take(10))
                    ListTile(
                      dense: true,
                      title: Text(
                        test.label.inLanguage(l.localeName),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        model.toggleTest(test.id);
                        searchController.clear();
                        model.setQuery('', doctors: false);
                      },
                    ),
                ],
                const SizedBox(height: 12),
                QuietFold(
                  key: PageStorageKey(
                    widget.doctors
                        ? 'directory-specialty-selection'
                        : 'directory-test-selection',
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.doctors
                              ? l.selectedSpecialties
                              : l.testsToTake,
                        ),
                      ),
                      StatusPill(
                        label:
                            '${widget.doctors ? model.specialtyIds.length : model.testIds.length}',
                        color: p.accent,
                        background: p.accentSoft,
                      ),
                    ],
                  ),
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (widget.doctors)
                          for (final option in model.availableSpecialties(
                            l.localeName,
                          ))
                            OptionChip(
                              label: Text(
                                option.label.inLanguage(l.localeName),
                              ),
                              selected: model.specialtyIds.contains(option.id),
                              onSelected: (_) =>
                                  model.toggleSpecialty(option.id),
                            )
                        else
                          for (final option in model.availableTests(
                            l.localeName,
                          ))
                            OptionChip(
                              label: Text(
                                option.label.inLanguage(l.localeName),
                              ),
                              selected: model.testIds.contains(option.id),
                              onSelected: (_) => model.toggleTest(option.id),
                            ),
                      ],
                    ),
                  ],
                ),
                if (!widget.doctors)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: p.orangeSoft,
                        foregroundColor: const Color(0xFF893900),
                      ),
                      onPressed: model.selectBasicTests,
                      child: Text(l.basicTestSet),
                    ),
                  ),
                QuietFold(
                  key: const Key('directory-filters'),
                  compact: true,
                  title: Text(l.directoryFilters),
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final city = AppSelect<DirectoryCity>(
                          label: l.directoryCity,
                          value: model.city,
                          options: [
                            AppSelectOption(
                              value: DirectoryCity.spb,
                              label: l.directorySpb,
                            ),
                            AppSelectOption(
                              value: DirectoryCity.voronezh,
                              label: l.directoryVoronezh,
                            ),
                          ],
                          onChanged: model.selectCity,
                        );
                        final network = AppSelect<String?>(
                          key: const Key('directory-network'),
                          label: l.directoryNetwork,
                          value: model.networkId,
                          options: [
                            AppSelectOption(
                              value: null,
                              label: l.directoryAllNetworks,
                            ),
                            for (final id in model.availableNetworks)
                              AppSelectOption(
                                value: id,
                                label: model.networkLabel(id),
                              ),
                          ],
                          onChanged: model.selectNetwork,
                        );
                        if (constraints.maxWidth >= 600) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: city),
                              const SizedBox(width: 12),
                              Expanded(child: network),
                            ],
                          );
                        }
                        return Column(
                          children: [city, const SizedBox(height: 12), network],
                        );
                      },
                    ),

                    AppSelect<String?>(
                      key: const Key('directory-specialty'),
                      label: l.directorySpecialty,
                      value: model.specialtyId,
                      options: [
                        AppSelectOption(
                          value: null,
                          label: l.directoryAllSpecialties,
                        ),
                        for (final specialty in model.availableSpecialties(
                          l.localeName,
                        ))
                          AppSelectOption(
                            value: specialty.id,
                            label: specialty.label.inLanguage(l.localeName),
                          ),
                      ],
                      onChanged: model.selectSpecialty,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (model.linkFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(l.directoryLinkFailed),
            ),
          PaperCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionHeading(
                  widget.doctors
                      ? l.directoryResults(hits.length)
                      : l.nearbyLabs,
                ),
                const SizedBox(height: 12),
                if (model.outsideCoverage)
                  Text(l.directoryOutsideCoverage)
                else if (hits.isEmpty)
                  Text(l.directoryEmpty),
                for (final hit in hits) _ProviderCard(hit: hit, model: model),
                QuietFold(
                  key: const Key('directory-sources'),
                  title: Text(l.directorySource),
                  children: [
                    if (model.catalog.publishedAt case final publishedAt?) ...[
                      Text(
                        l.directoryPublished(
                          DateFormat.yMMMd(l.localeName)
                              .format(publishedAt.toLocal()),
                        ),
                        key: const Key('directory-publication-date'),
                        style: TextStyle(color: p.secondary, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      l.directorySnapshot(
                        DateFormat.yMMMd(l.localeName)
                            .format(model.catalog.checkedAt),
                      ),
                      style: TextStyle(color: p.secondary, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.directoryPublicationNotice,
                      style: TextStyle(color: p.secondary, fontSize: 13),
                    ),
                    if (model.refreshCatalog != null) ...[
                      TextButton.icon(
                        onPressed: model.isRefreshing ? null : model.refresh,
                        icon: model.isRefreshing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh),
                        label: Text(l.directoryRefresh),
                      ),
                      if (model.refreshFailed)
                        Text(
                          l.directoryRefreshFailed,
                          style: TextStyle(color: p.secondary, fontSize: 13),
                        ),
                    ],

                    Text(
                      l.directoryCoverage,
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                    TextButton(
                      onPressed: () => model.open(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                      ),
                      child: Text(l.directoryMapAttribution),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.hit, required this.model});
  final DirectoryHit hit;
  final DirectoryViewModel model;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final branch = hit.branch, doctor = hit.doctor;
    final phone = branch.phone.replaceAll(RegExp(r'[^+0-9]'), '');
    final hasPhone = phone.contains(RegExp(r'[0-9]'));
    final distance = hit.distanceMeters;
    final distanceLabel = distance == null
        ? l.directoryUnknownDistance
        : distance < 1000
        ? l.directoryMeters(NumberFormat('0', l.localeName).format(distance))
        : l.directoryKilometers(
            NumberFormat('0.0', l.localeName).format(distance / 1000),
          );
    return Container(
      key: ValueKey('provider-${hit.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.card,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  doctor == null
                      ? Icons.science_outlined
                      : Icons.medical_services_outlined,
                  color: p.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor?.name ?? branch.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (doctor != null)
                      Text(
                        doctor.specialty,
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                    Text(
                      '${doctor == null ? '' : '${branch.name}, '}${branch.address}',
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l.directoryPriceUnknown,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  distanceLabel,
                  key: ValueKey('distance-${hit.id}'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (hit.needsConfirmation) ...[
            const SizedBox(height: 8),
            Text(
              l.directoryAvailabilityUnknown,
              style: TextStyle(color: p.secondary, fontSize: 13),
            ),
          ],
          if (hit.tests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final test in hit.tests) ...[
                    TextButton(
                      onPressed: () => model.open(test.source),
                      child: Text(test.name),
                    ),
                    if (model.catalog.mappingFor(test)?.specification
                        case final specification?)
                      Material(
                        type: MaterialType.transparency,
                        child: ExpansionTile(
                          key: PageStorageKey(
                            'test-details-${hit.id}-${test.id}',
                          ),
                          tilePadding: EdgeInsets.zero,
                          title: Text(l.directoryTestDetails),
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${l.directorySpecimen}: ${specification.specimenText ?? l.directoryNotPublished}',
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '${l.directoryMethod}: ${specification.methodText ?? l.directoryNotPublished}',
                              ),
                            ),
                            if (specification.components.isNotEmpty)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${l.directoryComponents}: ${specification.components.values.join('; ')}',
                                ),
                              ),
                            if (specification.note != null)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(specification.note!),
                              ),
                            TextButton(
                              onPressed: () => model.open(specification.source),
                              child: Text(l.directorySource),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => model.open(doctor?.source ?? branch.website),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(l.bookWebsite),
              ),
            ],
          ),
          QuietFold(
            compact: true,
            title: Text(l.directoryContactsAndSource),
            children: [
              Text(
                l.directorySourceChecked(
                  DateFormat.yMMMd(l.localeName).format(branch.checkedAt),
                ),
                style: TextStyle(fontSize: 12, color: p.secondary),
              ),
              if (doctor != null)
                Text(
                  l.directoryDoctorChecked(
                    DateFormat.yMMMd(l.localeName)
                        .format(doctor.checkedAt ?? model.catalog.checkedAt),
                  ),
                  style: TextStyle(fontSize: 12, color: p.secondary),
                ),
              Wrap(
                spacing: 8,
                children: [
                  if (hasPhone)
                    OutlinedButton.icon(
                      onPressed: () =>
                          model.open(Uri(scheme: 'tel', path: phone)),
                      icon: const Icon(Icons.phone_outlined, size: 18),
                      label: Text(branch.phone),
                    ),
                  if (doctor == null && branch.testsUrl != null)
                    TextButton(
                      onPressed: () => model.open(branch.testsUrl!),
                      child: Text(l.directoryAllTests),
                    ),
                  TextButton(
                    onPressed: () =>
                        model.open(doctor?.source ?? branch.source),
                    child: Text(l.directorySource),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                !hasPhone
                    ? l.directoryPhoneUnavailable
                    : branch.phoneScope == 'network'
                    ? l.directoryNetworkPhone
                    : l.directoryContactNotice,
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
              SelectableText(
                (doctor?.source ?? branch.website).toString(),
                style: TextStyle(color: p.secondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
