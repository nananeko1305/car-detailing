import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/start_gate.dart';
import 'services/first_run.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  _registerFontLicenses();
  await localeController.load();
  runApp(CarDetailingApp(welcome: await welcomePending()));
}

/// The bundled fonts come under the SIL Open Font License, which travels with
/// them: it shows on the licenses page.
void _registerFontLicenses() {
  const fonts = {'Space Grotesk': 'spacegrotesk', 'Inter': 'inter'};
  LicenseRegistry.addLicense(() async* {
    for (final e in fonts.entries) {
      final text = await rootBundle.loadString(
        'assets/fonts/licenses/${e.value}-OFL.txt',
      );
      yield LicenseEntryWithLineBreaks([e.key], text);
    }
  });
}

class CarDetailingApp extends StatelessWidget {
  const CarDetailingApp({super.key, required this.welcome});

  /// First start on this phone: show the welcome before signing in.
  final bool welcome;

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when the language changes.
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.current,
          locale: localeController.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: kSupportedLocales,
          localeListResolutionCallback: resolveLocale,
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: AppTheme.overlayFor(kCeramic),
            child: child!,
          ),
          home: StartGate(welcome: welcome),
        );
      },
    );
  }
}
