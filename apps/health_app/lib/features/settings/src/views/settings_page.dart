import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../presentation/reference_widgets.dart';
import '../../../device_access/device_access.dart';
import '../models/app_preferences.dart';
import '../view_models/settings_view_model.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.viewModel,
    required this.onClose,
    required this.onStartIntroduction,
    this.onOpenAccount,
    super.key,
  });
  final SettingsViewModel viewModel;
  final VoidCallback onClose;
  final VoidCallback onStartIntroduction;
  final VoidCallback? onOpenAccount;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final support = TextEditingController();
  @override
  void dispose() {
    support.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context),
        p = OrangePalette.of(context),
        model = widget.viewModel;
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) => DemoPage(
        children: [
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: SectionHeading(l.settings)),
                    BackButton(onPressed: widget.onClose),
                  ],
                ),
                const SizedBox(height: 8),
                SectionHeading(l.account),
                const SizedBox(height: 12),
                if (widget.onOpenAccount != null) ...[
                  Text(l.accountDescription),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: widget.onOpenAccount,
                    child: Text(l.accountManage),
                  ),
                ] else ...[
                  for (final pair in [
                    (l.nameLabel, 'Алексей'),
                    (l.phoneLabel, '+7 921 000-00-00'),
                    (l.emailLabel, ''),
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        initialValue: pair.$2,
                        readOnly: true,
                        decoration: InputDecoration(labelText: pair.$1),
                      ),
                    ),
                  Text(
                    l.demoAccount,
                    style: TextStyle(fontSize: 12, color: p.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(l.appearance),
                const SizedBox(height: 6),
                Text(
                  l.preferencesDescription,
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
                const SizedBox(height: 18),
                AppSelect<AppLanguage>(
                  label: l.language,
                  value: model.preferences.language,
                  options: [
                    AppSelectOption(
                      value: AppLanguage.system,
                      label: l.systemLanguage,
                      icon: Icons.language_rounded,
                    ),
                    AppSelectOption(
                      value: AppLanguage.ru,
                      label: l.russian,
                      icon: Icons.language_rounded,
                    ),
                    AppSelectOption(
                      value: AppLanguage.en,
                      label: l.english,
                      icon: Icons.language_rounded,
                    ),
                  ],
                  onChanged: model.isBusy ? null : model.setLanguage,
                ),
                const SizedBox(height: 20),
                AppSelect<AppThemeMode>(
                  label: l.theme,
                  value: model.preferences.themeMode,
                  options: [
                    AppSelectOption(
                      value: AppThemeMode.system,
                      label: l.systemTheme,
                      icon: Icons.brightness_auto_rounded,
                    ),
                    AppSelectOption(
                      value: AppThemeMode.light,
                      label: l.lightTheme,
                      icon: Icons.light_mode_outlined,
                    ),
                    AppSelectOption(
                      value: AppThemeMode.dark,
                      label: l.darkTheme,
                      icon: Icons.dark_mode_outlined,
                    ),
                  ],
                  onChanged: model.isBusy ? null : model.setThemeMode,
                ),
                if (model.isBusy) ...[
                  const SizedBox(height: 18),
                  LinearProgressIndicator(semanticsLabel: l.savingPreferences),
                ],
                if (model.error != null) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      model.error == SettingsError.load
                          ? l.preferencesLoadError
                          : l.preferencesSaveError,
                      style: TextStyle(color: p.red),
                    ),
                  ),
                  if (model.error == SettingsError.load)
                    TextButton(
                      onPressed: model.isBusy ? null : model.load,
                      child: Text(l.retry),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (final title in [l.accessToMine, l.sharedWithMe]) ...[
            PaperCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(title),
                  const SizedBox(height: 8),
                  Text(
                    l.noSharedAccess,
                    style: TextStyle(color: p.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(l.notifications),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 7,
                  children: [
                    for (final channel in ['Telegram', 'VK', 'Email'])
                      OutlinedButton(
                        onPressed: () => showUnavailable(context, channel),
                        child: Text(channel),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SectionHeading(l.appPermissions),
                const SizedBox(height: 8),
                const DeviceAccessSettings(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PaperCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(l.support),
                const SizedBox(height: 6),
                Text(
                  l.supportHint,
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: support,
                  maxLines: 4,
                  decoration: InputDecoration(labelText: l.supportMessage),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => showUnavailable(context, l.send),
                    child: Text(l.send),
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
                SectionHeading(l.appIntroduction),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: widget.onStartIntroduction,
                  child: Text(l.restartTour),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
