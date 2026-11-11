import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() {
  // Nama hari dan bulan berbahasa Indonesia dipakai di seluruh aplikasi (§7),
  // jadi datanya dimuat sebelum widget pertama dibangun.
  initializeDateFormatting('id_ID');

  runApp(const ProviderScope(child: BerduaApp()));
}
