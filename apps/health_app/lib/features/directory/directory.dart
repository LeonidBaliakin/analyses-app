import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../presentation/reference_widgets.dart';
import '../device_access/device_access.dart';

class DirectoryPage extends StatefulWidget {
  const DirectoryPage({this.doctors = false, super.key});
  final bool doctors;
  @override
  State<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends State<DirectoryPage> {
  String query = '';
  final searchController = TextEditingController();
  final Set<int> selected = {0, 1};
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final deviceAccess = DeviceAccessScope.of(context);
    return DemoPage(
      children: [
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(widget.doctors ? l.nearbyDoctors : l.labsTitle),
              const SizedBox(height: 10),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: p.accent),
                  ListenableBuilder(
                    listenable: deviceAccess,
                    builder: (context, _) => Text(
                      locationLabel(l, deviceAccess),
                      style: TextStyle(fontSize: 12, color: p.secondary),
                    ),
                  ),
                  TextButton(
                    key: const Key('choose-directory-location'),
                    onPressed: () => showLocationSelection(context),
                    child: Text(l.change),
                  ),
                ],
              ),
              TextField(
                controller: searchController,
                onChanged: (value) =>
                    setState(() => query = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: widget.doctors ? l.specialistSearch : l.labSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              if (query.isNotEmpty)
                for (var i = 0; i < 4; i++)
                  if (_options(widget.doctors)[i].toLowerCase().contains(query))
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_options(widget.doctors)[i]),
                      trailing: const Icon(Icons.add),
                      onTap: () => setState(() {
                        selected.add(i);
                        query = '';
                        searchController.clear();
                      }),
                    ),
              const SizedBox(height: 14),
              if (!widget.doctors)
                OutlinedButton(
                  onPressed: () =>
                      setState(() => selected.addAll([0, 1, 2, 3])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.basicSet,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l.basicSetHint,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SectionHeading(
                widget.doctors ? l.selectedSpecialists : l.testList,
              ),
              const SizedBox(height: 8),
              for (final i in selected)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 3, 0, 3),
                  margin: const EdgeInsets.only(bottom: 7),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.doctors
                              ? [
                                  'терапевт',
                                  'эндокринолог',
                                  'кардиолог',
                                  'гематолог',
                                ][i]
                              : [
                                  'Общий анализ крови с лейкоцитарной формулой',
                                  'Ферритин',
                                  'Глюкоза',
                                  'Витамин D',
                                ][i],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: l.close,
                        onPressed: () => setState(() => selected.remove(i)),
                        icon: Icon(Icons.close, size: 16, color: p.accent),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PaperCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(widget.doctors ? l.nearbyDoctors : l.nearbyLabs),
              const SizedBox(height: 12),
              for (var i = 0; i < (widget.doctors ? 4 : 6); i++)
                _DirectoryCard(index: i, doctor: widget.doctors),
              const SizedBox(height: 10),
              Text(
                '${l.demoDirectory} ${l.directoryLocationPreview}',
                style: TextStyle(fontSize: 11.5, color: p.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

List<String> _options(bool doctors) => doctors
    ? ['терапевт', 'эндокринолог', 'кардиолог', 'гематолог']
    : [
        'Общий анализ крови с лейкоцитарной формулой',
        'Ферритин',
        'Глюкоза',
        'Витамин D',
      ];

List<String> _names(bool doctor) => doctor
    ? ['Смирнова О. А.', 'Кузнецов И. В.', 'Петрова Е. В.', 'Орлова Н. С.']
    : [
        'МедЛаб Центр',
        'БиоТест',
        'Лаборатория «Невская»',
        'Анализ-Экспресс',
        'ДиаЛаб на Петроградской',
        'Клиника на Литейном',
      ];
List<String> _subtitles(bool doctor) => doctor
    ? [
        'терапевт · стаж 14 лет',
        'терапевт · стаж 9 лет',
        'эндокринолог · стаж 18 лет',
        'эндокринолог · стаж 11 лет',
      ]
    : [
        'Лиговский пр., 45 · 7:00–19:00',
        'ул. Типанова, 21 · 8:00–18:00',
        'ул. Марата, 12 · 7:30–20:00',
        'Невский пр., 88 · круглосуточно',
        'Большой пр. П.С., 30 · 7:30–19:30',
        'Литейный пр., 51 · 8:00–21:00',
      ];

class _DirectoryCard extends StatelessWidget {
  const _DirectoryCard({required this.index, required this.doctor});
  final int index;
  final bool doctor;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), p = OrangePalette.of(context);
    final color = doctor
        ? p.accent
        : index == 0
        ? OrangePalette.orange
        : index == 1
        ? p.green
        : index == 2
        ? p.blue
        : p.line;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: doctor || index > 2 ? 1 : 2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                _names(doctor)[index],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!doctor && index < 3)
                StatusPill(
                  label: [l.bestChoice, l.lowestPrice, l.nearest][index],
                  color: color,
                  background: color.withValues(alpha: .1),
                ),
            ],
          ),
          Text(
            _subtitles(doctor)[index],
            style: TextStyle(fontSize: 12, color: p.muted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${doctor ? [2200, 1800, 3200, 2600][index] : [1140, 990, 1390, 1170, 1120, 1330][index]} ₽',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${[1.6, 9.4, .8, 1.1, 4.2, 1.9][index]} км',
                style: TextStyle(color: p.secondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (doctor)
            TextButton(
              onPressed: () => showUnavailable(context, l.whatTests),
              child: Text(l.whatTests),
            ),
          FilledButton(
            onPressed: () => showUnavailable(context, l.bookWebsite),
            child: Text(l.bookWebsite),
          ),
        ],
      ),
    );
  }
}
