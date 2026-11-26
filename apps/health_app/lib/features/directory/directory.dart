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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(widget.doctors ? l.nearbyDoctors : l.labsTitle),
                const SizedBox(height: 12),
                AppSelect<DirectoryCity>(
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
                ),
                const SizedBox(height: 12),
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
                Text(
                  model.origin == null
                      ? l.directoryNeedPoint
                      : l.directorySorted,
                  style: TextStyle(color: p.secondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                if (widget.doctors) ...[
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
                TextField(
                  key: Key(
                    widget.doctors
                        ? 'directory-doctor-search'
                        : 'directory-lab-search',
                  ),
                  controller: searchController,
                  onChanged: (value) =>
                      model.setQuery(value, doctors: widget.doctors),
                  decoration: InputDecoration(
                    labelText: widget.doctors
                        ? l.directoryDoctorSearch
                        : l.directoryLabSearch,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l.close,
                            onPressed: () {
                              searchController.clear();
                              model.setQuery('', doctors: widget.doctors);
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
                if (!widget.doctors) ...[
                  const SizedBox(height: 8),
                  ExpansionTile(
                    // Its bool must not share storage with text scroll offsets.
                    key: const PageStorageKey('directory-test-selection'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.directoryChooseTests),
                    children: [
                      Text(
                        l.directoryTestSearchNotice,
                        style: TextStyle(color: p.secondary, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final test in model.availableTests(
                              l.localeName,
                            ))
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: FilterChip(
                                  label: Text(
                                    test.label.inLanguage(l.localeName),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  selected: model.testIds.contains(test.id),
                                  onSelected: (_) => model.toggleTest(test.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                  if (model.testIds.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final test
                            in model
                                .availableTests(l.localeName)
                                .where((t) => model.testIds.contains(t.id)))
                          InputChip(
                            label: Text(test.label.inLanguage(l.localeName)),
                            onDeleted: () => model.toggleTest(test.id),
                          ),
                      ],
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (model.linkFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                l.directoryLinkFailed,
                style: TextStyle(color: p.secondary),
              ),
            ),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(l.directoryResults(hits.length)),
                const SizedBox(height: 8),
                Text(
                  l.directorySnapshot(
                    DateFormat.yMMMd(l.localeName)
                        .format(model.catalog.checkedAt),
                  ),
                  style: TextStyle(color: p.secondary, fontSize: 13),
                ),
                if (model.refreshCatalog != null) ...[
                  TextButton.icon(
                    onPressed: model.isRefreshing ? null : model.refresh,
                    icon: model.isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                const SizedBox(height: 16),
                if (model.outsideCoverage)
                  Text(l.directoryOutsideCoverage)
                else if (hits.isEmpty)
                  Text(l.directoryEmpty),
                for (final hit in hits) _ProviderCard(hit: hit, model: model),
                const SizedBox(height: 8),
                Text(
                  l.directoryCoverage,
                  style: TextStyle(color: p.secondary, fontSize: 13),
                ),
                TextButton(
                  onPressed: () => model.open(
                    Uri.parse('https://www.openstreetmap.org/copyright'),
                  ),
                  child: Text(l.directoryMapAttribution),
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
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: p.paper,
        border: Border.all(color: p.line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doctor?.name ?? branch.name,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          if (doctor != null) ...[
            const SizedBox(height: 4),
            Text(
              doctor.specialty,
              style: TextStyle(color: p.accent, fontWeight: FontWeight.w600),
            ),
            Text(branch.name, style: TextStyle(color: p.secondary)),
          ],
          const SizedBox(height: 8),
          SelectableText(branch.address),
          Text(
            l.directorySourceChecked(
              DateFormat.yMMMd(l.localeName).format(branch.checkedAt),
            ),
            style: TextStyle(color: p.secondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            distanceLabel,
            key: ValueKey('distance-${hit.id}'),
            style: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
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
              OutlinedButton.icon(
                onPressed: () => model.open(
                  Uri(
                    scheme: 'tel',
                    path: branch.phone.replaceAll(RegExp(r'[^+0-9]'), ''),
                  ),
                ),
                icon: const Icon(Icons.phone_outlined, size: 18),
                label: Text(branch.phone),
              ),
              if (doctor == null && branch.testsUrl != null)
                TextButton(
                  onPressed: () => model.open(branch.testsUrl!),
                  child: Text(l.directoryAllTests),
                ),
              TextButton(
                onPressed: () => model.open(doctor?.source ?? branch.source),
                child: Text(l.directorySource),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l.directoryContactNotice,
            style: TextStyle(color: p.secondary, fontSize: 12),
          ),
          SelectableText(
            (doctor?.source ?? branch.website).toString(),
            style: TextStyle(color: p.secondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
