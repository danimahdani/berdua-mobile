import 'package:intl/intl.dart';

/// Format Rupiah dengan pemisah titik (§7 dokumen proyek): "Rp 512.000".
///
/// Semua nominal di aplikasi ini adalah integer Rupiah utuh — tidak ada sen,
/// sama seperti kolom `bigInteger` di backend.
abstract final class Rupiah {
  static final _plain = NumberFormat.decimalPattern('id_ID');

  /// "Rp 512.000"
  static String format(int amount) => 'Rp ${_plain.format(amount)}';

  /// "512.000" — tanpa awalan, untuk input dan label sumbu grafik.
  static String bare(int amount) => _plain.format(amount);

  /// Bentuk pendek untuk grafik dan kartu sempit: "512rb", "1,2jt".
  static String short(int amount) {
    final abs = amount.abs();

    if (abs >= 1000000000) {
      return _trim(amount / 1000000000, 'm');
    }
    if (abs >= 1000000) {
      return _trim(amount / 1000000, 'jt');
    }
    if (abs >= 1000) {
      return _trim(amount / 1000, 'rb');
    }

    return amount.toString();
  }

  static String _trim(double value, String unit) {
    final text = value
        .toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)
        .replaceAll('.', ',');

    return '$text$unit';
  }

  /// Desimal dengan koma, sesuai penulisan Indonesia: 28,8 — bukan 28.8.
  static String decimal(num value, {int digits = 1}) =>
      NumberFormat('#,##0.${'#' * digits}', 'id_ID').format(value);

  /// Membaca angka yang diketik pengguna: "512.000" dan "512000" sama saja.
  static int? parse(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');

    return digits.isEmpty ? null : int.tryParse(digits);
  }
}

/// Tanggal berbahasa Indonesia, untuk kartu dan blok tanggal (§16).
abstract final class TanggalId {
  static final _full = DateFormat('EEEE, d MMMM', 'id_ID');
  static final _short = DateFormat('d MMM', 'id_ID');
  static final _monthName = DateFormat('MMMM', 'id_ID');
  static final _monthShort = DateFormat('MMM', 'id_ID');
  static final _long = DateFormat('d MMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final _monthYearShort = DateFormat('MMM yyyy', 'id_ID');

  /// "14 Des 2023"
  static String long(DateTime date) => _long.format(date);

  /// "November 2026"
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// "Mar 2027" — tenggat target tabungan.
  static String monthYearShort(DateTime date) => _monthYearShort.format(date);

  /// "Senin, 9 November"
  static String full(DateTime date) => _full.format(date);

  /// "9 Nov"
  static String short(DateTime date) => _short.format(date);

  /// "November"
  static String month(DateTime date) => _monthName.format(date);

  /// "NOV" — blok tanggal pada kartu jadwal (§16).
  static String monthBadge(DateTime date) =>
      _monthShort.format(date).toUpperCase();

  /// "7 hari lagi", "besok", "hari ini".
  static String relative(DateTime date, {DateTime? from}) {
    final today = DateUtils.dayOnly(from ?? DateTime.now());
    final target = DateUtils.dayOnly(date);
    final days = target.difference(today).inDays;

    if (days == 0) return 'hari ini';
    if (days == 1) return 'besok';
    if (days == -1) return 'kemarin';

    return days > 0 ? '$days hari lagi' : '${-days} hari lalu';
  }
}

/// Pembulatan tanggal ke hari, supaya selisih hari tidak terpengaruh jam.
abstract final class DateUtils {
  static DateTime dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
