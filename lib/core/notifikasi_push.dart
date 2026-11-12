import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_client.dart';

/// Channel Android untuk semua pengingat. ID yang sama dipasang di
/// AndroidManifest sebagai channel bawaan FCM.
const _channel = AndroidNotificationChannel(
  'berdua_pengingat',
  'Pengingat',
  description: 'Pengingat kuis dan kabar dari pasangan.',
  importance: Importance.high,
);

/// Notifikasi yang datang saat aplikasi sedang terbuka. Android tidak
/// menampilkannya di baki notifikasi, jadi aplikasi yang menampilkannya.
class PesanPush {
  const PesanPush({required this.judul, required this.isi, this.rute});

  final String judul;
  final String isi;

  /// Layar yang dituju kalau pesannya diketuk, mis. `/kuis`.
  final String? rute;
}

/// Notifikasi push lewat Firebase Cloud Messaging.
///
/// Tugasnya tiga: mendaftarkan perangkat ini ke backend supaya bisa dikirimi
/// pengingat, meneruskan pesan yang datang saat aplikasi terbuka, dan memberi
/// tahu rute yang dituju saat sebuah notifikasi diketuk.
///
/// Semua kegagalan Firebase ditelan: tanpa Google Play, tanpa izin, atau tanpa
/// jaringan, aplikasi tetap berjalan — hanya tanpa pengingat.
class NotifikasiPush {
  NotifikasiPush(this._dio);

  final Dio _dio;

  final _pesan = StreamController<PesanPush>.broadcast();
  final _rute = StreamController<String>.broadcast();
  final _langganan = <StreamSubscription<dynamic>>[];
  final _lokal = FlutterLocalNotificationsPlugin();

  bool _berjalan = false;
  int _nomor = 0;
  String? _token;

  /// Pesan yang datang selagi aplikasi terbuka.
  Stream<PesanPush> get pesan => _pesan.stream;

  /// Rute dari notifikasi yang diketuk.
  Stream<String> get rute => _rute.stream;

  /// Dipanggil sesudah pengguna masuk. Aman dipanggil berulang.
  Future<void> mulai() async {
    if (_berjalan) return;

    _berjalan = true;

    try {
      await Firebase.initializeApp();

      final fcm = FirebaseMessaging.instance;

      // Android 13 ke atas menampilkan dialog izin; versi lama langsung lolos.
      await fcm.requestPermission();

      await _siapkanLokal();

      // Sengaja masih memakai token FCM klasik: backend mengirim lewat
      // `message.token` di FCM HTTP v1. API pengganti (register/onRegistered)
      // memberi Firebase Installation ID, yang butuh cara kirim berbeda.
      // ignore: deprecated_member_use
      await _daftarkan(await fcm.getToken());

      _langganan
        // ignore: deprecated_member_use
        ..add(fcm.onTokenRefresh.listen(_daftarkan))
        ..add(
          FirebaseMessaging.onMessage.listen((pesan) {
            final notifikasi = pesan.notification;

            if (notifikasi == null) return;

            final rute = pesan.data['route'] as String?;

            _tampilkan(notifikasi.title, notifikasi.body, rute);

            _pesan.add(
              PesanPush(
                judul: notifikasi.title ?? '',
                isi: notifikasi.body ?? '',
                rute: rute,
              ),
            );
          }),
        )
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_saatDiketuk));

      // Aplikasi dibuka dari keadaan mati lewat ketukan notifikasi.
      final awal = await fcm.getInitialMessage();

      if (awal != null) _saatDiketuk(awal);
    } catch (error) {
      _berjalan = false;
      debugPrint('Notifikasi push tidak aktif: $error');
    }
  }

  /// Membuat channel dan menyiapkan notifikasi lokal. FCM tidak menampilkan
  /// apa pun di baki selagi aplikasi terbuka, jadi kita yang memunculkannya.
  Future<void> _siapkanLokal() async {
    await _lokal.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (respons) {
        final rute = respons.payload;

        if (rute != null && rute.isNotEmpty) _rute.add(rute);
      },
    );

    await _lokal
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _tampilkan(String? judul, String? isi, String? rute) async {
    if ((judul ?? '').isEmpty && (isi ?? '').isEmpty) return;

    try {
      await _lokal.show(
        id: _nomor++,
        title: judul,
        body: isi,
        payload: rute,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    } catch (error) {
      debugPrint('Notifikasi tidak bisa ditampilkan: $error');
    }
  }

  void _saatDiketuk(RemoteMessage pesan) {
    final rute = pesan.data['route'];

    if (rute is String && rute.isNotEmpty) _rute.add(rute);
  }

  Future<void> _daftarkan(String? token) async {
    if (token == null || token.isEmpty) return;

    _token = token;

    try {
      await _dio.send(
        'PUT',
        '/devices',
        body: {'token': token, 'platform': 'android'},
      );
    } on ApiException catch (error) {
      debugPrint('Perangkat belum terdaftar untuk push: ${error.message}');
    }
  }

  /// Dipanggil SEBELUM keluar, selagi token masuk masih berlaku, supaya
  /// perangkat ini berhenti menerima notifikasi akun tersebut.
  Future<void> lepas() async {
    for (final langganan in _langganan) {
      await langganan.cancel();
    }

    _langganan.clear();
    _berjalan = false;

    final token = _token;

    _token = null;

    if (token == null) return;

    try {
      await _dio.send('DELETE', '/devices', body: {'token': token});
    } on ApiException {
      // Backend tidak terjangkau: token akan berpindah saat akun berikutnya
      // masuk di perangkat ini.
    }
  }
}
