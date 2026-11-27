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
    this.onOpenSharing,
    this.demoMode = false,
    super.key,
  });
  final SettingsViewModel viewModel;
  final bool demoMode;
  final VoidCallback onClose;
  final VoidCallback onStartIntroduction;
  final VoidCallback? onOpenAccount, onOpenSharing;
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final support = TextEditingController();
  int supportTopic = 0;
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
      builder: (context, _) => ReferencePage(
        showDemoNotice: widget.demoMode,
        children: [
          PaperCard(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.settings,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                QuietFold(
                  title: Text(l.account),
                  initiallyExpanded: true,
                  children: [
                    if (widget.onOpenAccount != null) ...[
                      Text(
                        l.accountDescription,
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: widget.onOpenAccount,
                          child: Text(l.accountManage),
                        ),
                      ),
                    ] else ...[
                      for (final pair in [
                        (l.nameLabel, 'Алексей'),
                        (l.phoneLabel, '+7 921 000-00-00'),
                        (l.emailLabel, ''),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                pair.$1,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.secondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              TextFormField(
                                initialValue: pair.$2,
                                readOnly: true,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: p.paper,
                                  contentPadding: const EdgeInsets.all(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => showUnavailable(context, l.signIn),
                          child: Text(
                            l.signInRegister,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                for (final title in [l.accessToMine, l.sharedWithMe])
                  QuietFold(
                    title: Text(title),
                    children: [
                      Text(
                        l.noSharedAccess,
                        style: TextStyle(fontSize: 12, color: p.secondary),
                      ),
                      if (title == l.accessToMine &&
                          widget.onOpenSharing != null)
                        TextButton(
                          onPressed: widget.onOpenSharing,
                          child: Text(l.sharingTitle),
                        ),
                    ],
                  ),
                QuietFold(
                  title: Text(l.notificationsAndPermissions),
                  children: [
                    Text(
                      l.notifications,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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
                    const SizedBox(height: 12),
                    const DeviceAccessSettings(),
                  ],
                ),
                QuietFold(
                  title: Text(l.support),
                  children: [
                    AppSelect<int>(
                      label: l.supportSubject,
                      value: supportTopic,
                      options: [
                        for (var i = 0; i < 5; i++)
                          AppSelectOption(
                            value: i,
                            label: [
                              l.supportRecognition,
                              l.supportBug,
                              l.supportAccess,
                              l.supportIdea,
                              l.supportOther,
                            ][i],
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => supportTopic = value),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.supportHint,
                      style: TextStyle(fontSize: 12, color: p.muted),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      key: const Key('support-message'),
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
                QuietFold(
                  key: const Key('appearance-fold'),
                  title: Text(l.appearance),
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
                      LinearProgressIndicator(
                        semanticsLabel: l.savingPreferences,
                      ),
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
              ],
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(
              onPressed: widget.onStartIntroduction,
              child: Text(l.restartTour),
            ),
          ),
        ],
      ),
    );
  }
}
