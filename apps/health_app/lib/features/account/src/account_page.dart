import 'package:design_system/design_system.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'account_view_model.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({
    required this.model,
    required this.onClose,
    required this.onOpenSync,
    super.key,
  });
  final AccountViewModel model;
  final VoidCallback onClose, onOpenSync;
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final email = TextEditingController(),
      password = TextEditingController(),
      code = TextEditingController(),
      device = TextEditingController();
  final form = GlobalKey<FormState>();
  bool visible = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    code.dispose();
    device.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.model,
    builder: (context, _) {
      final m = widget.model,
          l = AppLocalizations.of(context),
          session = m.session;
      final challenge = m.challengeId != null;
      final needsPassword = m.mode == AccountMode.login || challenge;
      final needsDevice = m.mode != AccountMode.recover && needsPassword;
      Future<void> submit() async {
        if (!form.currentState!.validate()) return;
        if (!needsPassword) {
          await m.requestCode(email.text);
          return;
        }
        await m.submit(
          email.text,
          password.text,
          device.text.isEmpty ? l.accountThisDevice : device.text,
          code.text,
        );
        if (m.session != null || m.message == 'recovered') {
          password.clear();
          code.clear();
        }
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(l.account),
          leading: BackButton(onPressed: widget.onClose),
        ),
        body: UnobstructedPane(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: PaperCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (m.busy) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 16),
                      ],
                      if (session == null) ...[
                        Text(l.accountDescription),
                        const SizedBox(height: 24),
                        AppSelect<AccountMode>(
                          label: l.accountAction,
                          value: m.mode,
                          options: [
                            AppSelectOption(
                              value: AccountMode.login,
                              label: l.accountLogin,
                            ),
                            AppSelectOption(
                              value: AccountMode.register,
                              label: l.accountRegister,
                            ),
                            AppSelectOption(
                              value: AccountMode.recover,
                              label: l.accountRecover,
                            ),
                          ],
                          onChanged: m.busy
                              ? null
                              : (value) {
                                  m.selectMode(value);
                                  password.clear();
                                  code.clear();
                                  form.currentState?.reset();
                                },
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: form,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  key: const Key('account-email'),
                                  controller: email,
                                  enabled: !m.busy && !challenge,
                                  keyboardType: TextInputType.emailAddress,
                                  autofillHints: const [
                                    AutofillHints.username,
                                    AutofillHints.email,
                                  ],
                                  textInputAction: TextInputAction.next,
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                    labelText: l.emailLabel,
                                  ),
                                  validator: (v) =>
                                      v != null &&
                                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                              .hasMatch(v.trim())
                                      ? null
                                      : l.accountEmailError,
                                ),
                                if (challenge) ...[
                                  const SizedBox(height: 16),
                                  Text(l.accountCodeSent),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    key: const Key('account-code'),
                                    controller: code,
                                    enabled: !m.busy,
                                    keyboardType: TextInputType.number,
                                    autofillHints: const [
                                      AutofillHints.oneTimeCode,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: l.accountCode,
                                    ),
                                    validator: (v) =>
                                        RegExp(r'^\d{8}$').hasMatch(v ?? '')
                                        ? null
                                        : l.accountCodeError,
                                  ),
                                ],
                                if (needsPassword) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    key: const Key('account-password'),
                                    controller: password,
                                    enabled: !m.busy,
                                    obscureText: !visible,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    maxLength: 128,
                                    autofillHints: [
                                      m.mode == AccountMode.login
                                          ? AutofillHints.password
                                          : AutofillHints.newPassword,
                                    ],
                                    decoration: InputDecoration(
                                      labelText: m.mode == AccountMode.recover
                                          ? l.accountNewPassword
                                          : l.accountPassword,
                                      helperText: m.mode == AccountMode.login
                                          ? null
                                          : l.accountPasswordHint,
                                      suffixIcon: IconButton(
                                        tooltip: visible
                                            ? l.accountHidePassword
                                            : l.accountShowPassword,
                                        onPressed: () =>
                                            setState(() => visible = !visible),
                                        icon: Icon(
                                          visible
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v ?? '').isNotEmpty &&
                                            (m.mode == AccountMode.login ||
                                                v!.runes.length >= 15)
                                        ? null
                                        : l.accountPasswordHint,
                                  ),
                                ],
                                if (needsDevice) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    key: const Key('account-device'),
                                    controller: device,
                                    enabled: !m.busy,
                                    maxLength: 80,
                                    decoration: InputDecoration(
                                      labelText: l.accountDeviceName,
                                      hintText: l.accountThisDevice,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                FilledButton(
                                  key: const Key('account-submit'),
                                  onPressed: m.busy ? null : submit,
                                  child: Text(
                                    !needsPassword
                                        ? l.accountSendCode
                                        : switch (m.mode) {
                                            AccountMode.login => l.accountLogin,
                                            AccountMode.register =>
                                              l.accountRegister,
                                            AccountMode.recover =>
                                              l.accountResetPassword,
                                          },
                                  ),
                                ),
                                if (challenge)
                                  TextButton(
                                    onPressed: m.busy
                                        ? null
                                        : () {
                                            m.selectMode(m.mode);
                                            code.clear();
                                          },
                                    child: Text(l.accountChangeEmail),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (m.message == 'recovered') ...[
                          const SizedBox(height: 16),
                          Semantics(
                            liveRegion: true,
                            child: Text(l.accountRecovered),
                          ),
                        ],
                      ] else ...[
                        Text(
                          session.email,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(l.accountSecondDeviceHint),
                        const SizedBox(height: 16),
                        Text(l.accountConnectHint),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const Key('account-connect'),
                          onPressed: m.busy ? null : m.connectCloud,
                          child: Text(
                            m.cloudConnected
                                ? l.accountReconnect
                                : l.accountConnect,
                          ),
                        ),
                        if (m.cloudConnected)
                          TextButton(
                            onPressed: widget.onOpenSync,
                            child: Text(l.syncTitle),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          l.cloudTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          key: const Key('cloud-refresh'),
                          onPressed: m.busy ? null : m.refreshCloud,
                          child: Text(l.cloudRefresh),
                        ),
                        if (m.cloudError != null)
                          Semantics(
                            liveRegion: true,
                            child: Text(
                              l.cloudUnavailable,
                              style: TextStyle(
                                color: OrangePalette.of(context).red,
                              ),
                            ),
                          ),
                        if (m.cloud case final status?) ...[
                          if (m.cloudError != null) Text(l.cloudLastKnown),
                          Text(
                            '${l.cloudSync}: ${status.syncAllowed ? l.cloudEnabled : l.cloudDisabled}',
                          ),
                          Text(
                            l.cloudRecordUsage(
                              status.recordsUsed,
                              status.recordLimit,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${l.cloudStorage}: ${status.storageAllowed ? l.cloudEnabled : l.cloudDisabled}',
                          ),
                          Text(
                            l.cloudByteUsage(
                              NumberFormat.decimalPattern(l.localeName)
                                  .format(status.bytesUsed),
                              NumberFormat.decimalPattern(l.localeName)
                                  .format(status.bytesReserved),
                              NumberFormat.decimalPattern(l.localeName)
                                  .format(status.storageLimit),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${l.cloudProcessing}: ${status.processingAllowed ? l.cloudEnabled : l.cloudDisabled}',
                          ),
                          Text(
                            l.cloudJobUsage(
                              status.jobsUsed,
                              status.jobsReserved,
                              status.jobLimit,
                              status.period,
                            ),
                          ),
                          if (status.validUntil != null)
                            Text(
                              l.cloudUntil(
                                DateFormat.yMd(l.localeName)
                                    .add_Hm()
                                    .format(status.validUntil!.toLocal()),
                              ),
                            ),
                        ],
                        Text(l.cloudLocalKept),
                        const SizedBox(height: 24),
                        Text(
                          l.accountDevices,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: m.busy ? null : m.loadDevices,
                          child: Text(l.accountRefreshDevices),
                        ),
                        for (final device in m.devices)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.label,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  '${DateFormat.yMd(l.localeName).add_Hm().format(device.createdAt.toLocal())}${device.current ? ' · ${l.accountThisSession}' : ''}',
                                ),
                                OutlinedButton(
                                  key: ValueKey('revoke-${device.id}'),
                                  onPressed: m.busy
                                      ? null
                                      : () => m.revoke(device),
                                  child: Text(l.accountRevoke),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: m.busy ? null : () => m.logout(),
                          child: Text(l.accountLogout),
                        ),
                        TextButton(
                          onPressed: m.busy ? null : () => m.logout(all: true),
                          child: Text(l.accountLogoutAll),
                        ),
                      ],
                      if (m.error != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error(l, m.error!),
                            style: TextStyle(
                              color: OrangePalette.of(context).red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  String _error(AppLocalizations l, String code) => switch (code) {
    'credentials' => l.accountCredentialsError,
    'email' => l.accountEmailError,
    'password' => l.accountPasswordHint,
    'code' => l.accountCodeError,
    'account_exists' => l.accountExists,
    'rate_limited' => l.accountRateLimited,
    'binding' => l.accountBindingError,
    'secure_storage' => l.accountStorageError,
    'unauthorized' || 'session_expired' => l.accountSessionExpired,
    _ => l.accountNetworkError,
  };
}
