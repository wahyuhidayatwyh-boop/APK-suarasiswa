class ApiResponse<T> {
  final bool success;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      error: json['error'] != null
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  factory ApiResponse.success(T data) {
    return ApiResponse<T>(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.failure(String code, String message) {
    return ApiResponse<T>(
      success: false,
      error: ApiError(code: code, message: message),
    );
  }
}

class ApiError {
  final String code;
  final String message;

  ApiError({
    required this.code,
    required this.message,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'Terjadi kendala. Silakan coba lagi.',
    );
  }
}
