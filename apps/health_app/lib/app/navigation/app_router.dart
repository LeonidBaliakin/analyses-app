import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../features/capture/capture.dart';
import '../../features/device_access/device_access.dart';
import '../../features/directory/directory.dart';
import '../../features/documents/documents.dart';
import '../../features/introduction/introduction.dart';
import '../../features/profile/profile.dart';
import '../../features/records/records.dart';
import '../../features/settings/settings.dart';
import '../../features/sharing/sharing.dart';
import '../../features/summary/summary.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../presentation/demo_catalog.dart';
import '../shell/app_shell.dart';
import 'app_destination.dart';

GoRouter createAppRouter(
  SettingsViewModel settings,
  DemoCatalog catalog, {
  RecordsViewModel? records,
  ValueNotifier<bool>? showDemo,
  String? initialLocation,
}) {
  var introductionOpen = false;
  late final GoRouter router;
  Future<void> startIntroduction(BuildContext context) async {
    if (introductionOpen) return;
    introductionOpen = true;
    final origin = router.routeInformationProvider.value.uri.toString();
    try {
      await showAppIntroduction(
        context,
        onComplete: settings.completeIntroduction,
        onStepChanged: (step) => router.goNamed(switch (step) {
          IntroductionStep.profile => AppDestination.profile.name,
          IntroductionStep.reports => AppDestination.results.name,
          IntroductionStep.summary => AppDestination.summary.name,
          IntroductionStep.laboratories => AppDestination.labs.name,
          IntroductionStep.specialists ||
          IntroductionStep.appointment => AppDestination.doctors.name,
        }),
      );
    } finally {
      introductionOpen = false;
      if (context.mounted) router.go(origin);
    }
  }

  Widget page(RecordsSection section, Widget demo) => records == null
      ? demo
      : ValueListenableBuilder<bool>(
          valueListenable: showDemo!,
          builder: (context, example, _) =>
              example ? demo : RecordsPage(model: records, section: section),
        );
  router = GoRouter(
    initialLocation: initialLocation,
    restorationScopeId: 'app-router',
    routes: [
      StatefulShellRoute.indexedStack(
        restorationScopeId: 'main-shell',
        builder: (context, state, shell) => DeviceAccessIntroduction(
          onReady: () async {
            if (!settings.preferences.introductionCompleted &&
                settings.error != SettingsError.load) {
              await startIntroduction(context);
            }
          },
          child: AppShell(
            navigationShell: shell,
            settings: settings,
            onAdd: records == null
                ? null
                : () {
                    if (showDemo!.value) {
                      showAddAnalysis(context);
                      return;
                    }
                    if (records.profile == null) {
                      showRecordEditor(context, records, RecordKind.profile);
                    } else {
                      showAddAnalysis(
                        context,
                        onManualEntry: () => showRecordEditor(
                          context,
                          records,
                          RecordKind.result,
                        ),
                      );
                    }
                  },
            modeControl: records == null
                ? null
                : ValueListenableBuilder<bool>(
                    valueListenable: showDemo!,
                    builder: (context, example, _) {
                      final l = AppLocalizations.of(context);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => showDemo.value = !example,
                            child: Text(example ? l.localBack : l.localExample),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.summary.path,
                name: AppDestination.summary.name,
                builder: (context, state) => page(
                  RecordsSection.summary,
                  SummaryPage(
                    catalog: catalog,
                    onShowDoctor: () =>
                        context.goNamed(AppDestination.sharing.name),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.results.path,
                name: AppDestination.results.name,
                builder: (context, state) => page(
                  RecordsSection.results,
                  DocumentsPage(
                    catalog: catalog,
                    onAdd: () => showAddAnalysis(context),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.labs.path,
                name: AppDestination.labs.name,
                builder: (context, state) => const DirectoryPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.doctors.path,
                name: AppDestination.doctors.name,
                builder: (context, state) => const DirectoryPage(doctors: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.profile.path,
                name: AppDestination.profile.name,
                builder: (context, state) =>
                    page(RecordsSection.profile, ProfilePage(catalog: catalog)),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.sharing.path,
                name: AppDestination.sharing.name,
                builder: (context, state) => SharingPage(catalog: catalog),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.settings.path,
                name: AppDestination.settings.name,
                builder: (context, state) => SettingsPage(
                  viewModel: settings,
                  onStartIntroduction: () => startIntroduction(context),
                  onClose: () => context.goNamed(AppDestination.summary.name),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppDestination.documents.path,
        redirect: (context, state) => AppDestination.results.path,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: Center(
          child: FilledButton(
            onPressed: () => context.goNamed(AppDestination.summary.name),
            child: Text(AppLocalizations.of(context).returnToSummary),
          ),
        ),
      ),
    ),
  );
  return router;
}
