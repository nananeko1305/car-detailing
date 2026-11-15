import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../screens/price_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/share_app_screen.dart';
import '../screens/workers_screen.dart';
import '../services/auth_service.dart';
import '../services/live_data.dart';
import '../theme/app_colors.dart';
import 'app_logo.dart';
import 'pearl.dart';

/// The side menu: price list, the crew, settings, sharing the app, and at
/// the very bottom, in red, signing out.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.data, required this.profile});

  final LiveData data;
  final AppUser profile;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    void open(Widget screen) {
      Navigator.of(context)
        ..pop()
        ..push(MaterialPageRoute(builder: (_) => screen));
    }

    final me = data.userById(profile.uid) ?? profile;
    return Drawer(
      backgroundColor: c.background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        const AppLogo(size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PearlWordmark(t.appTitle, size: 19),
                              const SizedBox(height: 2),
                              Text(
                                '${me.displayName} · ${me.isAdmin ? t.roleAdmin : t.roleWorker}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12, color: c.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Item(
                    icon: Icons.sell_outlined,
                    label: t.priceList,
                    onTap: () => open(PriceListScreen(data: data, profile: me)),
                  ),
                  _Item(
                    icon: Icons.groups_outlined,
                    label: t.workers,
                    onTap: () => open(WorkersScreen(data: data, profile: me)),
                  ),
                  _Item(
                    icon: Icons.settings_outlined,
                    label: t.settings,
                    onTap: () => open(SettingsScreen(data: data, profile: me)),
                  ),
                  _Item(
                    icon: Icons.qr_code_rounded,
                    label: t.shareApp,
                    onTap: () => open(const ShareAppScreen()),
                  ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            _Item(
              icon: Icons.logout_rounded,
              label: t.signOut,
              color: c.danger,
              onTap: () {
                Navigator.of(context).pop();
                AuthService.instance.signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Icon and text color; the accent when null.
  final Color? color;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    leading: Icon(icon, color: color ?? context.colors.primary),
    title: Text(
      label,
      style: TextStyle(fontWeight: FontWeight.w600, color: color),
    ),
    onTap: onTap,
  );
}
