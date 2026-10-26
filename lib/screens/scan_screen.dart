import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/ui.dart';
import '../services/ocr_service.dart';
import 'transaction_form.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _busy = false;

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, imageQuality: 85, maxWidth: 2200);
      if (x == null) return;
      setState(() => _busy = true);
      final file = File(x.path);
      final res = await OcrService.scan(file);
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => TransactionFormScreen(ocr: res, image: file)));
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        toast(context, 'Gagal membaca gambar. Coba foto yang lebih jelas.', error: true);
      }
    }
  }

  Widget _step(int n, String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          CircleAvatar(radius: 12, backgroundColor: C.soft, child: Text('$n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: C.primaryDark))),
          const SizedBox(width: 12),
          Expanded(child: Text(t, style: const TextStyle(fontSize: 13))),
        ]),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Scan Struk (OCR)', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Stack(children: [
          ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 30), children: [
            const Text('Catat transaksi lebih cepat', textAlign: TextAlign.center, style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Foto struk atau import screenshot bukti pembayaran, data terisi otomatis.',
                textAlign: TextAlign.center, style: TextStyle(color: C.muted, fontSize: 13)),
            const SizedBox(height: 22),
            Center(
              child: Container(
                width: 150,
                height: 190,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.75),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: C.primary.withOpacity(.35), width: 2),
                  boxShadow: [BoxShadow(color: C.primary.withOpacity(.2), blurRadius: 30)],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.receipt_long_rounded, size: 44, color: C.primary),
                  const SizedBox(height: 10),
                  const Text('Rp25.000', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 10),
                  for (final w in [90.0, 70.0, 80.0])
                    Container(margin: const EdgeInsets.symmetric(vertical: 3), width: w, height: 5, decoration: BoxDecoration(color: C.soft, borderRadius: BorderRadius.circular(3))),
                ]),
              ),
            ),
            const SizedBox(height: 26),
            GButton(label: 'Ambil Foto Struk', icon: Icons.photo_camera_rounded, onTap: _busy ? null : () => _pick(ImageSource.camera)),
            const SizedBox(height: 12),
            GButton(label: 'Import dari Galeri', icon: Icons.photo_library_rounded, filled: false, onTap: _busy ? null : () => _pick(ImageSource.gallery)),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen())),
                child: const Text('Isi manual saja'),
              ),
            ),
            const SizedBox(height: 8),
            Glass(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Tips agar hasil akurat', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                _step(1, 'Pastikan struk datar, terang, dan tidak buram.'),
                _step(2, 'Pastikan total pembayaran & tanggal terlihat jelas.'),
                _step(3, 'Untuk e-wallet: screenshot bukti bayar lalu import dari galeri.'),
                _step(4, 'Selalu periksa hasilnya sebelum menyimpan.'),
              ]),
            ),
            const SizedBox(height: 14),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.shield_outlined, size: 15, color: C.primaryDark),
              SizedBox(width: 6),
              Flexible(child: Text('Teks dibaca di perangkat Anda (on-device), gambar tidak dikirim ke pihak ketiga.', style: TextStyle(fontSize: 11.5, color: C.muted))),
            ]),
          ]),
          if (_busy)
            Container(
              color: Colors.white.withOpacity(.75),
              child: const Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: C.primary),
                  SizedBox(height: 16),
                  Text('Membaca teks pada gambar…', style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
        ]),
      );
}
