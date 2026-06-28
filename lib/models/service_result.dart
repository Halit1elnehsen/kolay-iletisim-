// ============================================================
// lib/models/service_result.dart
// Generic Result tipi — başarı veya başarısızlığı taşır.
// Hiçbir exception uygulama katmanlarını geçmez.
// ============================================================

sealed class ServiceResult<T> {
  const ServiceResult();
}

final class ServiceSuccess<T> extends ServiceResult<T> {
  final T data;
  const ServiceSuccess(this.data);
}

final class ServiceFailure<T> extends ServiceResult<T> {
  final String message;
  final Object? error;
  const ServiceFailure(this.message, {this.error});
}

extension ServiceResultX<T> on ServiceResult<T> {
  bool get isSuccess => this is ServiceSuccess<T>;
  bool get isFailure => this is ServiceFailure<T>;

  T get data => (this as ServiceSuccess<T>).data;
  String get errorMessage => (this as ServiceFailure<T>).message;

  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      ServiceSuccess<T> s => success(s.data),
      ServiceFailure<T> f => failure(f.message),
    };
  }
}
