import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/storage_service.dart';
import 'api_response.dart';

class ApiClient {
  final Dio _dio;
  final StorageService _storageService;

  ApiClient({
    required StorageService storageService,
    Dio? dio,
  })  : _storageService = storageService,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Authorization Bearer token
          final token = await _storageService.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Attach active school context if available
          final schoolId = _storageService.getActiveSchoolId();
          if (schoolId != null && schoolId.isNotEmpty) {
            options.headers['X-School-Id'] = schoolId;
          }

          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Normalize error handling
          return handler.next(error);
        },
      ),
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('UNKNOWN_ERROR', 'Terjadi kendala tidak terduga.');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('UNKNOWN_ERROR', 'Terjadi kendala tidak terduga.');
    }
  }

  /// Uploads raw file bytes to the authenticated storage endpoint (Universal for Web & Mobile).
  Future<ApiResponse<Map<String, dynamic>>> uploadBytes(
    String path,
    List<int> bytes, {
    String? fileName,
  }) async {
    try {
      final name = fileName ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final response = await _dio.post(
        path,
        data: FormData.fromMap({
          'file': MultipartFile.fromBytes(bytes, filename: name),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (_) {
      return ApiResponse.failure('UPLOAD_FAILED', 'Gagal mengunggah berkas.');
    }
  }

  /// Uploads a local attachment to the authenticated endpoint.
  Future<ApiResponse<Map<String, dynamic>>> uploadFile(
    String path,
    String filePath,
  ) async {
    try {
      final fileName = filePath.split(RegExp(r'[/\\]')).last;
      final response = await _dio.post(
        path,
        data: FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: fileName),
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      return _handleResponse<Map<String, dynamic>>(
        response,
        (data) => Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      return _handleDioError<Map<String, dynamic>>(e);
    } catch (_) {
      return ApiResponse.failure('UPLOAD_FAILED', 'Gagal menyiapkan berkas untuk diunggah.');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.patch(path, data: data, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('UNKNOWN_ERROR', 'Terjadi kendala tidak terduga.');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJsonT,
  }) async {
    try {
      final response = await _dio.delete(path, queryParameters: queryParameters);
      return _handleResponse<T>(response, fromJsonT);
    } on DioException catch (e) {
      return _handleDioError<T>(e);
    } catch (e) {
      return ApiResponse.failure('UNKNOWN_ERROR', 'Terjadi kendala tidak terduga.');
    }
  }

  ApiResponse<T> _handleResponse<T>(Response response, T Function(dynamic json)? fromJsonT) {
    if (response.data is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(response.data as Map<String, dynamic>, fromJsonT);
    }
    return ApiResponse<T>.success(response.data as T);
  }

  ApiResponse<T> _handleDioError<T>(DioException error) {
    if (error.response?.data is Map<String, dynamic>) {
      return ApiResponse<T>.fromJson(error.response!.data as Map<String, dynamic>, null);
    }
    String message = 'Terjadi kendala jaringan. Periksa koneksi internet Anda.';
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Waktu permintaan habis. Silakan coba kembali.';
    }
    return ApiResponse.failure('NETWORK_ERROR', message);
  }
}
