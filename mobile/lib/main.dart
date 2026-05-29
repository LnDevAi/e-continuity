import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/l10n/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialisation du répertoire de données locales (Isar)
  final appDir = await getApplicationDocumentsDirectory();

  runApp(
    const ProviderScope(
      child: EcontinuityApp(),
    ),
  );
}

class EcontinuityApp extends ConsumerStatefulWidget {
  const EcontinuityApp({super.key});

  @override
  ConsumerState<EcontinuityApp> createState() => _EcontinuityAppState();
}

class _EcontinuityAppState extends ConsumerState<EcontinuityApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(languageProvider.notifier).init());
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'E-Continuity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      locale: locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
