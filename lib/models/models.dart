import 'package:flutter/material.dart';

Color hexColor(String? h) {
  try {
    return Color(int.parse('FF${h!.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFF9CA3AF);
  }
}

String colorHex(Color c) => '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

class Cat {
  final int id;
  final String name, icon, type;
  final Color color;
  Cat({required this.id, required this.name, required this.icon, required this.type, required this.color});
  factory Cat.fromJson(Map j) =>
      Cat(id: j['id'], name: j['name'], icon: j['icon'] ?? 'more_horiz', type: j['type'], color: hexColor(j['color']));
}

class Tx {
  int? id;
  String type, merchant, method, note, source;
  double amount;
  DateTime date;
  int? categoryId;
  String? catName, catIcon, receiptPath, ocrText;
  Color? catColor;

  Tx({
    this.id,
    this.type = 'expense',
    required this.merchant,
    required this.amount,
    required this.date,
    this.categoryId,
    this.catName,
    this.catIcon,
    this.catColor,
    this.method = 'Tunai',
    this.note = '',
    this.receiptPath,
    this.source = 'manual',
    this.ocrText,
  });

  bool get isExpense => type == 'expense';

  factory Tx.fromJson(Map j) => Tx(
        id: j['id'],
        type: j['type'],
        merchant: j['merchant'],
        amount: double.parse('${j['amount']}'),
        date: DateTime.parse(j['tx_date'].toString().replaceFirst(' ', 'T')),
        categoryId: j['category_id'],
        catName: j['category_name'],
        catIcon: j['category_icon'],
        catColor: j['category_color'] == null ? null : hexColor(j['category_color']),
        method: j['payment_method'] ?? 'Tunai',
        note: j['note'] ?? '',
        receiptPath: j['receipt_path'],
        source: j['source'] ?? 'manual',
      );
}
