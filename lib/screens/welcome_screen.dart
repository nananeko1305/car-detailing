import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_logo.dart';
import '../widgets/pearl.dart';

/// The first start on a phone: the language, then on to sign in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final c = context.colors;
    final current = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: DecoratedBox(
        decoration: c.softGradient,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(child: WaterBeads()),
                  const SizedBox(height: 12),
                  const Center(child: AppLogo(size: 104)),
                  const SizedBox(height: 18),
                  Center(child: PearlWordmark(t.appTitle, size: 32)),
                  const SizedBox(height: 8),
                  Text(
                    t.appTagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    t.chooseLanguage,
                    textAlign: TextAlign.center,
                    style: c.display(17),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final (code, label) in const [
                        ('sr', 'Srpski'),
                        ('en', 'English'),
                      ]) ...[
                        Expanded(
                          child: ChoiceChip(
                            label: SizedBox(
                              width: double.infinity,
                              child: Text(label, textAlign: TextAlign.center),
                            ),
                            selected: current == code,
                            onSelected: (_) => localeController.select(
                              code == 'sr' ? kSerbianLatin : const Locale('en'),
                            ),
                          ),
                        ),
                        if (code == 'sr') const SizedBox(width: 10),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),
                  PearlButton(label: t.next, onPressed: onDone),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
