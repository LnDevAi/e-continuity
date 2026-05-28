import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _baseUrl = 'http://api.econtinuity.edefence.tech/api/v1';
const _storage = FlutterSecureStorage();

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(_AuthInterceptor(_dio));
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => print('[API] $obj'),
    ));
  }

  Dio get dio => _dio;

  // Auth
  Future<Response> register(Map<String, dynamic> data) =>
      _dio.post('/auth/register', data: data);

  Future<Response> login(Map<String, dynamic> data) =>
      _dio.post('/auth/login', data: data);

  Future<Response> getProfile() => _dio.get('/auth/profile');

  // Devices
  Future<Response> registerDevice(Map<String, dynamic> data) =>
      _dio.post('/devices/register', data: data);

  Future<Response> getDevices() => _dio.get('/devices');

  Future<Response> deleteDevice(String deviceId) =>
      _dio.delete('/devices/$deviceId');

  Future<Response> heartbeat(String deviceId) =>
      _dio.patch('/devices/$deviceId/heartbeat');

  // Clipboard
  Future<Response> pushClipboard(Map<String, dynamic> data) =>
      _dio.post('/clipboard', data: data);

  Future<Response> getLatestClipboard() => _dio.get('/clipboard/latest');

  Future<Response> getClipboardHistory() => _dio.get('/clipboard/history');

  Future<Response> deleteClipboardItem(String id) =>
      _dio.delete('/clipboard/$id');

  // Sync
  Future<Response> getSyncConfig() => _dio.get('/sync/config');

  Future<Response> updateSyncConfig(Map<String, dynamic> data) =>
      _dio.put('/sync/config', data: data);

  Future<Response> triggerSync() => _dio.post('/sync/trigger');

  // Kill Switch
  Future<Response> lockDevice(String targetDeviceId) =>
      _dio.post('/killswitch/lock', data: {'targetDeviceId': targetDeviceId});

  Future<Response> wipeDevice(String targetDeviceId) =>
      _dio.post('/killswitch/wipe', data: {'targetDeviceId': targetDeviceId});

  Future<Response> getKillSwitchStatus(String deviceId) =>
      _dio.get('/killswitch/status/$deviceId');
}

class _AuthInterceptor extends Interceptor {
  final Dio _dio;

  _AuthInterceptor(this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Tentative de refresh du token
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        try {
          final response = await _dio.post(
            '/auth/refresh',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': null}),
          );
          final newToken = response.data['accessToken'];
          await _storage.write(key: 'access_token', value: newToken);

          // Relancer la requête originale avec le nouveau token
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retryResponse = await _dio.fetch(err.requestOptions);
          handler.resolve(retryResponse);
          return;
        } catch (_) {
          // Refresh échoué : déconnexion
          await _storage.deleteAll();
        }
      }
    }
    handler.next(err);
  }
}
