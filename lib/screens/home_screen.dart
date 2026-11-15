import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../models/day_key.dart';
import '../models/job_push.dart';
import '../services/announcer.dart';
import '../services/live_data.dart';
import '../services/push_service.dart';
import '../services/update_checker.dart';
import '../services/worker_client.dart';
import '../widgets/app_drawer.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/job_push_snack_bar.dart';
import '../widgets/pearl.dart';
import '../widgets/sync_banner.dart';
import '../widgets/update_dialog.dart';
import 'calendar_tab.dart';
import 'earnings_tab.dart';
import 'job_detail_screen.dart';
import 'job_form_screen.dart';
import 'wallet_tab.dart';

/// Signed-in shell: calendar, wallet and earnings over one [LiveData], the
/// side menu, pushes, announcements and the update check.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile});

  final AppUser profile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LiveData _data = LiveData();
  int _tab = 0;
  DateTime _day = dayOf(DateTime.now());
  bool _updateDialogOpen = false;
  late final StreamSubscription<void> _releaseSub;
  late final StreamSubscription<JobPush> _pushSub;
  late final StreamSubscription<String> _openSub;
  late final Announcer _announcer = Announcer(
    source: _data,
    pending: () => pendingAnnouncements(
      me: widget.profile.uid,
      jobs: _data.jobs ?? const [],
    ),
    announce: announceJob,
  );

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
    // A release push (received in the foreground or tapped) re-runs the same
    // check, which then shows the download dialog.
    final push = PushService.instance;
    _releaseSub = push.onRelease.listen((_) => _checkForUpdate());
    _pushSub = push.onPush.listen(_showPush);
    _openSub = push.onOpen.listen(_openJob);
    push.start();
    push.registerToken();
    _announcer.start();
  }

  @override
  void dispose() {
    _releaseSub.cancel();
    _pushSub.cancel();
    _openSub.cancel();
    _announcer.dispose();
    _data.dispose();
    super.dispose();
  }

  void _showPush(JobPush push) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      jobPushSnackBar(
        AppLocalizations.of(context),
        push,
        onOpen: push.jobId.isEmpty ? null : () => _openJob(push.jobId),
      ),
    );
  }

  void _openJob(String id) {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            JobDetailScreen(data: _data, profile: widget.profile, jobId: id),
      ),
    );
  }

  /// On app start and on release pushes; silent when offline or already up
  /// to date, and never stacks a second dialog on an open one.
  Future<void> _checkForUpdate() async {
    if (_updateDialogOpen) return;
    final result = await UpdateChecker.instance.check();
    if (!mounted || result is! UpdateAvailable || _updateDialogOpen) return;
    _updateDialogOpen = true;
    await showUpdateDialog(context, result);
    _updateDialogOpen = false;
  }

  void _addJob() => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          JobFormScreen(data: _data, profile: widget.profile, day: _day),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final profile = widget.profile;
    final titles = [null, t.tabWallet, t.tabEarnings];
    return Scaffold(
      drawer: AppDrawer(data: _data, profile: profile),
      appBar: AppBar(
        titleSpacing: 0,
        title: titles[_tab] == null
            ? PearlWordmark(t.appTitle)
            : Text(titles[_tab]!),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: WaterBeads(scale: 0.6),
          ),
        ],
      ),
      // The banner floats over the tabs instead of pushing them down.
      body: Stack(
        children: [
          Positioned.fill(
            child: ListenableBuilder(
              listenable: _data,
              builder: (context, _) => IndexedStack(
                index: _tab,
                children: [
                  CalendarTab(
                    data: _data,
                    profile: profile,
                    selected: _day,
                    onSelect: (d) => setState(() => _day = d),
                  ),
                  WalletTab(data: _data, profile: profile),
                  EarningsTab(data: _data, profile: profile),
                ],
              ),
            ),
          ),
          const SyncBanner(),
        ],
      ),
      floatingActionButton: _tab == 0
          ? PearlFab(
              label: t.newJob,
              icon: Icons.add_rounded,
              onPressed: _addJob,
            )
          : null,
      bottomNavigationBar: BottomNav(
        index: _tab,
        onSelect: (i) => setState(() => _tab = i),
      ),
    );
  }
}
