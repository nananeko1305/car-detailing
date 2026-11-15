import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../services/background_save.dart';
import '../services/live_data.dart';
import '../services/user_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_delete.dart';
import '../widgets/pearl.dart';
import '../widgets/worker_dialog.dart';

/// The crew. The admin adds workers, edits them, and switches them off or
/// back on; a switched-off worker cannot sign in, and their jobs keep their
/// name. Accounts are never deleted from the app.
class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  Future<void> _toggle(BuildContext context, AppUser u) async {
    final t = AppLocalizations.of(context);
    final off = !u.disabled;
    final ok = await confirmDelete(
      context,
      off ? t.disableWorkerQ(u.displayName) : t.enableWorkerQ(u.displayName),
      body: off ? t.disableWorkerBody : null,
      confirmLabel: off ? t.disable : t.enable,
    );
    if (!ok || !context.mounted) return;
    saveInBackground(
      context,
      () => UserRepository.instance.setDisabled(u.uid, off),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: data,
      builder: (context, _) {
        final users = data.users ?? const <AppUser>[];
        final active = [
          for (final u in users)
            if (!u.disabled) u,
        ];
        final off = [
          for (final u in users)
            if (u.disabled) u,
        ];
        return Scaffold(
          appBar: AppBar(title: Text(t.workers)),
          floatingActionButton: profile.isAdmin
              ? PearlFab(
                  label: t.addWorker,
                  icon: Icons.person_add_alt_1_rounded,
                  onPressed: () => showWorkerDialog(context),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            children: [
              for (final u in active)
                _WorkerTile(
                  user: u,
                  me: u.uid == profile.uid,
                  admin: profile.isAdmin,
                  onToggle: () => _toggle(context, u),
                ),
              if (off.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
                  child: Text(t.switchedOff, style: context.colors.display(15)),
                ),
                for (final u in off)
                  _WorkerTile(
                    user: u,
                    me: false,
                    admin: profile.isAdmin,
                    onToggle: () => _toggle(context, u),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _WorkerTile extends StatelessWidget {
  const _WorkerTile({
    required this.user,
    required this.me,
    required this.admin,
    required this.onToggle,
  });

  final AppUser user;
  final bool me;
  final bool admin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final initials = user.displayName.trim().isEmpty
        ? '?'
        : user.displayName.trim()[0].toUpperCase();
    final subtitle = [
      user.isAdmin ? t.roleAdmin : t.roleWorker,
      if (user.phone.isNotEmpty) user.phone,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
          leading: CircleAvatar(
            backgroundColor: user.disabled ? c.surfaceHigh : c.soft,
            foregroundColor: user.disabled ? c.muted : c.primary,
            child: Text(initials),
          ),
          title: Text(
            user.displayName,
            style: TextStyle(color: user.disabled ? c.muted : c.ink),
          ),
          subtitle: Text(subtitle, style: TextStyle(color: c.muted)),
          onTap: admin ? () => showWorkerDialog(context, user: user) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user.phone.isNotEmpty)
                IconButton(
                  tooltip: t.call,
                  icon: Icon(Icons.phone_rounded, color: c.primary),
                  onPressed: () => launchUrl(
                    Uri(scheme: 'tel', path: user.phone.replaceAll(' ', '')),
                  ),
                ),
              if (admin && !me && !user.isAdmin)
                IconButton(
                  tooltip: user.disabled ? t.enable : t.disable,
                  icon: Icon(
                    user.disabled
                        ? Icons.person_add_alt_rounded
                        : Icons.person_off_outlined,
                    color: c.muted,
                  ),
                  onPressed: onToggle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
