import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/fmt.dart';
import '../core/ui.dart';
import '../providers/app_state.dart';
import 'scan_screen.dart';
import 'transaction_form.dart';

Future<void> editBudget(BuildContext context) async {
  final s = context.read<AppState>();
  final c = TextEditingController(text: s.budget > 0 ? groupDigits(s.budget.round().toString()) : '');
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Anggaran bulanan'),
      content: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [ThousandsFormatter()],
        decoration: const InputDecoration(prefixText: 'Rp ', hintText: '2.500.000'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
      ],
    ),
  );
  if (ok == true) {
    try {
      await s.setBudget(parseAmt(c.text));
    } on ApiError catch (e) {
      if (context.mounted) toast(context, e.message, error: true);
    }
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final now = DateTime.now();
    final total = s.expenseMonth(now), prev = s.expenseMonth(DateTime(now.year, now.month - 1));
    final monthTx = s.inRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 1));
    final pct = s.budget > 0 ? (total / s.budget).clamp(0.0, 1.0) : 0.0;
    final over = s.budget > 0 && total > s.budget;
    final diff = prev > 0 ? (total - prev) / prev * 100 : null;
    final recent = s.txs.take(5).toList();

    return RefreshIndicator(
      color: C.primary,
      onRefresh: () async {
        try {
          await s.refresh();
        } on ApiError catch (e) {
          if (context.mounted) toast(context, e.message, error: true);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(DateFormat('EEEE, d MMMM', 'id_ID').format(now).toUpperCase(),
                    style: const TextStyle(color: C.muted, fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Halo, ${s.firstName}!', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ]),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.white.withOpacity(.7), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.person_rounded, color: C.primaryDark),
            ),
          ]),
          const SizedBox(height: 18),
          Glass(
            radius: 30,
            padding: const EdgeInsets.all(22),
            gradient: const LinearGradient(
                colors: [Color(0xE64CBB88), Color(0xE62A9565)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Pengeluaran ${DateFormat('MMMM', 'id_ID').format(now)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 6),
              Text(rp(total), style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              if (diff != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    diff <= 0
                        ? '↓ ${diff.abs().toStringAsFixed(1).replaceAll('.', ',')}% lebih hemat dari bulan lalu'
                        : '↑ ${diff.toStringAsFixed(1).replaceAll('.', ',')}% lebih boros dari bulan lalu',
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(height: 16),
              Divider(color: Colors.white.withOpacity(.25), height: 1),
              const SizedBox(height: 14),
              if (s.budget <= 0)
                GestureDetector(
                  onTap: () => editBudget(context),
                  child: const Row(children: [
                    Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('Atur anggaran bulanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                )
              else ...[
                GestureDetector(
                  onTap: () => editBudget(context),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Anggaran bulanan', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text(rp(s.budget), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: Colors.white.withOpacity(.25),
                    valueColor: AlwaysStoppedAnimation(over ? const Color(0xFFFFC9C9) : Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    over ? 'Melebihi anggaran ${rp(total - s.budget)}' : '${(pct * 100).round()}% terpakai · sisa ${rp(s.budget - total)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _stat(Icons.receipt_long_rounded, 'Total Transaksi', '${monthTx.length}', 'bulan ini')),
            const SizedBox(width: 14),
            Expanded(child: _stat(Icons.calendar_today_rounded, 'Rata-rata Harian', rp(total / now.day), 'per hari')),
          ]),
          const SizedBox(height: 16),
          GButton(
              label: 'Catat Transaksi',
              icon: Icons.add_rounded,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen()))),
          const SizedBox(height: 12),
          Glass(
            radius: 22,
            padding: const EdgeInsets.all(14),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen())),
            child: Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.document_scanner_rounded, color: C.primaryDark),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Scan Struk dengan OCR', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Foto struk atau import dari galeri', style: TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: C.muted),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Transaksi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const Text('Aktivitas terkini', style: TextStyle(color: C.muted, fontSize: 12)),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            Glass(
              child: Column(children: const [
                Icon(Icons.inbox_rounded, size: 40, color: C.muted),
                SizedBox(height: 8),
                Text('Belum ada transaksi', style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Tekan tombol scan hijau atau “Catat Transaksi” untuk memulai.',
                    textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 12.5)),
              ]),
            )
          else
            Glass(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: [
                for (final t in recent)
                  TxTile(
                    tx: t,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(tx: t))),
                  ),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _stat(IconData i, String l, String v, String sub) => Glass(
        padding: const EdgeInsets.all(14),
        radius: 22,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(12)),
              child: Icon(i, size: 18, color: C.primaryDark),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(l, style: const TextStyle(color: C.muted, fontSize: 11.5), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 10),
          Text(v, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(sub, style: const TextStyle(color: C.muted, fontSize: 11)),
        ]),
      );
}
