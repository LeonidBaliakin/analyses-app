import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:medical_domain/medical_domain.dart';

import '../../features/capture/capture.dart';
import '../../features/device_access/device_access.dart';
import '../../features/directory/directory.dart';
import '../../features/documents/documents.dart';
import '../../features/processing/processing.dart';
import '../../features/reports/reports.dart';
import '../../features/results/results.dart';
import '../../data/reports/export_report.dart';
import '../../data/reports/history_pdf.dart';
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
import '../../presentation/reference_widgets.dart';
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
  void closeHistory() {
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed(AppDestination.summary.name);
    }
  }

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
    var startUpload = false;
    try {
      await showAppIntroduction(
        context,
        onComplete: settings.completeIntroduction,
        onFinish: () => startUpload = true,
        onOpenStep: (step) async {
          final local = records != null && !showDemo!.value;
          switch (step) {
            case IntroductionStep.profile:
              if (local) {
                await showLocalProfileSection(
                  context,
                  records,
                  ProfileSection.base,
                );
              } else {
                await showDemoProfileSection(
                  context,
                  catalog,
                  ProfileSection.base,
                  onSaveAttempt: () async {
                    if (account != null) {
                      await router.push('/account');
                    } else if (context.mounted) {
                      await showUnavailable(
                        context,
                        AppLocalizations.of(context).signIn,
                      );
                    }
                  },
                );
              }
            case IntroductionStep.reports:
              await showAddAnalysis(
                context,
                showOtherRecords: false,
                onManualEntry: local
                    ? () => showRecordEditor(
                        context,
                        records,
                        records.profile == null
                            ? RecordKind.profile
                            : RecordKind.result,
                      )
                    : null,
              );
            case IntroductionStep.summary:
              if (local && reports != null) {
                await Navigator.of(context, rootNavigator: true).push<void>(
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      body: SafeArea(
                        child: ReportsPage(
                          model: reports,
                          onClose: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ),
                );
              } else {
                await showHistory(context, catalog, export: exportReport);
              }
            default:
              break;
          }
        },
        onStepChanged: (step) => router.goNamed(switch (step) {
          IntroductionStep.profile => AppDestination.profile.name,
          IntroductionStep.reports => AppDestination.results.name,
          IntroductionStep.summary => AppDestination.summary.name,
          IntroductionStep.laboratories => AppDestination.labs.name,
          IntroductionStep.specialists => AppDestination.doctors.name,
          IntroductionStep.appointment => AppDestination.sharing.name,
        }),
      );
    } finally {
      introductionOpen = false;
      if (context.mounted) {
        router.go(startUpload ? AppDestination.results.path : origin);
        if (startUpload) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              showAddAnalysis(
                context,
                showOtherRecords: false,
                onManualEntry: records == null
                    ? null
                    : () => showRecordEditor(
                        context,
                        records,
                        records.profile == null
                            ? RecordKind.profile
                            : RecordKind.result,
                      ),
              );
            }
          });
        }
      }
    }
  }

  Widget page(RecordsSection section, Widget demo) => records == null
      ? demo
      : ValueListenableBuilder<bool>(
          valueListenable: showDemo!,
          builder: (context, example, _) => example
              ? demo
              : section == RecordsSection.profile
              ? LocalProfilePage(
                  model: records,
                  catalog: catalog,
                  onDocuments: originals == null
                      ? null
                      : () => router.goNamed(AppDestination.documents.name),
                )
              : RecordsPage(
                  model: records,
                  section: section,
                  reports: reports,
                  sync: sync,
                  onOpenReport: () => router.push('/history'),
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
            accountCaption: records == null
                ? null
                : ListenableBuilder(
                    listenable: Listenable.merge([records, showDemo!]),
                    builder: (context, _) => Text(
                      showDemo.value
                          ? AppLocalizations.of(context).guestCaption
                          : (records.profile?.record as MedicalProfile?)
                                    ?.name ??
                                AppLocalizations.of(context).profile,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                  ),
            onDirectoryOpened: () => confirmDirectoryLocation(context),
            onAdd: () {
              if (records == null || showDemo!.value) {
                showAddAnalysis(
                  context,
                  onAddEvent: () => showDemoEventCapture(context, catalog),
                  onDiary: () =>
                      showDemoEventCapture(context, catalog, diary: true),
                );
                return;
              }
              if (records.profile == null) {
                showRecordEditor(context, records, RecordKind.profile);
              } else {
                showAddAnalysis(
                  context,
                  onAddEvent: () => showLocalEventCapture(context, records),
                  onDiary: () =>
                      showLocalEventCapture(context, records, diary: true),
                  onManualEntry: () =>
                      showRecordEditor(context, records, RecordKind.result),
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
                    onOpenHistory: () => context.push('/history'),
                    onPrintSystems: (ids) =>
                        context.push('/history', extra: ids),
                    onAddEvent: () => showDemoEventCapture(context, catalog),
                    onStartIntroduction: () => startIntroduction(context),
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
                    onAddEvent: () => showDemoEventCapture(context, catalog),
                    onDiary: () =>
                        showDemoEventCapture(context, catalog, diary: true),
                    onAdd: () =>
                        showAddAnalysis(context, showOtherRecords: false),
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
                builder: (context, state) => page(
                  RecordsSection.profile,
                  ProfilePage(
                    catalog: catalog,
                    onPreviewSave: () async {
                      if (account != null) {
                        await router.push('/account');
                      } else if (context.mounted) {
                        await showUnavailable(
                          context,
                          AppLocalizations.of(context).signIn,
                        );
                      }
                    },
                    onAddEvent: () => showDemoEventCapture(context, catalog),
                    onDiary: () =>
                        showDemoEventCapture(context, catalog, diary: true),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppDestination.sharing.path,
                name: AppDestination.sharing.name,
                builder: (context, state) => SharingPage(
                  catalog: catalog,
                  onOpenSettings: () =>
                      router.goNamed(AppDestination.settings.name),
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
                  demoMode: records == null,
                  onStartIntroduction: () => startIntroduction(context),
                  onOpenSharing: () =>
                      router.goNamed(AppDestination.sharing.name),
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
        path: '/history',
        builder: (context, state) => Scaffold(
          body: SafeArea(
            child: reports == null
                ? DemoHistoryPage(
                    catalog: catalog,
                    export: exportReport,
                    exportPdf: exportHistoryPdf,
                    selectedSystemIds: state.extra is Set<int>
                        ? state.extra as Set<int>
                        : null,
                    onClose: closeHistory,
                  )
                : ValueListenableBuilder<bool>(
                    valueListenable: showDemo!,
                    builder: (context, example, _) => example
                        ? DemoHistoryPage(
                            catalog: catalog,
                            export: exportReport,
                            exportPdf: exportHistoryPdf,
                            selectedSystemIds: state.extra is Set<int>
                                ? state.extra as Set<int>
                                : null,
                            onClose: closeHistory,
                          )
                        : ReportsPage(
                            model: reports,
                            onClose: closeHistory,
                            exportPdf: exportHistoryPdf,
                          ),
                  ),
          ),
        ),
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
