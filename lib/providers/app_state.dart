import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api.dart';
import '../core/fmt.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  bool ready = false, loading = false;
  Map<String, dynamic>? user;
  List<Cat> cats = [];
  List<Tx> txs = [];
  double budget = 0;

  bool get loggedIn => Api.token != null;
  String get firstName => ((user?['name'] ?? 'Pengguna') as String).split(' ').first;

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    Api.base = p.getString('server') ?? Api.base;
    Api.token = p.getString('token');
    if (Api.token != null) {
      try {
        user = (await Api.get('/api/me'))['user'];
        await refresh();
      } on ApiError catch (e) {
        if (e.code == 401) {
          Api.token = null;
          p.remove('token');
        }
      }
    }
    ready = true;
    notifyListeners();
  }

  Future<void> setServer(String url) async {
    var u = url.trim();
    if (u.endsWith('/')) u = u.substring(0, u.length - 1);
    if (!u.startsWith('http')) u = 'http://$u';
    Api.base = u;
    (await SharedPreferences.getInstance()).setString('server', u);
    notifyListeners();
  }

  Future<void> auth(String path, Map body) async {
    final r = await Api.post(path, body);
    Api.token = r['token'];
    user = Map<String, dynamic>.from(r['user']);
    (await SharedPreferences.getInstance()).setString('token', Api.token!);
    await refresh();
    notifyListeners();
  }

  Future<void> logout() async {
    Api.token = null;
    user = null;
    txs = [];
    cats = [];
    (await SharedPreferences.getInstance()).remove('token');
    notifyListeners();
  }

  Future<void> refresh() async {
    loading = true;
    notifyListeners();
    try {
      final r = await Future.wait([Api.get('/api/categories'), Api.get('/api/transactions'), Api.get('/api/budget')]);
      cats = (r[0]['categories'] as List).map((e) => Cat.fromJson(e)).toList();
      txs = (r[1]['transactions'] as List).map((e) => Tx.fromJson(e)).toList();
      budget = (r[2]['amount'] as num).toDouble();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> saveTx(Tx t, {File? receipt}) async {
    final f = <String, String>{
      'type': t.type,
      'merchant': t.merchant,
      'amount': t.amount.toStringAsFixed(0),
      'tx_date': sqlDate(t.date),
      'payment_method': t.method,
      'note': t.note,
      'source': t.source,
      'category_id': t.categoryId?.toString() ?? '',
      if (t.ocrText != null) 'ocr_text': t.ocrText!,
    };
    await Api.multipart('POST', t.id == null ? '/api/transactions' : '/api/transactions/${t.id}', f, receipt);
    await refresh();
  }

  Future<void> deleteTx(int id) async {
    await Api.delete('/api/transactions/$id');
    txs.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<void> setBudget(double v) async {
    await Api.put('/api/budget', {'amount': v});
    budget = v;
    notifyListeners();
  }

  Future<void> addCat(String name, String icon, Color color, String type) async {
    await Api.post('/api/categories', {'name': name, 'icon': icon, 'color': colorHex(color), 'type': type});
    await refresh();
  }

  Future<void> deleteCat(int id) async {
    await Api.delete('/api/categories/$id');
    await refresh();
  }

  // ---- hitungan ----
  List<Tx> inRange(DateTime start, DateTime end) =>
      txs.where((t) => !t.date.isBefore(start) && t.date.isBefore(end)).toList();

  double expenseIn(DateTime start, DateTime end) =>
      inRange(start, end).where((t) => t.isExpense).fold(0.0, (a, t) => a + t.amount);

  double expenseMonth(DateTime m) => expenseIn(DateTime(m.year, m.month, 1), DateTime(m.year, m.month + 1, 1));
}
