import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../features/capture/capture.dart';
import '../../features/device_access/device_access.dart';
import '../../features/directory/directory.dart';
import '../../features/documents/documents.dart';
import '../../features/processing/processing.dart';
import '../../features/reports/reports.dart';
import '../../features/sync/sync.dart';
import '../../features/account/account.dart';
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
  OriginalsViewModel? originals,
  ProcessingViewModel? processing,
  ReportsViewModel? reports,
  SyncViewModel? sync,
  AccountViewModel? account,
  DirectoryViewModel? directory,
  ValueNotifier<bool>? showDemo,
  String? initialLocation,
}) {
  var introductionOpen = false;
  late final GoRouter router;
  Future<void> confirmDirectoryLocation(BuildContext context) async {
    if (introductionOpen || !context.mounted) return;
    final path = router.routeInformationProvider.value.uri.path;
    if (path == AppDestination.labs.path ||
        path == AppDestination.doctors.path) {
      await showLocationSelection(context, prepareSession: true);
    }
  }

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
          builder: (context, example, _) => example
              ? demo
              : RecordsPage(
                  model: records,
                  section: section,
                  reports: reports,
                  sync: sync,
                  onOpenReport: () =>
                      router.goNamed(AppDestination.sharing.name),
                  onOpenSync: sync == null ? null : () => router.go('/sync'),
                  onOpenOriginals: originals == null
                      ? null
                      : () => router.goNamed(AppDestination.documents.name),
                ),
        );
  router = GoRouter(
    initialLocation: initialLocation,
    restorationScopeId: 'app-router',
    routes: [
      if (account != null)
        GoRoute(
          path: '/account',
          builder: (context, state) => AccountPage(
            model: account,
            onClose: () => router.goNamed(AppDestination.settings.name),
            onOpenSync: () => router.go('/sync'),
          ),
        ),
      if (sync != null)
        GoRoute(
          path: '/sync',
          builder: (context, state) => SyncPage(
            model: sync,
            onClose: () => router.goNamed(AppDestination.summary.name),
          ),
        ),
      StatefulShellRoute.indexedStack(
        restorationScopeId: 'main-shell',
        builder: (context, state, shell) => DeviceAccessIntroduction(
          onReady: () async {
            if (!settings.preferences.introductionCompleted &&
                settings.error != SettingsError.load) {
              await startIntroduction(context);
            }
            if (context.mounted) await confirmDirectoryLocation(context);
          },
          child: AppShell(
            navigationShell: shell,
            settings: settings,
            onDirectoryOpened: () => confirmDirectoryLocation(context),
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
                builder: (context, state) => DirectoryPage(
                  model: directory,
                  requestLocationOnOpen: false,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.doctors.path,
                name: AppDestination.doctors.name,
                builder: (context, state) => DirectoryPage(
                  doctors: true,
                  model: directory,
                  requestLocationOnOpen: false,
                ),
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
                builder: (context, state) => reports == null
                    ? SharingPage(catalog: catalog)
                    : ValueListenableBuilder<bool>(
                        valueListenable: showDemo!,
                        builder: (context, example, _) => example
                            ? SharingPage(catalog: catalog)
                            : ReportsPage(model: reports),
                      ),
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
                  onOpenAccount: account == null
                      ? null
                      : () => router.go('/account'),
                  onClose: () => context.goNamed(AppDestination.summary.name),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppDestination.documents.path,
        name: AppDestination.documents.name,
        redirect: originals == null
            ? (context, state) => AppDestination.results.path
            : null,
        builder: (context, state) => OriginalsPage(
          model: originals!,
          processing: processing,
          onClose: () => router.goNamed(AppDestination.results.name),
        ),
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
