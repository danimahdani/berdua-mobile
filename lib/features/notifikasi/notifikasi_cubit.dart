import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../beranda/beranda_cubit.dart';

/// Satu baris notifikasi (§5.5).
class Notifikasi {
  const Notifikasi({
    required this.id,
    required this.type,
    required this.text,
    required this.read,
    required this.createdAt,
  });

  factory Notifikasi.fromJson(Map<String, dynamic> json) => Notifikasi(
    id: json['id'] as int,
    type: json['type'] as String,
    text: json['text'] as String,
    read: json['read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final int id;
  final String type;
  final String text;
  final bool read;
  final DateTime createdAt;

  /// Ikon per pemicu di §5.5.
  IconData get ikon => switch (type) {
    'transaction_new' => Icons.receipt_long_outlined,
    'transaction_changed' => Icons.edit_outlined,
    'settlement' => Icons.check_circle_outline,
    'period_forecast' => Icons.favorite_outline,
    'todo_due' => Icons.task_alt_outlined,
    'event_reminder' => Icons.event_outlined,
    'shopping_new' => Icons.shopping_basket_outlined,
    'saving_milestone' => Icons.savings_outlined,
    _ => Icons.notifications_none,
  };
}

/// Layar 07.
class NotifikasiCubit extends MuatanCubit<List<Notifikasi>> {
  NotifikasiCubit(this._dio, this._beranda);

  final Dio _dio;
  final BerandaCubit _beranda;

  @override
  Future<List<Notifikasi>> ambil() async {
    final data = await _dio.send('GET', '/notifications');

    return (data['data'] as List<dynamic>)
        .map((e) => Notifikasi.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tandaiSemuaDibaca() async {
    await _dio.send('POST', '/notifications/read-all');
    await segarkan();

    // Lonceng di layar 06 ikut diperbarui.
    await _beranda.segarkan();
  }
}
