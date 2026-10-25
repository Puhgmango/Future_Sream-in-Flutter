import 'dart:async';
import 'dart:developer' as developer;

import '../../../../core/exceptions/app_exceptions.dart';

class TimerService {
  final StreamController<int> _controller = StreamController<int>.broadcast();

  Stream<int> get timerStream => _controller.stream;

  Timer? _timer;
  int _counter = 0;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  int get currentCounter => _counter;

  void start() {
    if (_isRunning) return;

    try {
      _isRunning = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _counter++;
        if (_controller.isClosed) {
          throw StreamClosedException();
        }
        _controller.sink.add(_counter);
      });
    } catch (e, stackTrace) {
      developer.log(
        'Lỗi khi khởi động timer',
        error: e,
        stackTrace: stackTrace,
      );
      if (!_controller.isClosed) {
        _controller.sink.addError(
          TimerServiceException('Không thể đếm giờ').toString(),
        );
      }
    }
  }

  void pause() {
    try {
      _timer?.cancel();
      _isRunning = false;
    } catch (e, stackTrace) {
      developer.log('Lỗi khi tạm dừng timer', error: e, stackTrace: stackTrace);
    }
  }

  void reset() {
    try {
      pause();
      _counter = 0;
      if (!_controller.isClosed) {
        _controller.sink.add(_counter);
      }
    } catch (e, stackTrace) {
      developer.log('Lỗi khi reset timer', error: e, stackTrace: stackTrace);
    }
  }

  void dispose() {
    try {
      _timer?.cancel();
      _controller.close();
      developer.log('Đã giải phóng TimerService an toàn.');
    } catch (e, stackTrace) {
      developer.log('Lỗi khi dispose timer', error: e, stackTrace: stackTrace);
    }
  }
}
