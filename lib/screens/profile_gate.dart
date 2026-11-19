import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/pearl.dart';
import 'home_screen.dart';
import 'status_screen.dart';

/// Decides what a signed-in account sees, from its `users/{uid}` profile:
/// the app, a "switched off" notice, or the one-time admin claim. Watched
/// live, so switching someone off throws them out at once.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, required this.user});

  final User user;

  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final _users = UserRepository.instance;
  late final Stream<AppUser?> _profile = _users.watchProfile(widget.user.uid);
  late Future<bool> _canClaim = _users.canClaimAdmin();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return StreamBuilder<AppUser?>(
      stream: _profile,
      builder: (context, snap) {
        if (snap.hasError) {
          return StatusScreen(
            icon: Icons.cloud_off_rounded,
            title: t.errGeneric,
            body: errorText(t, snap.error!),
          );
        }
        if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final profile = snap.data;
        if (profile == null) return _noProfile(t);
        if (profile.disabled) {
          return StatusScreen(
            icon: Icons.person_off_rounded,
            title: t.disabledTitle,
            body: t.disabledBody,
          );
        }
        // Keyed by role: the home screen settles its tabs and whether it
        // reads the wallet once, so a role changed in the database starts it
        // afresh instead of keeping the old one until the app restarts.
        return HomeScreen(key: ValueKey(profile.role), profile: profile);
      },
    );
  }

  Widget _noProfile(AppLocalizations t) {
    return FutureBuilder<bool>(
      future: _canClaim,
      builder: (context, snap) {
        if (snap.hasError) {
          // A fresh install offline cannot ask the server; let it try again.
          return StatusScreen(
            icon: Icons.cloud_off_rounded,
            title: t.errGeneric,
            body: errorText(t, snap.error!),
            actionLabel: t.tryAgain,
            onAction: () => setState(() => _canClaim = _users.canClaimAdmin()),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == true) {
          return _ClaimAdmin(
            user: widget.user,
            onFailed: () => setState(() => _canClaim = _users.canClaimAdmin()),
          );
        }
        return StatusScreen(
          icon: Icons.lock_outline_rounded,
          title: t.noAccessTitle,
          body: t.noAccessBody,
        );
      },
    );
  }
}

/// The very first account becomes the admin, once: its name, then the claim.
class _ClaimAdmin extends StatefulWidget {
  const _ClaimAdmin({required this.user, required this.onFailed});

  final User user;
  final VoidCallback onFailed;

  @override
  State<_ClaimAdmin> createState() => _ClaimAdminState();
}

class _ClaimAdminState extends State<_ClaimAdmin> {
  final _form = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  /// Awaited, unlike other writes: nothing else can happen before it.
  Future<void> _claim() async {
    if (!_form.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await UserRepository.instance.claimAdmin(
        widget.user,
        firstName: _first.text,
        lastName: _last.text,
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(errorText(t, e))));
      if (mounted) setState(() => _busy = false);
      widget.onFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      body: Container(
        decoration: c.softGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: AppLogo(size: 84)),
                    const SizedBox(height: 18),
                    Text(
                      t.claimAdminTitle,
                      textAlign: TextAlign.center,
                      style: c.display(24),
                    ),
                    const SizedBox(height: 10),
                    Text(t.claimAdminBody, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _first,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: t.firstName),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? t.required : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _last,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(labelText: t.lastName),
                    ),
                    const SizedBox(height: 22),
                    PearlButton(
                      label: t.claimAdminButton,
                      busy: _busy,
                      onPressed: _claim,
                    ),
                    TextButton(
                      onPressed: AuthService.instance.signOut,
                      child: Text(t.signOut),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
