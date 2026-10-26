import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api.dart';
import '../core/ui.dart';
import '../providers/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), _pass = TextEditingController();
  bool _register = false, _hide = true, _busy = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await context.read<AppState>().auth(_register ? '/api/auth/register' : '/api/auth/login', {
        if (_register) 'name': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _pass.text,
      });
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _serverDialog() async {
    final s = context.read<AppState>();
    final c = TextEditingController(text: Api.base);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Alamat server'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Contoh: http://192.168.1.10:3000 (IP komputer yang menjalankan backend).',
              style: TextStyle(fontSize: 12.5, color: C.muted)),
          const SizedBox(height: 12),
          TextField(controller: c, keyboardType: TextInputType.url),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Simpan')),
        ],
      ),
    );
    if (ok == true) await s.setServer(c.text);
  }

  Widget _tab(String t, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: active ? [BoxShadow(color: C.primary.withOpacity(.18), blurRadius: 10)] : null,
            ),
            child: Text(t, style: TextStyle(fontWeight: FontWeight.w700, color: active ? C.primaryDark : C.muted)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    gradient: C.gradient,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: C.primary.withOpacity(.4), blurRadius: 28, offset: const Offset(0, 12))],
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 42),
                ),
                const SizedBox(height: 18),
                const Text('DompetKu', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('Catat keuangan otomatis dengan scan struk',
                    style: TextStyle(color: C.muted, fontSize: 13.5)),
                const SizedBox(height: 28),
                Glass(
                  radius: 30,
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _form,
                    child: Column(children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: C.soft.withOpacity(.8), borderRadius: BorderRadius.circular(18)),
                        child: Row(children: [
                          _tab('Masuk', !_register, () => setState(() => _register = false)),
                          _tab('Daftar', _register, () => setState(() => _register = true)),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: _register
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: TextFormField(
                                  controller: _name,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(hintText: 'Nama lengkap', prefixIcon: Icon(Icons.person_outline_rounded)),
                                  validator: (v) => (_register && (v ?? '').trim().isEmpty) ? 'Nama wajib diisi' : null,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                        validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim()) ? null : 'Email tidak valid',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pass,
                        obscureText: _hide,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                        validator: (v) => (v ?? '').length < 6 ? 'Minimal 6 karakter' : null,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 22),
                      GButton(label: _register ? 'Buat Akun' : 'Masuk', loading: _busy, onTap: _submit),
                    ]),
                  ),
                ),
                const SizedBox(height: 22),
                Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.center, children: const [
                  _Chip(Icons.document_scanner_rounded, 'Scan struk OCR'),
                  _Chip(Icons.insights_rounded, 'Statistik'),
                  _Chip(Icons.shield_outlined, 'Aman'),
                ]),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _serverDialog,
                  icon: const Icon(Icons.dns_outlined, size: 16),
                  label: const Text('Pengaturan server'),
                  style: TextButton.styleFrom(foregroundColor: C.muted),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _Chip extends StatelessWidget {
  final IconData i;
  final String t;
  const _Chip(this.i, this.t);
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: Colors.white.withOpacity(.6), borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: C.primaryDark),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      );
}
