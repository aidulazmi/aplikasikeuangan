import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrResult {
  String? merchant, method, categoryGuess;
  double? amount;
  DateTime? date;
  String raw;
  OcrResult({this.merchant, this.method, this.categoryGuess, this.amount, this.date, this.raw = ''});
  bool get complete => amount != null && merchant != null;
}

class OcrService {
  static Future<OcrResult> scan(File f) async {
    final rec = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final t = await rec.processImage(InputImage.fromFile(f));
      return parse(t.text);
    } finally {
      rec.close();
    }
  }

  static const _merchants = {
    'shopeepay': 'ShopeePay', 'shopee': 'Shopee', 'gopay': 'GoPay', 'gojek': 'Gojek', 'grab': 'Grab',
    'ovo': 'OVO', 'dana': 'DANA', 'linkaja': 'LinkAja', 'tokopedia': 'Tokopedia', 'lazada': 'Lazada',
    'indomaret': 'Indomaret', 'alfamart': 'Alfamart', 'starbucks': 'Starbucks', 'kopi kenangan': 'Kopi Kenangan',
    'janji jiwa': 'Janji Jiwa', 'pln': 'PLN', 'indihome': 'IndiHome', 'telkomsel': 'Telkomsel', 'pertamina': 'Pertamina',
    'traveloka': 'Traveloka', 'tiket.com': 'tiket.com', 'bukalapak': 'Bukalapak', 'blibli': 'Blibli',
  };
  static const _ewallet = ['shopeepay', 'gopay', 'ovo', 'dana', 'linkaja', 'isaku'];
  static const _bank = ['bca', 'mandiri', 'bni', 'bri', 'cimb', 'permata', 'transfer', 'btn', 'jago'];
  static const _cats = {
    'Makanan': ['kopi', 'coffee', 'resto', 'cafe', 'food', 'makan', 'warung', 'bakso', 'ayam', 'pizza', 'burger', 'kfc', 'starbucks', 'kenangan', 'janji jiwa'],
    'Transportasi': ['gojek', 'grab', 'bensin', 'pertamina', 'parkir', 'tol', 'krl', 'mrt', 'transjakarta', 'bluebird', 'shell', 'kereta'],
    'Tagihan': ['pln', 'listrik', 'pdam', 'internet', 'indihome', 'telkom', 'pulsa', 'bpjs', 'token', 'tagihan', 'pascabayar'],
    'Hiburan': ['netflix', 'spotify', 'cinema', 'xxi', 'cgv', 'game', 'steam'],
    'Kesehatan': ['apotek', 'farmasi', 'klinik', 'rumah sakit', 'dokter', 'kimia farma', 'guardian'],
    'Pendidikan': ['sekolah', 'kursus', 'buku', 'gramedia', 'udemy'],
    'Belanja': ['shopee', 'tokopedia', 'lazada', 'indomaret', 'alfamart', 'market', 'mart', 'belanja', 'bukalapak', 'blibli'],
  };
  static const _months = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'may': 5, 'jun': 6, 'jul': 7, 'agu': 8, 'aug': 8,
    'ags': 8, 'sep': 9, 'okt': 10, 'oct': 10, 'nov': 11, 'des': 12, 'dec': 12,
  };

  static double? _toNum(String s) {
    var x = s;
    if (RegExp(r'[.,]\d{1,2}$').hasMatch(x) && !RegExp(r'[.,]\d{3}$').hasMatch(x)) {
      x = x.substring(0, x.lastIndexOf(RegExp(r'[.,]')));
    }
    return double.tryParse(x.replaceAll(RegExp(r'[.,]'), ''));
  }

  static OcrResult parse(String text) {
    final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final low = text.toLowerCase();
    final res = OcrResult(raw: text);

    // --- Nominal ---
    final numRe = RegExp(r'(Rp\.?\s*)?(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{1,2})?|\d{4,})', caseSensitive: false);
    final kw = RegExp(r'total|jumlah|nominal|bayar|pembayaran|tagihan|grand|amount', caseSensitive: false);
    final kwAmts = <double>[], rpAmts = <double>[], allAmts = <double>[];
    for (var i = 0; i < lines.length; i++) {
      for (final m in numRe.allMatches(lines[i])) {
        final v = _toNum(m.group(2)!);
        if (v == null || v < 500 || v > 1e10) continue;
        allAmts.add(v);
        if (m.group(1) != null) rpAmts.add(v);
        final near = lines[i] + (i > 0 ? ' ${lines[i - 1]}' : '');
        if (kw.hasMatch(near)) kwAmts.add(v);
      }
    }
    List<double> pick = kwAmts.isNotEmpty ? kwAmts : (rpAmts.isNotEmpty ? rpAmts : allAmts);
    if (pick.isNotEmpty) res.amount = pick.reduce((a, b) => a > b ? a : b);

    // --- Tanggal & jam ---
    DateTime? d;
    final r1 = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})').firstMatch(text);
    final r2 = RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\.?\s+(\d{4})').firstMatch(text);
    if (r2 != null && _months[r2.group(2)!.toLowerCase().substring(0, 3)] != null) {
      d = DateTime(int.parse(r2.group(3)!), _months[r2.group(2)!.toLowerCase().substring(0, 3)]!, int.parse(r2.group(1)!));
    } else if (r1 != null) {
      var y = int.parse(r1.group(3)!);
      if (y < 100) y += 2000;
      final dd = int.parse(r1.group(1)!), mm = int.parse(r1.group(2)!);
      if (mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) d = DateTime(y, mm, dd);
    }
    final tm = RegExp(r'\b([01]?\d|2[0-3])[:.]([0-5]\d)\b(?![.\-/]\d)').firstMatch(text);
    if (d != null) {
      d = DateTime(d.year, d.month, d.day, tm != null ? int.parse(tm.group(1)!) : 12, tm != null ? int.parse(tm.group(2)!) : 0);
      if (d.isAfter(DateTime.now().add(const Duration(days: 1)))) d = null;
    }
    res.date = d;

    // --- Merchant ---
    for (final e in _merchants.entries) {
      if (low.contains(e.key)) {
        res.merchant = e.value;
        break;
      }
    }
    res.merchant ??= lines.cast<String?>().firstWhere(
        (l) => RegExp(r'[A-Za-z]{3,}').hasMatch(l!) && !kw.hasMatch(l) && l.length < 40,
        orElse: () => null);

    // --- Metode & kategori ---
    if (_ewallet.any(low.contains)) {
      res.method = 'E-Wallet';
    } else if (low.contains('qris')) {
      res.method = 'QRIS';
    } else if (_bank.any((b) => RegExp('\\b$b\\b').hasMatch(low))) {
      res.method = 'Transfer';
    }
    final hay = '${res.merchant ?? ''} $low'.toLowerCase();
    for (final e in _cats.entries) {
      if (e.value.any(hay.contains)) {
        res.categoryGuess = e.key;
        break;
      }
    }
    return res;
  }
}
