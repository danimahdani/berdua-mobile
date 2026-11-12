import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Alamat backend Laravel yang berjalan di dalam WSL.
///
/// Backend hidup di filesystem ext4 WSL dan harus listen di `0.0.0.0`:
/// `php artisan serve --host=0.0.0.0 --port=8000`. Kalau dia bind ke
/// `127.0.0.1`, hanya bisa diakses dari dalam WSL dan aplikasi ini gagal
/// menyambung.
///
/// Alamat yang benar berbeda per target:
///
/// | Target                | Alamat               |
/// |-----------------------|----------------------|
/// | Chrome / Windows      | `localhost:8000`     |
/// | Emulator Android      | `10.0.2.2:8000`      |
/// | HP fisik lewat USB    | `localhost:8000` + `adb reverse tcp:8000 tcp:8000` |
/// | HP fisik lewat Wi-Fi  | IP LAN Windows (WSL mode NAT perlu portproxy) |
///
/// Timpa kapan saja dengan:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8000`
abstract final class Env {
  static const _override = String.fromEnvironment('API_BASE_URL');

  /// Backend produksi. Build release selalu ke sini kecuali ditimpa, supaya
  /// APK tidak pernah diam-diam menunjuk alamat pengembangan.
  static const _produksi = 'https://berdua.danimahdani.dev';

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return '$_override/api';

    if (kReleaseMode) return '$_produksi/api';

    // Web dan desktop Windows menembus ke WSL lewat localhost forwarding.
    if (kIsWeb) return 'http://localhost:8000/api';

    // 10.0.2.2 pada emulator Android menunjuk loopback host Windows,
    // yang lalu diteruskan ke WSL.
    if (Platform.isAndroid) return 'http://10.0.2.2:8000/api';

    return 'http://localhost:8000/api';
  }

  /// §7: aplikasi berbahasa Indonesia dengan Rupiah.
  static const locale = 'id_ID';
}
