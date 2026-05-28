import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'core/router.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Orientation portrait + paysage
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Initialisation du répertoire de données locales (Isar)
  final appDir = await getApplicationDocumentsDirectory();

  runApp(
    ProviderScope(
      child: EcontinuityApp(),
    ),
  );
}

class EcontinuityApp extends ConsumerWidget {
  const EcontinuityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'E-Continuity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
