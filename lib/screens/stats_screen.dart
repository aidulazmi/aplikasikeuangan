import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/fmt.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../providers/app_state.dart';

class _Agg {
  final List<double> v;
  final List<String> l;
  final double exp, inc;
  final List<Tx> txs;
  _Agg(this.v, this.l, this.exp, this.inc, this.txs);
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _p = 1, _off = 0; // 0 minggu, 1 bulan, 2 tahun

  List<DateTime> _range(int off) {
    final n = DateTime.now();
    switch (_p) {
      case 0:
        final end = DateTime(n.year, n.month, n.day + 1 + 7 * off);
        return [end.subtract(const Duration(days: 7)), end];
      case 1:
        return [DateTime(n.year, n.month + off, 1), DateTime(n.year, n.month + off + 1, 1)];
      default:
        return [DateTime(n.year + off, 1, 1), DateTime(n.year + off + 1, 1, 1)];
    }
  }

  _Agg _agg(AppState s, int off) {
    final r = _range(off);
    final txs = s.inRange(r[0], r[1]);
    late int n;
    late List<String> labels;
    if (_p == 0) {
      n = 7;
      labels = List.generate(7, (i) => DateFormat('E', 'id_ID').format(r[0].add(Duration(days: i))));
    } else if (_p == 1) {
      n = 5;
      labels = const ['1-7', '8-14', '15-21', '22-28', '29+'];
    } else {
      n = 12;
      labels = List.generate(12, (i) => DateFormat('MMM', 'id_ID').format(DateTime(2000, i + 1)));
    }
    final v = List<double>.filled(n, 0);
    double exp = 0, inc = 0;
    for (final t in txs) {
      if (t.isExpense) {
        exp += t.amount;
        final i = _p == 0 ? t.date.difference(r[0]).inDays : (_p == 1 ? (t.date.day - 1) ~/ 7 : t.date.month - 1);
        if (i >= 0 && i < n) v[i] += t.amount;
      } else {
        inc += t.amount;
      }
    }
    return _Agg(v, labels, exp, inc, txs);
  }

  String _title() {
    final r = _range(_off);
    if (_p == 0) return '${DateFormat('d MMM', 'id_ID').format(r[0])} - ${DateFormat('d MMM', 'id_ID').format(r[1].subtract(const Duration(days: 1)))}';
    if (_p == 1) return DateFormat('MMMM y', 'id_ID').format(r[0]);
    return '${r[0].year}';
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final a = _agg(s, _off), prev = _agg(s, _off - 1);
    final diff = prev.exp > 0 ? (a.exp - prev.exp) / prev.exp * 100 : null;
    final maxV = a.v.fold(0.0, (m, x) => x > m ? x : m);

    // per kategori
    final byCat = <String, double>{};
    final colors = <String, Color>{};
    final icons = <String, String>{};
    final byMerchant = <String, double>{};
    for (final t in a.txs.where((t) => t.isExpense)) {
      final k = t.catName ?? 'Tanpa kategori';
      byCat[k] = (byCat[k] ?? 0) + t.amount;
      colors[k] = t.catColor ?? C.muted;
      icons[k] = t.catIcon ?? 'more_horiz';
      byMerchant[t.merchant] = (byMerchant[t.merchant] ?? 0) + t.amount;
    }
    final cats = byCat.entries.toList()..sort((x, y) => y.value.compareTo(x.value));
    final merch = byMerchant.entries.toList()..sort((x, y) => y.value.compareTo(x.value));

    return ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 120), children: [
      const Padding(padding: EdgeInsets.only(left: 0, bottom: 12), child: Text('Statistik Pengeluaran', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.6), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          for (final e in ['Mingguan', 'Bulanan', 'Tahunan'].asMap().entries)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _p = e.key;
                  _off = 0;
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(gradient: _p == e.key ? C.gradient : null, borderRadius: BorderRadius.circular(14)),
                  child: Text(e.value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _p == e.key ? Colors.white : C.muted)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        IconButton(onPressed: () => setState(() => _off--), icon: const Icon(Icons.chevron_left_rounded)),
        Expanded(child: Center(child: Text(_title(), style: const TextStyle(fontWeight: FontWeight.w700)))),
        IconButton(onPressed: _off >= 0 ? null : () => setState(() => _off++), icon: const Icon(Icons.chevron_right_rounded)),
      ]),
      Text('Total pengeluaran', style: const TextStyle(color: C.muted, fontSize: 12.5)),
      Text(rp(a.exp), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
      if (diff != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${diff <= 0 ? '↓' : '↑'} ${diff.abs().toStringAsFixed(1).replaceAll('.', ',')}% dibanding periode sebelumnya',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: diff <= 0 ? C.primaryDark : C.danger),
          ),
        ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _mini('Pemasukan', rp(a.inc), C.primaryDark)),
        const SizedBox(width: 12),
        Expanded(child: _mini('Selisih', rp(a.inc - a.exp, sign: true), a.inc - a.exp >= 0 ? C.primaryDark : C.danger)),
      ]),
      const SizedBox(height: 16),
      Glass(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tren Pengeluaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: BarChart(BarChartData(
              maxY: maxV == 0 ? 100 : maxV * 1.25,
              gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxV == 0 ? 50 : maxV / 3,
                  getDrawingHorizontalLine: (_) => FlLine(color: C.primary.withOpacity(.12), strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(), rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 38,
                  getTitlesWidget: (v, m) => v == m.max || v == 0 && maxV == 0 ? const SizedBox() : Text(rpShort(v), style: const TextStyle(fontSize: 9.5, color: C.muted)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(a.l[v.toInt()], style: const TextStyle(fontSize: 10, color: C.muted)),
                  ),
                )),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => C.ink,
                  getTooltipItem: (g, gi, r, ri) => BarTooltipItem(rp(r.toY), const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ),
              barGroups: [
                for (var i = 0; i < a.v.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: a.v[i],
                      width: _p == 2 ? 14 : 22,
                      borderRadius: BorderRadius.circular(8),
                      color: a.v[i] == maxV && maxV > 0 ? C.primary : C.primary.withOpacity(.3),
                    ),
                  ]),
              ],
            )),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Glass(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pengeluaran per Kategori', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 16),
          if (cats.isEmpty)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Belum ada data pada periode ini', style: TextStyle(color: C.muted))))
          else ...[
            SizedBox(
              height: 190,
              child: Stack(alignment: Alignment.center, children: [
                PieChart(PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 62,
                  sections: [for (final c in cats) PieChartSectionData(value: c.value, color: colors[c.key], radius: 26, showTitle: false)],
                )),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Total', style: TextStyle(color: C.muted, fontSize: 11)),
                  Text(rp(a.exp), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            for (final c in cats)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(children: [
                  IconBox(icon: icons[c.key], color: colors[c.key]!, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.key, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: c.value / a.exp, minHeight: 5,
                          backgroundColor: colors[c.key]!.withOpacity(.15),
                          valueColor: AlwaysStoppedAnimation(colors[c.key]!),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(rp(c.value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                    Text('${(c.value / a.exp * 100).round()}%', style: const TextStyle(color: C.muted, fontSize: 11)),
                  ]),
                ]),
              ),
          ],
        ]),
      ),
      if (merch.isNotEmpty) ...[
        const SizedBox(height: 16),
        Glass(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Merchant Teratas', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 10),
            for (final m in merch.take(5).toList().asMap().entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  CircleAvatar(radius: 13, backgroundColor: C.soft, child: Text('${m.key + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.primaryDark))),
                  const SizedBox(width: 12),
                  Expanded(child: Text(m.value.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600))),
                  Text(rp(m.value.value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ]),
              ),
          ]),
        ),
      ],
    ]);
  }

  Widget _mini(String l, String v, Color c) => Glass(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l, style: const TextStyle(color: C.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(v, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: c)),
        ]),
      );
}
