import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/live_data.dart';
import '../services/notification_settings.dart';
import '../theme/app_colors.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/update_tiles.dart';
import '../widgets/worker_dialog.dart';
import 'share_app_screen.dart';

/// The account's own things: name, password, language, notifications,
/// updates, and signing out.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    const gap = SizedBox(height: 22);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text, style: c.display(15)),
    );
    return Scaffold(
      appBar: AppBar(title: Text(t.settings)),
      body: ListenableBuilder(
        listenable: Listenable.merge([data, localeController]),
        builder: (context, _) {
          final me = data.userById(profile.uid) ?? profile;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              label(t.profile),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person_rounded),
                      title: Text(
                        me.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      // Without a name the title already is the email.
                      subtitle: me.displayName == me.email
                          ? null
                          : Text(me.email, maxLines: 1),
                      trailing: const Icon(Icons.edit_rounded),
                      onTap: () => showWorkerDialog(context, user: me),
                    ),
                    ListTile(
                      leading: const Icon(Icons.password_rounded),
                      title: Text(t.changePassword),
                      onTap: () => showChangePasswordDialog(context),
                    ),
                  ],
                ),
              ),
              gap,
              label(t.language),
              const _LanguagePicker(),
              gap,
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications_rounded),
                      title: Text(t.notifications),
                      subtitle: Text(t.notificationsHint),
                      onTap: openNotificationSettings,
                    ),
                    ListTile(
                      leading: const Icon(Icons.qr_code_rounded),
                      title: Text(t.shareApp),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ShareAppScreen(),
                        ),
                      ),
                    ),
                    const UpdateTiles(),
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(t.licenses),
                      onTap: () => showLicensePage(
                        context: context,
                        applicationName: t.appTitle,
                      ),
                    ),
                  ],
                ),
              ),
              gap,
              OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded),
                label: Text(t.signOut),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await AuthService.instance.signOut();
                  navigator.popUntil((r) => r.isFirst);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final current = localeController.locale?.languageCode;
    final options = <(String?, String)>[
      (null, t.languagePhone),
      ('sr', 'Srpski'),
      ('en', 'English'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (code, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: current == code,
            onSelected: (_) => localeController.select(
              code == null
                  ? null
                  : (code == 'sr' ? kSerbianLatin : const Locale('en')),
            ),
          ),
      ],
    );
  }
}
