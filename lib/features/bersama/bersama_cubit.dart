import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../core/muatan.dart';
import '../beranda/beranda_cubit.dart';

/// Model dan cubit untuk layar 16-22 (§5.4).

/// Bagian-bagian layar "Bersama" (§5.4).
enum BagianBersama {
  belanja('Belanja'),
  todo('To-do'),
  tabungan('Tabungan'),
  jadwal('Jadwal'),
  jurnal('Jurnal');

  const BagianBersama(this.label);

  final String label;
}

/// Bagian yang sedang dibuka. Beranda dan notifikasi memilihnya sebelum
/// pindah ke tab Bersama.
class BagianBersamaCubit extends Cubit<BagianBersama> {
  BagianBersamaCubit() : super(BagianBersama.belanja);

  void pilih(BagianBersama bagian) => emit(bagian);
}

// --------------------------------------------------------------- layar 16

class BarangBelanja {
  const BarangBelanja({
    required this.id,
    required this.title,
    required this.addedByName,
    required this.done,
  });

  factory BarangBelanja.fromJson(Map<String, dynamic> json) => BarangBelanja(
    id: json['id'] as int,
    title: json['title'] as String,
    addedByName: json['added_by_name'] as String? ?? '',
    done: json['done'] as bool? ?? false,
  );

  final int id;
  final String title;
  final String addedByName;
  final bool done;
}

class BelanjaCubit extends MuatanCubit<List<BarangBelanja>> {
  BelanjaCubit(this._dio, this._beranda);

  final Dio _dio;
  final BerandaCubit _beranda;

  @override
  Future<List<BarangBelanja>> ambil() async {
    final data = await _dio.send('GET', '/shopping');

    return (data['data'] as List<dynamic>)
        .map((e) => BarangBelanja.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah(String judul) async {
    await _dio.send('POST', '/shopping', body: {'title': judul});
    await _segarkan();
  }

  Future<void> centang(int id) async {
    await _dio.send('PATCH', '/shopping/$id/toggle');
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/shopping/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    await segarkan();
    _beranda.segarkan();
  }
}

// --------------------------------------------------------------- layar 17

class Tugas {
  const Tugas({
    required this.id,
    required this.title,
    required this.assigneeId,
    required this.assigneeName,
    required this.dueDate,
    required this.done,
  });

  factory Tugas.fromJson(Map<String, dynamic> json) => Tugas(
    id: json['id'] as int,
    title: json['title'] as String,
    assigneeId: json['assignee_id'] as int?,
    assigneeName: json['assignee_name'] as String?,
    dueDate: json['due_date'] == null
        ? null
        : DateTime.parse(json['due_date'] as String),
    done: json['done'] as bool? ?? false,
  );

  final int id;
  final String title;

  /// null = tugas Berdua.
  final int? assigneeId;
  final String? assigneeName;
  final DateTime? dueDate;
  final bool done;

  String get penanggungJawab => assigneeName ?? 'Berdua';
}

class TodoCubit extends MuatanCubit<List<Tugas>> {
  TodoCubit(this._dio, this._beranda);

  final Dio _dio;
  final BerandaCubit _beranda;

  @override
  Future<List<Tugas>> ambil() async {
    final data = await _dio.send('GET', '/todos');

    return (data['data'] as List<dynamic>)
        .map((e) => Tugas.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah({
    required String judul,
    int? assigneeId,
    DateTime? tenggat,
  }) async {
    await _dio.send(
      'POST',
      '/todos',
      body: {
        'title': judul,
        'assignee_id': assigneeId,
        if (tenggat != null) 'due_date': _tanggal(tenggat),
      },
    );

    await _segarkan();
  }

  Future<void> centang(int id) async {
    await _dio.send('PATCH', '/todos/$id/toggle');
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/todos/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    await segarkan();
    _beranda.segarkan();
  }
}

// ------------------------------------------------------------ layar 18-19

class TargetTabungan {
  const TargetTabungan({
    required this.id,
    required this.title,
    required this.target,
    required this.collected,
    required this.remaining,
    required this.perMonth,
    required this.percent,
    required this.dueDate,
    this.kontribusi = const [],
    this.riwayat = const [],
  });

  factory TargetTabungan.fromJson(Map<String, dynamic> json) => TargetTabungan(
    id: json['id'] as int,
    title: json['title'] as String,
    target: json['target'] as int,
    collected: json['collected'] as int? ?? 0,
    remaining: json['remaining'] as int? ?? 0,
    perMonth: json['per_month'] as int?,
    percent: json['percent'] as int? ?? 0,
    dueDate: json['due_date'] == null
        ? null
        : DateTime.parse(json['due_date'] as String),
    kontribusi: (json['kontribusi'] as List<dynamic>? ?? [])
        .map((e) => Kontribusi.fromJson(e as Map<String, dynamic>))
        .toList(),
    riwayat: (json['riwayat'] as List<dynamic>? ?? [])
        .map((e) => Setoran.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final int id;
  final String title;
  final int target;
  final int collected;
  final int remaining;
  final int? perMonth;
  final int percent;
  final DateTime? dueDate;
  final List<Kontribusi> kontribusi;
  final List<Setoran> riwayat;

  double get progres => (percent / 100).clamp(0.0, 1.0);
}

class Kontribusi {
  const Kontribusi({
    required this.userId,
    required this.name,
    required this.amount,
  });

  factory Kontribusi.fromJson(Map<String, dynamic> json) => Kontribusi(
    userId: json['user_id'] as int,
    name: json['name'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
  );

  final int userId;
  final String name;
  final int amount;
}

class Setoran {
  const Setoran({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
  });

  factory Setoran.fromJson(Map<String, dynamic> json) => Setoran(
    id: json['id'] as int,
    name: json['name'] as String? ?? '',
    amount: json['amount'] as int? ?? 0,
    date: DateTime.parse(json['date'] as String),
  );

  final int id;
  final String name;
  final int amount;
  final DateTime date;
}

class TabunganCubit extends MuatanCubit<List<TargetTabungan>> {
  TabunganCubit(this._dio, this._beranda);

  final Dio _dio;
  final BerandaCubit _beranda;

  @override
  Future<List<TargetTabungan>> ambil() async {
    final data = await _dio.send('GET', '/goals');

    return (data['data'] as List<dynamic>)
        .map((e) => TargetTabungan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah({
    required String judul,
    required int target,
    DateTime? tenggat,
  }) async {
    await _dio.send(
      'POST',
      '/goals',
      body: {
        'title': judul,
        'target': target,
        if (tenggat != null) 'due_date': _tanggal(tenggat),
      },
    );

    await _segarkan();
  }

  Future<void> setor({required int goalId, required int jumlah}) async {
    await _dio.send(
      'POST',
      '/goals/$goalId/deposits',
      body: {'amount': jumlah},
    );

    // Layar 19 menyegarkan [DetailTabunganCubit] miliknya sendiri.
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/goals/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    await segarkan();
    _beranda.segarkan();
  }
}

/// Layar 19, satu cubit per target; disediakan oleh layarnya sendiri.
class DetailTabunganCubit extends MuatanCubit<TargetTabungan> {
  DetailTabunganCubit(this._dio, this.id);

  final Dio _dio;
  final int id;

  @override
  Future<TargetTabungan> ambil() async {
    final data = await _dio.send('GET', '/goals/$id');

    return TargetTabungan.fromJson(data['data'] as Map<String, dynamic>);
  }
}

// ------------------------------------------------------------ layar 20-21

class Acara {
  const Acara({
    required this.id,
    required this.title,
    required this.type,
    required this.nextOccurrence,
    required this.daysUntil,
    required this.remindBefore,
    required this.yearly,
  });

  factory Acara.fromJson(Map<String, dynamic> json) => Acara(
    id: json['id'] as int,
    title: json['title'] as String,
    type: json['type'] as String,
    nextOccurrence: DateTime.parse(json['next_occurrence'] as String),
    daysUntil: json['days_until'] as int? ?? 0,
    remindBefore: json['remind_before'] as int? ?? 0,
    yearly: json['yearly'] as bool? ?? false,
  );

  final int id;
  final String title;
  final String type;
  final DateTime nextOccurrence;
  final int daysUntil;
  final int remindBefore;
  final bool yearly;

  String get labelPengingat => switch (remindBefore) {
    0 => 'Hari H',
    1 => '1 hari sebelum',
    3 => '3 hari sebelum',
    _ => '1 minggu sebelum',
  };
}

class JadwalCubit extends MuatanCubit<List<Acara>> {
  JadwalCubit(this._dio, this._beranda);

  final Dio _dio;
  final BerandaCubit _beranda;

  @override
  Future<List<Acara>> ambil() async {
    final data = await _dio.send('GET', '/events');

    return (data['data'] as List<dynamic>)
        .map((e) => Acara.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah({
    required String judul,
    required DateTime tanggal,
    required String jenis,
    required int ingatkan,
    required bool tahunan,
  }) async {
    await _dio.send(
      'POST',
      '/events',
      body: {
        'title': judul,
        'date': _tanggal(tanggal),
        'type': jenis,
        'remind_before': ingatkan,
        'yearly': tahunan,
      },
    );

    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/events/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    await segarkan();
    _beranda.segarkan();
  }
}

// --------------------------------------------------------------- layar 22

class CatatanJurnal {
  const CatatanJurnal({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.text,
    required this.date,
  });

  factory CatatanJurnal.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return CatatanJurnal(
      id: json['id'] as int,
      authorId: json['author_id'] as int,
      // Daftar memakai author_name; jawaban store menyertakan relasi author.
      authorName:
          json['author_name'] as String? ?? author?['name'] as String? ?? '',
      text: json['text'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  final int id;
  final int authorId;
  final String authorName;
  final String text;
  final DateTime date;
}

class JurnalCubit extends MuatanCubit<List<CatatanJurnal>> {
  JurnalCubit(this._dio);

  final Dio _dio;

  @override
  Future<List<CatatanJurnal>> ambil() async {
    final data = await _dio.send('GET', '/journal');

    return (data['data'] as List<dynamic>)
        .map((e) => CatatanJurnal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tulis(String teks) async {
    await _dio.send('POST', '/journal', body: {'text': teks});
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await _dio.send('DELETE', '/journal/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    await segarkan();
  }
}

/// Backend menerima tanggal sebagai YYYY-MM-DD.
String _tanggal(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
