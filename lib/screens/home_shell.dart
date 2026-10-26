import 'package:flutter/material.dart';
import '../core/ui.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  Widget _item(int idx, IconData icon, String label) {
    final on = _i == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _i = idx),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: on ? C.primaryDark : C.muted, size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(fontSize: 10.5, fontWeight: on ? FontWeight.w800 : FontWeight.w500, color: on ? C.primaryDark : C.muted)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(index: _i, children: const [HomeScreen(), HistoryScreen(), StatsScreen(), SettingsScreen()]),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Glass(
            radius: 30,
            opacity: .7,
            padding: EdgeInsets.zero,
            child: SizedBox(
              height: 68,
              child: Row(children: [
                _item(0, Icons.home_rounded, 'Beranda'),
                _item(1, Icons.history_rounded, 'Riwayat'),
                Expanded(
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: C.gradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: C.primary.withOpacity(.45), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
                _item(2, Icons.bar_chart_rounded, 'Statistik'),
                _item(3, Icons.settings_rounded, 'Pengaturan'),
              ]),
            ),
          ),
        ),
      );
}
