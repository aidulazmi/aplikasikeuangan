import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/fmt.dart';
import '../core/ui.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../services/ocr_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final Tx? tx;
  final OcrResult? ocr;
  final File? image;
  const TransactionFormScreen({super.key, this.tx, this.ocr, this.image});
  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  static const methods = ['Tunai', 'E-Wallet', 'QRIS', 'Transfer', 'Kartu Debit', 'Kartu Kredit'];
  final _merchant = TextEditingController(), _amount = TextEditingController(), _note = TextEditingController();
  late String _type, _method;
  late DateTime _date;
  int? _cat;
  File? _image;
  bool _busy = false, _fromOcr = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tx, o = widget.ocr, s = context.read<AppState>();
    _image = widget.image;
    _fromOcr = o != null;
    _type = t?.type ?? 'expense';
    _method = t?.method ?? o?.method ?? 'Tunai';
    _date = t?.date ?? o?.date ?? DateTime.now();
    if (t != null) {
      _merchant.text = t.merchant;
      _amount.text = groupDigits(t.amount.round().toString());
      _note.text = t.note;
      _cat = t.categoryId;
    } else if (o != null) {
      _merchant.text = o.merchant ?? '';
      if (o.amount != null) _amount.text = groupDigits(o.amount!.round().toString());
      final g = s.cats.where((c) => c.type == 'expense' && c.name == o.categoryGuess);
      _cat = g.isNotEmpty ? g.first.id : null;
    }
    if (_cat == null && t == null && _catsFor(s).isNotEmpty) _cat = _catsFor(s).first.id;
  }

  List<Cat> _catsFor(AppState s) => s.cats.where((c) => c.type == _type).toList();

  Future<void> _save() async {
    final s = context.read<AppState>();
    final amt = parseAmt(_amount.text);
    if (_merchant.text.trim().isEmpty) return toast(context, 'Nama merchant wajib diisi', error: true);
    if (amt <= 0) return toast(context, 'Nominal harus lebih dari 0', error: true);
    final cat = s.cats.where((c) => c.id == _cat);
    setState(() => _busy = true);
    try {
      await s.saveTx(
        Tx(
          id: widget.tx?.id,
          type: _type,
          merchant: _merchant.text.trim(),
          amount: amt,
          date: _date,
          categoryId: cat.isEmpty ? null : _cat,
          method: _method,
          note: _note.text.trim(),
          source: (_fromOcr || widget.tx?.source == 'ocr') ? 'ocr' : 'manual',
          ocrText: widget.ocr?.raw,
        ),
        receipt: _image,
      );
      if (mounted) {
        Navigator.pop(context);
        toast(context, 'Transaksi disimpan');
      }
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus transaksi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: C.danger), onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<AppState>().deleteTx(widget.tx!.id!);
      if (mounted) Navigator.pop(context);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _rescan() async {
    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.photo_camera_rounded), title: const Text('Ambil foto'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_rounded), title: const Text('Pilih dari galeri'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );
    if (src == null) return;
    final x = await ImagePicker().pickImage(source: src, imageQuality: 85, maxWidth: 2200);
    if (x == null || !mounted) return;
    final f = File(x.path);
    setState(() => _busy = true);
    try {
      final o = await OcrService.scan(f);
      setState(() {
        _image = f;
        _fromOcr = true;
        if (o.merchant != null) _merchant.text = o.merchant!;
        if (o.amount != null) _amount.text = groupDigits(o.amount!.round().toString());
        if (o.date != null) _date = o.date!;
        if (o.method != null) _method = o.method!;
        final g = context.read<AppState>().cats.where((c) => c.type == 'expense' && c.name == o.categoryGuess);
        if (g.isNotEmpty) _cat = g.first.id;
      });
    } catch (_) {
      if (mounted) toast(context, 'Gagal membaca gambar', error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String t, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          if (trailing != null) trailing,
        ]),
      );

  Widget _preview() {
    final local = _image, remote = receiptUrl(widget.tx?.receiptPath);
    if (local == null && remote == null) return const SizedBox.shrink();
    final img = local != null ? Image.file(local, fit: BoxFit.cover) : Image.network(remote!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded));
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Glass(
        padding: const EdgeInsets.all(10),
        radius: 20,
        onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(child: InteractiveViewer(child: local != null ? Image.file(local) : Image.network(remote!)))),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 56, child: img)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bukti / struk', style: TextStyle(color: C.muted, fontSize: 11.5)),
              Text(_fromOcr ? 'Data berhasil dibaca' : 'Lampiran tersimpan', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
          const Text('Lihat', style: TextStyle(color: C.primaryDark, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cats = _catsFor(s);
    final editing = widget.tx != null;
    final missing = _fromOcr && (widget.ocr?.amount == null || widget.ocr?.merchant == null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(editing ? 'Edit Transaksi' : (_fromOcr ? 'Konfirmasi Transaksi' : 'Catat Transaksi'), style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [if (editing) IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded, color: C.danger))],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), children: [
          if (_fromOcr)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: const Color(0xFFFFF7DD), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF8A6D00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(missing ? 'Sebagian data tidak terbaca. Lengkapi secara manual.' : 'Periksa kembali data sebelum menyimpan.',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B5400))),
                ),
              ]),
            ),
          _preview(),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white.withOpacity(.6), borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                for (final e in {'expense': 'Pengeluaran', 'income': 'Pemasukan'}.entries)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _type = e.key;
                        final l = _catsFor(s);
                        _cat = l.isNotEmpty ? l.first.id : null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(gradient: _type == e.key ? C.gradient : null, borderRadius: BorderRadius.circular(12)),
                        child: Text(e.value, style: TextStyle(fontWeight: FontWeight.w700, color: _type == e.key ? Colors.white : C.muted)),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
          _label('Nominal (Rp)', trailing: _fromOcr && _amount.text.isNotEmpty ? const Text('Hasil OCR', style: TextStyle(fontSize: 11, color: C.primaryDark, fontWeight: FontWeight.w700)) : null),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            inputFormatters: [ThousandsFormatter()],
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: C.primaryDark),
            decoration: const InputDecoration(prefixText: 'Rp ', hintText: '0'),
          ),
          _label('Nama Merchant / Keterangan'),
          TextField(controller: _merchant, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'cth. Kopi Kenangan', prefixIcon: Icon(Icons.storefront_rounded))),
          _label('Tanggal & Waktu'),
          Row(children: [
            Expanded(
              flex: 3,
              child: _tap(Icons.calendar_today_rounded, dateLong(_date), () async {
                final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2015), lastDate: DateTime.now().add(const Duration(days: 1)));
                if (d != null) setState(() => _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
              }),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _tap(Icons.access_time_rounded, timeStr(_date), () async {
                final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_date));
                if (t != null) setState(() => _date = DateTime(_date.year, _date.month, _date.day, t.hour, t.minute));
              }),
            ),
          ]),
          _label('Kategori'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final c in cats)
              GestureDetector(
                onTap: () => setState(() => _cat = c.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _cat == c.id ? c.color.withOpacity(.18) : Colors.white.withOpacity(.65),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _cat == c.id ? c.color : Colors.transparent, width: 1.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(iconMap[c.icon] ?? Icons.more_horiz_rounded, size: 16, color: c.color),
                    const SizedBox(width: 6),
                    Text(c.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
          ]),
          _label('Metode Pembayaran'),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final m in methods)
              ChoiceChip(
                label: Text(m),
                selected: _method == m,
                onSelected: (_) => setState(() => _method = m),
                selectedColor: C.soft,
                backgroundColor: Colors.white.withOpacity(.65),
                side: BorderSide(color: _method == m ? C.primary : Colors.transparent),
                labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _method == m ? C.primaryDark : C.ink),
              ),
          ]),
          _label('Catatan (opsional)'),
          TextField(controller: _note, maxLines: 2, decoration: const InputDecoration(hintText: 'cth. Pembelian kebutuhan harian', prefixIcon: Icon(Icons.notes_rounded))),
          const SizedBox(height: 24),
          GButton(label: 'Simpan Transaksi', icon: Icons.check_rounded, loading: _busy, onTap: _save),
          const SizedBox(height: 12),
          GButton(label: _image == null ? 'Scan / Lampirkan Struk' : 'Ambil Ulang Screenshot', icon: Icons.photo_camera_rounded, filled: false, onTap: _busy ? null : _rescan),
        ]),
      ),
    );
  }

  Widget _tap(IconData i, String t, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(color: Colors.white.withOpacity(.7), borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Icon(i, size: 18, color: C.muted),
            const SizedBox(width: 10),
            Expanded(child: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5))),
          ]),
        ),
      );
}
