import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/error_text.dart';
import '../models/app_user.dart';
import '../services/background_save.dart';
import '../services/user_repository.dart';

/// Adds a worker (name, phone, email, starting password), or edits one's
/// name and phone. Adding waits for the server: the account must exist
/// before the admin can hand over the password.
Future<void> showWorkerDialog(BuildContext context, {AppUser? user}) =>
    showDialog<void>(
      context: context,
      builder: (_) => _WorkerDialog(user: user),
    );

class _WorkerDialog extends StatefulWidget {
  const _WorkerDialog({this.user});

  final AppUser? user;

  @override
  State<_WorkerDialog> createState() => _WorkerDialogState();
}

class _WorkerDialogState extends State<_WorkerDialog> {
  final _form = GlobalKey<FormState>();
  late final _first = TextEditingController(text: widget.user?.firstName);
  late final _last = TextEditingController(text: widget.user?.lastName);
  late final _phone = TextEditingController(text: widget.user?.phone);
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  bool get _isNew => widget.user == null;

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final t = AppLocalizations.of(context);
    final repo = UserRepository.instance;
    if (!_isNew) {
      final uid = widget.user!.uid;
      saveInBackground(
        context,
        () => repo.updateProfile(
          uid,
          firstName: _first.text,
          lastName: _last.text,
          phone: _phone.text,
        ),
      );
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await repo.createWorker(
        email: _email.text,
        password: _password.text,
        firstName: _first.text,
        lastName: _last.text,
        phone: _phone.text,
      );
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(t.workerAdded)));
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(errorText(t, e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    String? required(String? v) =>
        (v == null || v.trim().isEmpty) ? t.required : null;
    const gap = SizedBox(height: 12);
    return AlertDialog(
      title: Text(_isNew ? t.addWorker : t.editWorker),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _first,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: t.firstName),
                validator: required,
              ),
              gap,
              TextFormField(
                controller: _last,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: t.lastName),
              ),
              gap,
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: t.phone),
              ),
              if (_isNew) ...[
                gap,
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: t.email),
                  validator: (v) =>
                      (v == null || !v.contains('@')) ? t.invalidEmail : null,
                ),
                gap,
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: t.startPassword,
                    helperText: t.startPasswordHint,
                    helperMaxLines: 3,
                  ),
                  validator: (v) =>
                      (v == null || v.length < 6) ? t.minChars6 : null,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(t.goBack),
        ),
        TextButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? t.wait : (_isNew ? t.add : t.save)),
        ),
      ],
    );
  }
}
