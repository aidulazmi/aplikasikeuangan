import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/api.dart';
import '../core/fmt.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import 'home_screen.dart' show editBudget;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    try {
      final csv = await Api.getText('/api/export');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/dompetku_transaksi.csv');
      await f.writeAsString(csv);
      await Share.shareXFiles([XFile(f.path)], text: 'Ekspor transaksi DompetKu');
    } on ApiError catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _server(BuildContext context) async {
    final s = context.read<AppState>();
    final c = TextEditingController(text: Api.base);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alamat server'),
        content: TextField(controller: c, keyboardType: TextInputType.url),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) await s.setServer(c.text);
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: C.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true && context.mounted) await context.read<AppState>().logout();
  }

  Widget _row(IconData i, String t, String sub, {VoidCallback? onTap, Widget? trailing, Color? color}) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: (color ?? C.primary).withOpacity(.13), borderRadius: BorderRadius.circular(13)),
              child: Icon(i, size: 20, color: color ?? C.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
                if (sub.isNotEmpty) Text(sub, style: const TextStyle(color: C.muted, fontSize: 11.5)),
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: C.muted),
          ]),
        ),
      );

  Widget _sec(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 0, 8),
        child: Text(t, style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w800, letterSpacing: 1)),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), children: [
      const Padding(padding: EdgeInsets.only(bottom: 14), child: Text('Pengaturan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
      Glass(
        radius: 26,
        padding: const EdgeInsets.all(18),
        gradient: const LinearGradient(colors: [Color(0xE64CBB88), Color(0xE62A9565)]),
        child: Row(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white.withOpacity(.25), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.user?['name'] ?? 'Pengguna', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              Text(s.user?['email'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
        ]),
      ),
      _sec('KEUANGAN'),
      Glass(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
        _row(Icons.flag_rounded, 'Anggaran Bulanan', s.budget > 0 ? rp(s.budget) : 'Belum diatur', onTap: () => editBudget(context)),
        _row(Icons.category_rounded, 'Kelola Kategori', '${s.cats.length} kategori', onTap: () => _manageCats(context)),
      ])),
      _sec('DATA'),
      Glass(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
        _row(Icons.storage_rounded, 'Data Tersimpan', '${s.txs.length} transaksi di database MySQL'),
        _row(Icons.ios_share_rounded, 'Ekspor Transaksi', 'Bagikan data dalam format CSV (Excel)', onTap: () => _export(context)),
        _row(Icons.sync_rounded, 'Sinkronkan Ulang', 'Muat ulang data dari server', onTap: () async {
          try {
            await s.refresh();
            if (context.mounted) toast(context, 'Data diperbarui');
          } on ApiError catch (e) {
            if (context.mounted) toast(context, e.message, error: true);
          }
        }),
      ])),
      _sec('OCR & KONEKSI'),
      Glass(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
        _row(Icons.document_scanner_rounded, 'Mesin OCR', 'Google ML Kit · berjalan offline di perangkat', trailing: const SizedBox()),
        _row(Icons.dns_rounded, 'Alamat Server', Api.base, onTap: () => _server(context)),
      ])),
      _sec('TENTANG'),
      Glass(padding: const EdgeInsets.symmetric(vertical: 4), child: Column(children: [
        _row(Icons.shield_outlined, 'Privasi & Keamanan', 'Password di-hash (bcrypt), sesi memakai token JWT', trailing: const SizedBox()),
        _row(Icons.info_outline_rounded, 'Tentang DompetKu', 'Versi 1.0.0', trailing: const SizedBox()),
      ])),
      const SizedBox(height: 16),
      Glass(padding: const EdgeInsets.symmetric(vertical: 4), child: _row(Icons.logout_rounded, 'Keluar', '', color: C.danger, onTap: () => _logout(context), trailing: const SizedBox())),
    ]);
  }

  void _manageCats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => const _CatSheet(),
    );
  }
}

class _CatSheet extends StatefulWidget {
  const _CatSheet();
  @override
  State<_CatSheet> createState() => _CatSheetState();
}

class _CatSheetState extends State<_CatSheet> {
  final _name = TextEditingController();
  String _type = 'expense', _icon = 'pets';
  Color _color = const Color(0xFF3B82F6);
  static const _colors = [Color(0xFF3B82F6), Color(0xFFF59E0B), Color(0xFF10B981), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFFEF4444), Color(0xFF06B6D4)];

  Future<void> _add() async {
    if (_name.text.trim().isEmpty) return;
    try {
      await context.read<AppState>().addCat(_name.text.trim(), _icon, _color, _type);
      _name.clear();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Kelola Kategori', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(children: [
              for (final Cat c in s.cats)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: IconBox(icon: c.icon, color: c.color, size: 40),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(c.type == 'income' ? 'Pemasukan' : 'Pengeluaran', style: const TextStyle(fontSize: 11.5)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: C.danger),
                    onPressed: () => s.deleteCat(c.id),
                  ),
                ),
            ]),
          ),
          const Divider(),
          Row(children: [
            Expanded(child: TextField(controller: _name, decoration: const InputDecoration(hintText: 'Kategori baru'))),
            const SizedBox(width: 8),
            ToggleButtons(
              isSelected: [_type == 'expense', _type == 'income'],
              onPressed: (i) => setState(() => _type = i == 0 ? 'expense' : 'income'),
              borderRadius: BorderRadius.circular(12),
              constraints: const BoxConstraints(minHeight: 48, minWidth: 44),
              children: const [Icon(Icons.arrow_upward_rounded), Icon(Icons.arrow_downward_rounded)],
            ),
          ]),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (final k in ['pets', 'home', 'flight', 'sports_esports', 'savings', 'work'])
                GestureDetector(
                  onTap: () => setState(() => _icon = k),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _icon == k ? C.soft : Colors.grey.shade100, borderRadius: BorderRadius.circular(12), border: Border.all(color: _icon == k ? C.primary : Colors.transparent)),
                    child: Icon(iconMap[k], size: 22, color: C.primaryDark),
                  ),
                ),
              const SizedBox(width: 8),
              for (final c in _colors)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: _color == c ? C.ink : Colors.transparent, width: 2)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 12),
          GButton(label: 'Tambah Kategori', icon: Icons.add_rounded, onTap: _add),
        ]),
      ),
    );
  }
}
