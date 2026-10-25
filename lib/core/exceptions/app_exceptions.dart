abstract class AppException implements Exception {
  final String message;
  final String prefix;

  AppException([
    this.message = 'Đã xảy ra lỗi không xác định',
    this.prefix = 'AppException',
  ]);

  @override
  String toString() {
    return '$prefix: $message';
  }
}

class TimerServiceException extends AppException {
  TimerServiceException([String message = 'Lỗi dịch vụ đếm giờ'])
    : super(message, 'Timer Error');
}

class StreamClosedException extends AppException {
  StreamClosedException([
    String message = 'Stream đã bị đóng, không thể truyền dữ liệu',
  ]) : super(message, 'Stream Error');
}
