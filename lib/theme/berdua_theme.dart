import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// ThemeData Berdua v4 — "versi fun".
///
/// Tema terang di atas krem. Teks pada tombol pink berwarna tinta, bukan
/// putih: itu yang digambar prototipe, dan kontrasnya jauh lebih baik.
abstract final class BerduaTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light(
      primary: BerduaColors.rose,
      onPrimary: BerduaColors.ink,
      secondary: BerduaColors.mint,
      onSecondary: BerduaColors.ink,
      surface: BerduaColors.background,
      onSurface: BerduaColors.text,
      surfaceContainerLow: BerduaColors.card,
      surfaceContainer: BerduaColors.card2,
      outline: BerduaColors.ink,
      error: BerduaColors.roseText,
    );

    final text = _textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: BerduaColors.background,
      textTheme: text,
      iconTheme: const IconThemeData(
        color: BerduaColors.text,
        size: Sizes.icon,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BerduaColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(color: BerduaColors.text),
      ),
      cardTheme: CardThemeData(
        color: BerduaColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.card),
          side: const BorderSide(color: BerduaColors.ink, width: Sizes.garis),
        ),
      ),
      // Tombol pink datar (tanpa garis): "TANDAI LUNAS", "SETOR", "Ubah".
      // Tombol utama bergaris dan berbayangan keras ada di `TombolUtama`.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: BerduaColors.rose,
              foregroundColor: BerduaColors.ink,
              disabledBackgroundColor: BerduaColors.netral,
              disabledForegroundColor: BerduaColors.textSecondary,
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              textStyle: text.labelLarge?.copyWith(
                fontSize: 17,
                letterSpacing: .5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.input),
              ),
            ).copyWith(
              overlayColor: const WidgetStatePropertyAll(
                BerduaColors.roseHover,
              ),
            ),
      ),
      // Tombol sekunder putih bergaris tinta, radius 18.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BerduaColors.text,
          backgroundColor: BerduaColors.card,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: BerduaColors.ink, width: Sizes.garis),
          textStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.input),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BerduaColors.roseText,
          textStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      // Input putih bergaris tinta 2 dp, radius 18.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BerduaColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: Gap.lg,
        ),
        hintStyle: text.bodyLarge?.copyWith(color: BerduaColors.textSecondary),
        border: _inputBorder(BerduaColors.ink),
        enabledBorder: _inputBorder(BerduaColors.ink),
        focusedBorder: _inputBorder(BerduaColors.rose),
        errorBorder: _inputBorder(BerduaColors.roseText),
        focusedErrorBorder: _inputBorder(BerduaColors.roseText),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BerduaColors.card2,
        selectedColor: BerduaColors.roseChipActive,
        labelStyle: text.bodySmall,
        secondaryLabelStyle: text.bodySmall?.copyWith(
          color: BerduaColors.roseChipText,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.pilihan),
        ),
      ),
      // FAB pink 60x60 radius 20, ikon tinta.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: BerduaColors.rose,
        foregroundColor: BerduaColors.ink,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        sizeConstraints: const BoxConstraints.tightFor(
          width: Sizes.fab,
          height: Sizes.fab,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
      ),
      // Bottom sheet putih, sudut atas 32, latar redup tinta 32%.
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(Radii.sheet),
          ),
        ),
        modalBarrierColor: Color(0x522B2733),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BerduaColors.rose
              : BerduaColors.netral,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: BerduaColors.rose,
        inactiveTrackColor: BerduaColors.netral,
        thumbColor: BerduaColors.rose,
        overlayColor: Color(0x33FF4F8B),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? BerduaColors.rose
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: const BorderSide(color: BerduaColors.garisCentang, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BerduaColors.rose,
        linearTrackColor: BerduaColors.line,
        linearMinHeight: Sizes.progressBar,
      ),
      dividerTheme: const DividerThemeData(
        color: BerduaColors.line,
        thickness: 1,
        space: 1,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.input),
    borderSide: BorderSide(color: color, width: Sizes.garis),
  );

  /// Tipografi: satu keluarga huruf, Poppins, berat 400/500/600/700.
  static TextTheme _textTheme() {
    final base = GoogleFonts.poppinsTextTheme();

    return base.copyWith(
      // Display 36/600 — "Satu catatan untuk berdua".
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: BerduaColors.text,
        height: 1.1,
      ),
      // Angka 34/600 — "Rp 51.000".
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: BerduaColors.text,
        height: 1.1,
      ),
      // H1 28/600 — "Hai, Dinda".
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: BerduaColors.text,
        height: 1.15,
      ),
      // Judul layar 22/500 — "Uang bersama".
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: BerduaColors.text,
      ),
      // Judul kartu 17-18/600 — "Kategori", "Setor".
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: BerduaColors.text,
        letterSpacing: 0,
      ),
      // Isi 16-17/400-500.
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: BerduaColors.text,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: BerduaColors.text,
        letterSpacing: 0,
      ),
      // Label 14/400 — "Nomor telepon", "Belanja".
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: BerduaColors.label,
        letterSpacing: 0,
      ),
      // Keterangan 13/400 — "Dinda · 50/50".
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: BerduaColors.textSecondary,
        letterSpacing: 0,
      ),
      // Tombol 20/700 kapital — "SIMPAN".
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: BerduaColors.ink,
      ),
    );
  }
}
