import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/models.dart';
import 'api.dart';
import 'fmt.dart';

class C {
  static const primary = Color(0xFF3DAA78);
  static const primaryDark = Color(0xFF237A55);
  static const soft = Color(0xFFE3F5EB);
  static const ink = Color(0xFF16352A);
  static const muted = Color(0xFF6B8579);
  static const danger = Color(0xFFE5484D);
  static const gradient = LinearGradient(
      colors: [Color(0xFF5CC693), Color(0xFF2E9E6B)], begin: Alignment.topLeft, end: Alignment.bottomRight);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: C.primary, brightness: Brightness.light),
  );
  OutlineInputBorder b(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withOpacity(.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: b(Colors.white.withOpacity(.8)),
      enabledBorder: b(Colors.white.withOpacity(.8)),
      focusedBorder: b(C.primary, 1.6),
      errorBorder: b(C.danger),
      focusedErrorBorder: b(C.danger, 1.6),
      hintStyle: const TextStyle(color: C.muted, fontSize: 14),
    ),
  );
}

class AppBg extends StatelessWidget {
  final Widget child;
  const AppBg({super.key, required this.child});

  Widget _blob(double s, Color c) => ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: c)),
      );

  @override
  Widget build(BuildContext context) => Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFD9F3E5), Color(0xFFF3FBF7), Color(0xFFE6F6EE)]),
          ),
        ),
        Positioned(top: -80, right: -60, child: _blob(260, C.primary.withOpacity(.28))),
        Positioned(top: 320, left: -110, child: _blob(260, const Color(0xFF9BE3BE).withOpacity(.4))),
        Positioned(bottom: -70, right: -50, child: _blob(230, const Color(0xFFB6EBD0).withOpacity(.5))),
        child,
      ]);
}

class Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius, opacity;
  final VoidCallback? onTap;
  final Gradient? gradient;
  const Glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.opacity = .55,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final box = ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null ? Colors.white.withOpacity(opacity) : null,
            borderRadius: r,
            border: Border.all(color: Colors.white.withOpacity(.75), width: 1.2),
          ),
          child: child,
        ),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(borderRadius: r, boxShadow: [
          BoxShadow(color: C.primaryDark.withOpacity(.09), blurRadius: 24, offset: const Offset(0, 10)),
        ]),
        child: box,
      ),
    );
  }
}

class GButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading, filled;
  const GButton({super.key, required this.label, this.icon, this.onTap, this.loading = false, this.filled = true});

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : C.primaryDark;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: filled ? C.gradient : null,
          color: filled ? null : Colors.white.withOpacity(.7),
          borderRadius: BorderRadius.circular(18),
          border: filled ? null : Border.all(color: C.primary.withOpacity(.4)),
          boxShadow: filled
              ? [BoxShadow(color: C.primary.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8))]
              : null,
        ),
        child: loading
            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: fg))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
                Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
      ),
    );
  }
}

void toast(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(m),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? C.danger : C.primaryDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
}

const iconMap = <String, IconData>{
  'restaurant': Icons.restaurant_rounded,
  'shopping_cart': Icons.shopping_cart_rounded,
  'directions_car': Icons.directions_car_rounded,
  'receipt_long': Icons.receipt_long_rounded,
  'movie': Icons.movie_rounded,
  'favorite': Icons.favorite_rounded,
  'school': Icons.school_rounded,
  'more_horiz': Icons.more_horiz_rounded,
  'payments': Icons.payments_rounded,
  'card_giftcard': Icons.card_giftcard_rounded,
  'pets': Icons.pets_rounded,
  'home': Icons.home_rounded,
  'flight': Icons.flight_rounded,
  'sports_esports': Icons.sports_esports_rounded,
  'savings': Icons.savings_rounded,
  'work': Icons.work_rounded,
};

class IconBox extends StatelessWidget {
  final String? icon;
  final Color color;
  final double size;
  const IconBox({super.key, this.icon, required this.color, this.size = 46});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(size * .32)),
        child: Icon(iconMap[icon] ?? Icons.more_horiz_rounded, color: color, size: size * .5),
      );
}

class TxTile extends StatelessWidget {
  final Tx tx;
  final VoidCallback? onTap;
  const TxTile({super.key, required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = tx.catColor ?? C.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          IconBox(icon: tx.catIcon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.merchant, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              const SizedBox(height: 3),
              Row(children: [
                Flexible(
                  child: Text('${tx.catName ?? 'Tanpa kategori'} · ${dayLabel(tx.date)}, ${timeStr(tx.date)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: C.muted, fontSize: 11.5)),
                ),
                if (tx.source == 'ocr') ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.document_scanner_rounded, size: 13, color: C.primary),
                ],
              ]),
            ]),
          ),
          Text(
            tx.isExpense ? '-${rp(tx.amount)}' : '+${rp(tx.amount)}',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: tx.isExpense ? C.ink : C.primaryDark),
          ),
        ]),
      ),
    );
  }
}

class Header extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const Header(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
          if (trailing != null) trailing!,
        ]),
      );
}

String? receiptUrl(String? p) => p == null ? null : '${Api.base}/$p';
