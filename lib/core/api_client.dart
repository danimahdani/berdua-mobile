import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'env.dart';

/// Pesan galat yang sudah siap ditampilkan ke pengguna.
///
/// Backend mengirim `message` untuk galat umum dan `errors` untuk galat
/// validasi; keduanya diringkas jadi satu kalimat berbahasa Indonesia.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;

  /// 409 dipakai backend untuk "belum terhubung ke pasangan".
  bool get needsPairing => statusCode == 409;

  @override
  String toString() => message;
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Token Sanctum disimpan terenkripsi, bukan di SharedPreferences.
class TokenStore {
  TokenStore(this._storage);

  static const _key = 'berdua_token';

  final FlutterSecureStorage _storage;
  String? _cached;

  String? get cached => _cached;

  Future<String?> read() async => _cached ??= await _storage.read(key: _key);

  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}

final tokenStoreProvider = Provider<TokenStore>(
  (ref) => TokenStore(ref.watch(secureStorageProvider)),
);

final dioProvider = Provider<Dio>((ref) {
  final tokens = ref.watch(tokenStoreProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
      // Status dibiarkan lewat supaya interceptor yang memetakan galat,
      // bukan Dio yang melempar DioException mentah.
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokens.read();

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;

        if (status >= 400) {
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              error: _mapError(response),
              type: DioExceptionType.badResponse,
            ),
            true,
          );

          return;
        }

        handler.next(response);
      },
      onError: (error, handler) {
        if (error.error is ApiException) {
          handler.next(error);

          return;
        }

        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            error: ApiException(_networkMessage(error)),
            type: error.type,
          ),
          true,
        );
      },
    ),
  );

  return dio;
});

ApiException _mapError(Response<dynamic> response) {
  final data = response.data;
  final status = response.statusCode;

  if (data is! Map) {
    return ApiException('Terjadi kesalahan di server.', statusCode: status);
  }

  final fieldErrors = <String, String>{};
  final errors = data['errors'];

  if (errors is Map) {
    errors.forEach((key, value) {
      final first = value is List && value.isNotEmpty ? value.first : value;
      fieldErrors['$key'] = '$first';
    });
  }

  final message = data['message'] as String? ??
      (fieldErrors.isNotEmpty
          ? fieldErrors.values.first
          : 'Terjadi kesalahan.');

  return ApiException(
    message,
    statusCode: status,
    fieldErrors: fieldErrors,
  );
}

String _networkMessage(DioException error) {
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout =>
      'Sambungan timeout. Periksa apakah backend sudah jalan.',
    DioExceptionType.connectionError =>
      // Penyebab paling sering di susunan WSL ini: backend bind ke 127.0.0.1,
      // bukan 0.0.0.0, atau alamatnya salah untuk target yang dipakai.
      'Tidak bisa menyambung ke ${Env.apiBaseUrl}. '
          'Pastikan backend jalan dengan --host=0.0.0.0.',
    _ => 'Terjadi kesalahan jaringan.',
  };
}

/// Pembungkus tipis supaya pemanggil cukup menangkap [ApiException].
extension ApiCall on Dio {
  Future<Map<String, dynamic>> send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );

      final data = response.data;

      return data is Map<String, dynamic> ? data : <String, dynamic>{};
    } on DioException catch (error) {
      final mapped = error.error;

      throw mapped is ApiException
          ? mapped
          : ApiException('Terjadi kesalahan jaringan.');
    }
  }
}
