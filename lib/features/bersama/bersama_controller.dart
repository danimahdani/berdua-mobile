import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../beranda/beranda_controller.dart';

/// Model dan controller untuk layar 16-22 (§5.4).

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

class BelanjaController extends AsyncNotifier<List<BarangBelanja>> {
  @override
  Future<List<BarangBelanja>> build() async {
    final data = await ref.read(dioProvider).send('GET', '/shopping');

    return (data['data'] as List<dynamic>)
        .map((e) => BarangBelanja.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah(String judul) async {
    await ref.read(dioProvider).send('POST', '/shopping', body: {'title': judul});
    await _segarkan();
  }

  Future<void> centang(int id) async {
    await ref.read(dioProvider).send('PATCH', '/shopping/$id/toggle');
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await ref.read(dioProvider).send('DELETE', '/shopping/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);
    ref.invalidate(berandaProvider);
  }
}

final belanjaProvider =
    AsyncNotifierProvider<BelanjaController, List<BarangBelanja>>(
  BelanjaController.new,
);

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

class TodoController extends AsyncNotifier<List<Tugas>> {
  @override
  Future<List<Tugas>> build() async {
    final data = await ref.read(dioProvider).send('GET', '/todos');

    return (data['data'] as List<dynamic>)
        .map((e) => Tugas.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah({
    required String judul,
    int? assigneeId,
    DateTime? tenggat,
  }) async {
    await ref.read(dioProvider).send(
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
    await ref.read(dioProvider).send('PATCH', '/todos/$id/toggle');
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await ref.read(dioProvider).send('DELETE', '/todos/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);
    ref.invalidate(berandaProvider);
  }
}

final todoProvider = AsyncNotifierProvider<TodoController, List<Tugas>>(
  TodoController.new,
);

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

class TabunganController extends AsyncNotifier<List<TargetTabungan>> {
  @override
  Future<List<TargetTabungan>> build() async {
    final data = await ref.read(dioProvider).send('GET', '/goals');

    return (data['data'] as List<dynamic>)
        .map((e) => TargetTabungan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tambah({
    required String judul,
    required int target,
    DateTime? tenggat,
  }) async {
    await ref.read(dioProvider).send(
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
    await ref
        .read(dioProvider)
        .send('POST', '/goals/$goalId/deposits', body: {'amount': jumlah});

    await _segarkan();
    ref.invalidate(detailTabunganProvider(goalId));
  }

  Future<void> hapus(int id) async {
    await ref.read(dioProvider).send('DELETE', '/goals/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);
    ref.invalidate(berandaProvider);
  }
}

final tabunganProvider =
    AsyncNotifierProvider<TabunganController, List<TargetTabungan>>(
  TabunganController.new,
);

/// Layar 19, per target.
final detailTabunganProvider =
    FutureProvider.family<TargetTabungan, int>((ref, id) async {
  final data = await ref.read(dioProvider).send('GET', '/goals/$id');

  return TargetTabungan.fromJson(data['data'] as Map<String, dynamic>);
});

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

class JadwalController extends AsyncNotifier<List<Acara>> {
  @override
  Future<List<Acara>> build() async {
    final data = await ref.read(dioProvider).send('GET', '/events');

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
    await ref.read(dioProvider).send(
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
    await ref.read(dioProvider).send('DELETE', '/events/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);
    ref.invalidate(berandaProvider);
  }
}

final jadwalProvider = AsyncNotifierProvider<JadwalController, List<Acara>>(
  JadwalController.new,
);

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
      authorName: json['author_name'] as String? ??
          author?['name'] as String? ??
          '',
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

class JurnalController extends AsyncNotifier<List<CatatanJurnal>> {
  @override
  Future<List<CatatanJurnal>> build() async {
    final data = await ref.read(dioProvider).send('GET', '/journal');

    return (data['data'] as List<dynamic>)
        .map((e) => CatatanJurnal.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> tulis(String teks) async {
    await ref.read(dioProvider).send('POST', '/journal', body: {'text': teks});
    await _segarkan();
  }

  Future<void> hapus(int id) async {
    await ref.read(dioProvider).send('DELETE', '/journal/$id');
    await _segarkan();
  }

  Future<void> _segarkan() async {
    // Sengaja TIDAK menyetel AsyncValue.loading() di sini: isi lama
    // bertahan di layar selama permintaan berjalan, sehingga penambahan
    // kecil tidak membuat seluruh daftar berkedip jadi kerangka.
    // Kerangka hanya untuk pemuatan pertama; tombol yang menekan aksi
    // sudah menampilkan indikatornya sendiri.
    state = await AsyncValue.guard(build);
  }
}

final jurnalProvider =
    AsyncNotifierProvider<JurnalController, List<CatatanJurnal>>(
  JurnalController.new,
);

/// Backend menerima tanggal sebagai YYYY-MM-DD.
String _tanggal(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
