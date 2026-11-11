import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../models/models.dart';

/// Keadaan sesi. Router membaca ini untuk memutuskan layar mana yang tampil:
/// masuk (01), onboarding (03-04), atau aplikasi utama.
class SesiState {
  const SesiState({
    this.user,
    this.couple,
    this.partner,
    this.balance = 0,
    this.memuat = true,
    this.pengaturan = const {},
  });

  final Pengguna? user;
  final Pasangan? couple;
  final Pengguna? partner;
  final int balance;

  /// Sakelar di layar Profil: `share_cycle`, `remind_period`, `remind_bills`.
  final Map<String, bool> pengaturan;

  bool nyala(String kunci) => pengaturan[kunci] ?? false;

  /// true selama token lama sedang diperiksa saat aplikasi dibuka.
  final bool memuat;

  bool get masuk => user != null;

  bool get perluOnboarding => user?.needsOnboarding ?? false;

  bool get terhubung => partner != null;

  SesiState copyWith({
    Pengguna? user,
    Pasangan? couple,
    Pengguna? partner,
    int? balance,
    bool? memuat,
    Map<String, bool>? pengaturan,
    bool kosongkan = false,
  }) {
    if (kosongkan) return const SesiState(memuat: false);

    return SesiState(
      user: user ?? this.user,
      couple: couple ?? this.couple,
      partner: partner ?? this.partner,
      balance: balance ?? this.balance,
      memuat: memuat ?? this.memuat,
      pengaturan: pengaturan ?? this.pengaturan,
    );
  }
}

/// Baris `settings` dari backend bisa kosong (belum pernah diubah) dan nilai
/// boolean-nya bisa datang sebagai 0/1.
Map<String, bool> _bacaPengaturan(Object? json) {
  if (json is! Map) return const {};

  return {
    for (final kunci in const ['share_cycle', 'remind_period', 'remind_bills'])
      kunci: json[kunci] == true || json[kunci] == 1,
  };
}

class SesiCubit extends Cubit<SesiState> {
  /// [pulihkanSaatMulai] dimatikan di tes yang sudah menyiapkan sesi sendiri.
  SesiCubit(
    this._dio,
    this._tokens, {
    SesiState awal = const SesiState(),
    bool pulihkanSaatMulai = true,
  }) : super(awal) {
    if (pulihkanSaatMulai) Future.microtask(pulihkan);
  }

  final Dio _dio;
  final TokenStore _tokens;

  /// Dipakai saat aplikasi dibuka: kalau masih ada token, langsung muat profil.
  Future<void> pulihkan() async {
    final token = await _tokens.read();

    if (token == null) {
      emit(const SesiState(memuat: false));

      return;
    }

    try {
      await muatProfil();
    } on ApiException catch (error) {
      // Token sudah tidak berlaku: bersihkan dan kembali ke layar masuk.
      if (error.isUnauthorized) {
        await _tokens.clear();
      }

      emit(const SesiState(memuat: false));
    }
  }

  Future<void> muatProfil() async {
    final data = await _dio.send('GET', '/me');

    emit(
      SesiState(
        user: Pengguna.fromJson(data['user'] as Map<String, dynamic>),
        couple: data['couple'] == null
            ? null
            : Pasangan.fromJson(data['couple'] as Map<String, dynamic>),
        partner: data['partner'] == null
            ? null
            : Pengguna.fromJson(data['partner'] as Map<String, dynamic>),
        balance: data['balance'] as int? ?? 0,
        memuat: false,
        pengaturan: _bacaPengaturan(data['settings']),
      ),
    );
  }

  /// Sakelar di layar Profil. Tampilan diubah lebih dulu supaya sakelar
  /// langsung bergeser; kalau server menolak, nilainya dikembalikan.
  Future<void> ubahPengaturan(String kunci, bool nilai) async {
    final sebelum = state.pengaturan;

    emit(state.copyWith(pengaturan: {...sebelum, kunci: nilai}));

    try {
      final data = await _dio.send(
        'PATCH',
        '/me/settings',
        body: {kunci: nilai},
      );

      emit(state.copyWith(pengaturan: _bacaPengaturan(data['settings'])));
    } on ApiException {
      emit(state.copyWith(pengaturan: sebelum));
      rethrow;
    }
  }

  /// Layar 01: minta kode verifikasi. Mengembalikan petunjuk email tersamar
  /// untuk ditampilkan di layar 02.
  Future<({String emailHint, String? devCode})> mintaKode(String phone) async {
    final data = await _dio.send(
      'POST',
      '/auth/request-code',
      body: {'phone_number': phone},
    );

    return (
      emailHint: data['email_hint'] as String? ?? '',
      devCode: data['dev_code'] as String?,
    );
  }

  /// Layar 02: tukar kode dengan token.
  Future<void> verifikasi(String phone, String code) async {
    final data = await _dio.send(
      'POST',
      '/auth/verify',
      body: {'phone_number': phone, 'code': code},
    );

    await _tokens.write(data['token'] as String);

    emit(
      SesiState(
        user: Pengguna.fromJson(data['user'] as Map<String, dynamic>),
        couple: data['couple'] == null
            ? null
            : Pasangan.fromJson(data['couple'] as Map<String, dynamic>),
        partner: data['partner'] == null
            ? null
            : Pengguna.fromJson(data['partner'] as Map<String, dynamic>),
        memuat: false,
      ),
    );
  }

  /// Onboarding langkah 2 (layar 04): nama panggilan dan pilihan siklus.
  Future<void> simpanProfil({
    required String nama,
    required bool catatSiklus,
  }) async {
    final data = await _dio.send(
      'PATCH',
      '/me',
      body: {'name': nama, 'tracks_cycle': catatSiklus},
    );

    emit(
      state.copyWith(
        user: Pengguna.fromJson(data['user'] as Map<String, dynamic>),
      ),
    );
  }

  Future<void> terbitkanUlangKode() async {
    final data = await _dio.send('POST', '/couple/invite/refresh');

    emit(
      state.copyWith(
        couple: Pasangan.fromJson(data['couple'] as Map<String, dynamic>),
      ),
    );
  }

  Future<void> keluar() async {
    try {
      await _dio.send('POST', '/auth/logout');
    } on ApiException {
      // Token mungkin sudah tidak berlaku di server; sesi lokal tetap dibersihkan.
    }

    await _tokens.clear();
    emit(const SesiState(memuat: false));
  }
}
