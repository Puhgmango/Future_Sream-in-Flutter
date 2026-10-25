// test/domain/timer_service_test.dart

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

// Sửa đường dẫn import này cho khớp với vị trí thật của TimerService
// trong project của bạn.
import 'package:fture_stream/features/timer/domain/services/timer_service.dart';

void main() {
  group('TimerService', () {
    test('phát dữ liệu stream theo từng giây khi start()', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];

        final sub = service.timerStream.listen(emitted.add);

        service.start();
        expect(service.isRunning, isTrue);

        async.elapse(const Duration(seconds: 3));

        expect(emitted, [1, 2, 3]);
        expect(service.currentCounter, 3);

        sub.cancel();
        service.dispose();
      });
    });

    test('gọi start() khi đang chạy là no-op, không tạo timer thứ hai', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];
        final sub = service.timerStream.listen(emitted.add);

        service.start();
        service.start(); // gọi lại khi đã chạy
        async.elapse(const Duration(seconds: 2));

        // Nếu bị tạo 2 timer song song, giá trị sẽ là [2, 4] thay vì [1, 2]
        expect(emitted, [1, 2]);

        sub.cancel();
        service.dispose();
      });
    });

    test('pause() dừng đếm, isRunning = false, không phát thêm tick', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];
        final sub = service.timerStream.listen(emitted.add);

        service.start();
        async.elapse(const Duration(seconds: 2));
        service.pause();

        expect(service.isRunning, isFalse);

        async.elapse(const Duration(seconds: 5));
        expect(emitted, [1, 2]); // không có tick mới trong lúc pause

        sub.cancel();
        service.dispose();
      });
    });

    test('start() lại sau pause() tiếp tục đếm từ giá trị hiện tại', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];
        final sub = service.timerStream.listen(emitted.add);

        service.start();
        async.elapse(const Duration(seconds: 2));
        service.pause();

        service.start();
        expect(service.isRunning, isTrue);
        async.elapse(const Duration(seconds: 2));

        expect(emitted, [1, 2, 3, 4]);
        expect(service.currentCounter, 4);

        sub.cancel();
        service.dispose();
      });
    });

    test('reset() đưa counter về 0, phát 0 qua stream và dừng chạy', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];
        final sub = service.timerStream.listen(emitted.add);

        service.start();
        async.elapse(const Duration(seconds: 3));
        service.reset();

        expect(service.currentCounter, 0);
        expect(service.isRunning, isFalse);
        expect(emitted.last, 0);

        // Không start() lại thì không có tick mới sau reset.
        async.elapse(const Duration(seconds: 3));
        expect(emitted.last, 0);

        sub.cancel();
        service.dispose();
      });
    });

    test('reset() khi chưa start() không gây lỗi và phát 0', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];
        final sub = service.timerStream.listen(emitted.add);

        expect(() => service.reset(), returnsNormally);
        expect(emitted, [0]);
        expect(service.currentCounter, 0);

        sub.cancel();
        service.dispose();
      });
    });

    test('dispose() hủy timer và đóng stream, không leak memory', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];

        final sub = service.timerStream.listen(emitted.add);

        service.start();
        async.elapse(const Duration(seconds: 2));

        service.dispose();
        async.flushMicrotasks();

        // Timer đã bị hủy nên không còn tick nào được phát thêm,
        // kể cả khi thời gian tiếp tục trôi qua.
        async.elapse(const Duration(seconds: 5));
        expect(emitted, [1, 2]);

        // Stream đã đóng: đăng ký thêm một listener mới sẽ không bao giờ
        // nhận được sự kiện nào nữa (cũng không văng lỗi).
        var secondListenerCalled = false;
        service.timerStream.listen((_) => secondListenerCalled = true);
        async.elapse(const Duration(seconds: 2));
        expect(secondListenerCalled, isFalse);

        sub.cancel();
      });
    });

    test('gọi dispose() nhiều lần không ném lỗi (an toàn khi dispose lặp)',
        () {
      fakeAsync((async) {
        final service = TimerService();

        service.start();
        async.elapse(const Duration(seconds: 1));

        expect(() => service.dispose(), returnsNormally);
        expect(() => service.dispose(), returnsNormally);
      });
    });

    test('không phát tick mới sau khi listener tự hủy đăng ký', () {
      fakeAsync((async) {
        final service = TimerService();
        final emitted = <int>[];

        final sub = service.timerStream.listen(emitted.add);
        service.start();
        async.elapse(const Duration(seconds: 1));

        sub.cancel();
        async.elapse(const Duration(seconds: 5));

        expect(emitted, [1]);

        service.dispose();
      });
    });
  });
}