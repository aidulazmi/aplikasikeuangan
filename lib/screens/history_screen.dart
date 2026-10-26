import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/fmt.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import 'transaction_form.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _q = '';
  int _range = 0; // 0 semua, 1 hari ini, 2 minggu, 3 bulan
  int? _cat;
  String? _method;

  Widget _pill(String t, bool on, VoidCallback f) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: f,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              gradient: on ? C.gradient : null,
              color: on ? null : Colors.white.withOpacity(.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(t, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: on ? Colors.white : C.ink)),
          ),
        ),
      );

  Future<void> _pickCat(AppState s) async {
    final r = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          ListTile(title: const Text('Semua kategori'), leading: const Icon(Icons.apps_rounded), onTap: () => Navigator.pop(context, -1)),
          for (final c in s.cats)
            ListTile(leading: IconBox(icon: c.icon, color: c.color, size: 38), title: Text(c.name), onTap: () => Navigator.pop(context, c.id)),
        ]),
      ),
    );
    if (r != null) setState(() => _cat = r == -1 ? null : r);
  }

  Future<void> _pickMethod() async {
    const m = ['Tunai', 'E-Wallet', 'QRIS', 'Transfer', 'Kartu Debit', 'Kartu Kredit'];
    final r = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
          ListTile(title: const Text('Semua metode'), onTap: () => Navigator.pop(context, '')),
          for (final x in m) ListTile(title: Text(x), onTap: () => Navigator.pop(context, x)),
        ]),
      ),
    );
    if (r != null) setState(() => _method = r.isEmpty ? null : r);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now(), today = DateTime(now.year, now.month, now.day);
    final from = [null, today, today.subtract(Duration(days: now.weekday - 1)), DateTime(now.year, now.month, 1)][_range];
    final list = s.txs.where((t) {
      if (from != null && t.date.isBefore(from)) return false;
      if (_cat != null && t.categoryId != _cat) return false;
      if (_method != null && t.method != _method) return false;
      if (_q.isNotEmpty && !('${t.merchant} ${t.note} ${t.catName ?? ''}').toLowerCase().contains(_q.toLowerCase())) return false;
      return true;
    }).toList();

    final items = <Object>[];
    String? last;
    for (final t in list) {
      final k = '${t.date.year}-${t.date.month}-${t.date.day}';
      if (k != last) {
        last = k;
        final sum = list.where((x) => x.isExpense && '${x.date.year}-${x.date.month}-${x.date.day}' == k).fold(0.0, (a, x) => a + x.amount);
        items.add(MapEntry(t.date, sum));
      }
      items.add(t);
    }
    final catName = _cat == null ? 'Semua kategori' : s.cats.firstWhere((c) => c.id == _cat, orElse: () => s.cats.first).name;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Header('Riwayat Transaksi',
          trailing: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen())),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(gradient: C.gradient, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          )),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: const InputDecoration(hintText: 'Cari transaksi, merchant, catatan…', prefixIcon: Icon(Icons.search_rounded)),
        ),
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          for (final e in ['Semua', 'Hari Ini', 'Minggu Ini', 'Bulan Ini'].asMap().entries)
            _pill(e.value, _range == e.key, () => setState(() => _range = e.key)),
        ]),
      ),
      const SizedBox(height: 10),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Expanded(child: _filter(Icons.category_rounded, catName, _cat != null, () => _pickCat(s))),
          const SizedBox(width: 10),
          Expanded(child: _filter(Icons.account_balance_wallet_rounded, _method ?? 'Semua metode', _method != null, _pickMethod)),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: RefreshIndicator(
          color: C.primary,
          onRefresh: () async {
            try {
              await s.refresh();
            } on ApiError catch (e) {
              if (context.mounted) toast(context, e.message, error: true);
            }
          },
          child: items.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 80),
                  const Icon(Icons.search_off_rounded, size: 48, color: C.muted),
                  const SizedBox(height: 8),
                  const Center(child: Text('Tidak ada transaksi ditemukan', style: TextStyle(color: C.muted))),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    if (it is MapEntry<DateTime, double>) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text(dayLabel(it.key).toUpperCase(),
                              style: const TextStyle(fontSize: 11, color: C.muted, fontWeight: FontWeight.w700, letterSpacing: .8)),
                          if (it.value > 0) Text('-${rp(it.value)}', style: const TextStyle(fontSize: 11.5, color: C.muted, fontWeight: FontWeight.w700)),
                        ]),
                      );
                    }
                    final t = it as Tx;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Dismissible(
                        key: ValueKey('tx${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 22),
                          decoration: BoxDecoration(color: C.danger, borderRadius: BorderRadius.circular(22)),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Hapus transaksi?'),
                              content: Text('${t.merchant} · ${rp(t.amount)}'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: C.danger),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Hapus')),
                              ],
                            ),
                          );
                          if (ok != true) return false;
                          try {
                            await s.deleteTx(t.id!);
                            return true;
                          } on ApiError catch (e) {
                            if (context.mounted) toast(context, e.message, error: true);
                            return false;
                          }
                        },
                        child: Glass(
                          radius: 22,
                          padding: EdgeInsets.zero,
                          child: TxTile(
                            tx: t,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(tx: t))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }

  Widget _filter(IconData i, String t, bool on, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: on ? C.soft : Colors.white.withOpacity(.65),
            borderRadius: BorderRadius.circular(16),
            border: on ? Border.all(color: C.primary) : null,
          ),
          child: Row(children: [
            Icon(i, size: 16, color: on ? C.primaryDark : C.muted),
            const SizedBox(width: 6),
            Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
            const Icon(Icons.expand_more_rounded, size: 18, color: C.muted),
          ]),
        ),
      );
}
