import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:design_system/design_system.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/settings/settings.dart';
import '../features/records/records.dart';
import '../features/documents/documents.dart';
import '../features/processing/processing.dart';
import '../features/device_access/device_access.dart';
import '../presentation/demo_catalog.dart';
import '../l10n/generated/app_localizations.dart';
import 'navigation/app_router.dart';

/// Owns and disposes the injected settings ViewModel and its router.
class HealthApp extends StatefulWidget {
  const HealthApp({
    required this.settings,
    required this.catalog,
    this.initialLocation,
    this.deviceAccess,
    this.records,
    this.originals,
    this.processing,
    super.key,
  });

  final SettingsViewModel settings;
  final DemoCatalog catalog;
  final String? initialLocation;
  final DeviceAccessViewModel? deviceAccess;
  final RecordsViewModel? records;
  final OriginalsViewModel? originals;
  final ProcessingViewModel? processing;

  @override
  State<HealthApp> createState() => _HealthAppState();
}

class _HealthAppState extends State<HealthApp> {
  final _showDemo = ValueNotifier(false);
  late final _deviceAccess =
      widget.deviceAccess ??
      DeviceAccessViewModel(gateway: const UnavailableDeviceAccess());
  late AppPreferences _preferences = widget.settings.preferences;
  late final GoRouter _router = createAppRouter(
    widget.settings,
    widget.catalog,
    records: widget.records,
    originals: widget.originals,
    processing: widget.processing,
    showDemo: _showDemo,
    initialLocation: widget.initialLocation,
  );

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_applyAppearance);
  }

  void _applyAppearance() {
    final next = widget.settings.preferences;
    if (next.language == _preferences.language &&
        next.themeMode == _preferences.themeMode) {
      return;
    }
    setState(() => _preferences = next);
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    restorationScopeId: 'health-app',
    routerConfig: _router,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: _preferences.language == AppLanguage.system
        ? null
        : Locale(_preferences.language.name),
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    // Interpolating the global theme rebuilds every mounted route per frame.
    // Local control feedback remains animated.
    themeAnimationDuration: Duration.zero,
    themeMode: switch (_preferences.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    },
    builder: (context, child) => DeviceAccessScope(
      model: _deviceAccess,
      child: UnobstructedPane(child: child!),
    ),
  );

  @override
  void dispose() {
    widget.settings.removeListener(_applyAppearance);
    _router.dispose();
    _showDemo.dispose();
    widget.records?.dispose();
    widget.originals?.dispose();
    widget.processing?.dispose();
    widget.settings.dispose();
    _deviceAccess.dispose();
    super.dispose();
  }
}
