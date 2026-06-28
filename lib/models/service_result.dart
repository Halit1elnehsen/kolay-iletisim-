// ============================================================
// lib/models/service_result.dart
//
// WHY THIS EXISTS:
// Most junior devs throw exceptions across service boundaries and
// catch them (badly) in the UI layer. This creates invisible
// coupling and makes error messages impossible to localise.
//
// Instead every service method returns ServiceResult<T>.
// The UI layer only pattern-matches on .isSuccess — it never
// needs to know what SpeechToTextException is.
// ============================================================

/// A discriminated union: either a value OR a typed failure.
/// Usage:
///   final result = await audioService.startListening(...);
///   if (result.isSuccess) { use(result.value); }
///   else                  { showError(result.failure!.userMessage); }
class ServiceResult<T> {
  final T?             _value;
  final ServiceFailure? failure;

  const ServiceResult._({T? value, this.failure}) : _value = value;

  /// Construct a success result.
  factory ServiceResult.success(T value) =>
      ServiceResult._(value: value);

  /// Construct a void success (use for methods that return nothing meaningful).
  static ServiceResult<void> ok() =>
      const ServiceResult._(value: null);

  /// Construct a failure result.
  factory ServiceResult.fail(ServiceFailure failure) =>
      ServiceResult._(failure: failure);

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  /// Throws if called on a failure result — use isSuccess first.
  T get value {
    if (_value == null) throw StateError('ServiceResult has no value. Check isSuccess first.');
    return _value as T;
  }

  /// Run [onSuccess] or [onFailure] depending on the result.
  R fold<R>({
    required R Function(T value)            onSuccess,
    required R Function(ServiceFailure err) onFailure,
  }) {
    return isSuccess ? onSuccess(value) : onFailure(failure!);
  }
}

// ---- Failure types ---- //

enum FailureKind {
  permissionDenied,
  deviceNotSupported,
  networkUnavailable,
  apiError,
  timeout,
  unknown,
}

class ServiceFailure {
  final FailureKind kind;

  /// Developer-facing message — shown in logs only.
  final String technicalMessage;

  /// User-facing message — safe to show in the UI.
  final String userMessage;

  const ServiceFailure({
    required this.kind,
    required this.technicalMessage,
    required this.userMessage,
  });

  // --- Pre-built failures so callers don't repeat strings --- //

  static const permissionDenied = ServiceFailure(
    kind:             FailureKind.permissionDenied,
    technicalMessage: 'Microphone permission was denied by the OS.',
    userMessage:      'Microphone access is required. Please enable it in Settings.',
  );

  static const deviceNotSupported = ServiceFailure(
    kind:             FailureKind.deviceNotSupported,
    technicalMessage: 'SpeechToText plugin reported device not supported.',
    userMessage:      'Speech recognition is not available on this device.',
  );

  static const networkUnavailable = ServiceFailure(
    kind:             FailureKind.networkUnavailable,
    technicalMessage: 'No internet connection detected.',
    userMessage:      'No internet connection. Using offline phrase bank instead.',
  );

  static const timeout = ServiceFailure(
    kind:             FailureKind.timeout,
    technicalMessage: 'Operation exceeded the maximum allowed duration.',
    userMessage:      'The request took too long. Please try again.',
  );

  static ServiceFailure apiError(String detail) => ServiceFailure(
    kind:             FailureKind.apiError,
    technicalMessage: 'API error: $detail',
    userMessage:      'Translation failed. Please try again.',
  );

  static ServiceFailure unknown(Object e) => ServiceFailure(
    kind:             FailureKind.unknown,
    technicalMessage: 'Unexpected error: $e',
    userMessage:      'Something went wrong. Please try again.',
  );

  @override
  String toString() => 'ServiceFailure(${kind.name}): $technicalMessage';
}