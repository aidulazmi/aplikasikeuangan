import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

String groupDigits(String s) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String rp(num v, {bool sign = false}) {
  final s = groupDigits(v.abs().round().toString());
  final p = v < 0 ? '-' : (sign ? '+' : '');
  return '${p}Rp$s';
}

String rpShort(double v) {
  if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1).replaceAll('.', ',')}jt';
  if (v >= 1e3) return '${(v / 1e3).round()}rb';
  return v.round().toString();
}

String dayLabel(DateTime d) {
  final n = DateTime.now();
  final diff = DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Kemarin';
  return DateFormat('d MMM', 'id_ID').format(d);
}

String timeStr(DateTime d) => DateFormat('HH.mm').format(d);
String dateLong(DateTime d) => DateFormat('d MMMM y', 'id_ID').format(d);
String sqlDate(DateTime d) => DateFormat('yyyy-MM-dd HH:mm:ss').format(d);
double parseAmt(String s) => double.tryParse(s.replaceAll(RegExp(r'\D'), '')) ?? 0;

class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final d = nv.text.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return nv.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    final f = groupDigits(d);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
