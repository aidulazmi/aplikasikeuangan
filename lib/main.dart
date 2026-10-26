import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/ui.dart';
import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(ChangeNotifierProvider(create: (_) => AppState()..init(), child: const DompetKuApp()));
}

class DompetKuApp extends StatelessWidget {
  const DompetKuApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'DompetKu',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (c, child) => AppBg(child: child!),
        home: const Gate(),
      );
}

class Gate extends StatelessWidget {
  const Gate({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: C.primary)));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: s.loggedIn ? const HomeShell(key: ValueKey('home')) : const LoginScreen(key: ValueKey('login')),
    );
  }
}
