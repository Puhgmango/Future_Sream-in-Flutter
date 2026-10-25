# Chủ đề 02: Lập trình Bất đồng bộ với Future & Stream trong Flutter

Ứng dụng **Đồng hồ Bấm giờ (Stopwatch)** được xây dựng để minh họa cơ chế lập trình bất đồng bộ trong Flutter. Dự án tập trung vào việc sử dụng `Stream` và `StreamController` để phát luồng dữ liệu thời gian thực, sử dụng `StreamBuilder` để cập nhật giao diện tối ưu theo luồng dữ liệu một chiều. Dự án được làm để minh họa cách tách biệt giao diện, logic xử lý thời gian và giải quyết vấn đề rò rỉ bộ nhớ (Memory Leak).

---

## 1. Thông tin nhóm

| STT | Họ và tên | MSSV | Phụ trách |
|---|---|---|---|
| 1 | Phạm Viết Duy | 106230008 | Business Logic (TimerService), Core Exceptions, Test |
| 2 | Cao Minh Phụng | 106230023 | UI Design (TimerScreen, ControlButtons), Cấu hình Main |

Tỷ lệ đóng góp: 50% – 50%. Hai thành viên review chéo phần của nhau.

## 2. Yêu cầu của đề

**Nội dung:**
- Cơ chế bất đồng bộ: Xử lý tác vụ chờ với `Future` và cú pháp `async/await`.
- Luồng dữ liệu liên tục (Stream): Sử dụng `StreamController` để phát dữ liệu, lắng nghe sự kiện và cập nhật giao diện bằng `StreamBuilder`.
- Cơ chế dọn dẹp: Hủy lắng nghe (`cancel`/`dispose`) để tránh rò rỉ bộ nhớ (memory leak).
- Tách biệt logic: Đóng gói tác vụ đếm giờ và quản lý luồng độc lập, không phụ thuộc vào widget.

**Yêu cầu demo:**
- Xây dựng ứng dụng hiển thị dữ liệu biến đổi liên tục (Đồng hồ bấm giờ) sử dụng `StreamBuilder`.
- Có nút Bắt đầu / Tạm dừng / Đặt lại và đảm bảo giải phóng (`close`/`cancel`) Stream an toàn khi người dùng thoát khỏi màn hình.
- Chứng minh tầng View không chứa code xử lý `Timer` ngầm; View chỉ lắng nghe và hiển thị trạng thái từ Service.
- Chất lượng Source Code: Cấu trúc thư mục chuẩn, Clean code, tuân thủ Dart styling guide, xử lý ngoại lệ chặt chẽ.

## 3. Tính năng

- Hiển thị thời gian trôi qua với định dạng `MM:SS` cập nhật liên tục mỗi giây.
- Điều khiển trạng thái đếm giờ qua 3 nút: **Bắt đầu**, **Tạm dừng**, **Đặt lại**.
- Hiển thị 3 trạng thái của luồng dữ liệu: Đang chờ (Waiting), Đang chạy (Active/Success), và Lỗi (Error).
- Tự động hủy luồng ngầm an toàn khi thoát ứng dụng hoặc chuyển màn hình.

## 4. Kiến trúc Dự án

```
┌────────┐  sự kiện   ┌──────────────┐   gọi    ┌──────────────┐
│  View  │ ─────────► │ TimerService │ ───────► │ dart:async   │
│        │ ◄───────── │ (Stream)     │          │ (Timer)      │
└────────┘   state    └──────────────┘          └──────────────┘
           sink.add()
```

| Thành phần | Thư mục | Vai trò |
|---|---|---|
| **Core** | `lib/core/exceptions/` | Chứa `AppException` đóng gói các lỗi như `StreamClosedException`, `TimerServiceException`. |
| **Service** | `lib/features/timer/domain/services/` | `TimerService` đóng gói việc dùng `Timer.periodic`, quản lý `StreamController`. Phát số đếm qua `sink.add()` và cung cấp `stream` ra ngoài. Không import widget. |
| **View** | `lib/features/timer/presentation/` | `TimerScreen` lắng nghe `TimerService` bằng `StreamBuilder` và vẽ giao diện theo trạng thái. Không tự xử lý `Timer`. |

### Luồng dữ liệu một chiều

1. Người dùng bấm **Bắt đầu** → View gọi `_timerService.start()`.
2. Service kích hoạt `Timer.periodic`, mỗi giây tăng biến đếm và gọi `sink.add(counter)`.
3. `StreamBuilder` trong View nhận tín hiệu dữ liệu mới (hoặc lỗi).
4. `StreamBuilder` tự build lại (rebuild) chỉ phần Text hiển thị thời gian, giữ nguyên các nút bấm.

Sự kiện đi **lên** (View → Service), trạng thái đi **xuống** (Service → View). View không tự tính toán thời gian.

### Liên kết View – Service

```dart
// Service: phát tín hiệu khi biến đếm thay đổi
class TimerService {
  final StreamController<int> _controller = StreamController<int>.broadcast();
  // ... mỗi giây gọi: _controller.sink.add(_counter);
}

// View: lắng nghe và vẽ lại
StreamBuilder<int>(
  stream: _timerService.timerStream,
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text('Lỗi: ${snapshot.error}');
    if (snapshot.connectionState == ConnectionState.waiting) return Text('00:00');
    return Text(_formatTime(snapshot.data ?? 0));
  },
)
```

### Khởi tạo và liên kết phụ thuộc

Trong `timer_screen.dart`, Service được khởi tạo trong `initState` và quan trọng nhất là phải được dọn dẹp trong `dispose`:

```dart
@override
void dispose() {
  _timerService.dispose(); // Gọi cancel Timer và close Stream
  super.dispose();
}
```

## 5. Cấu trúc thư mục

```
lib/
├── core/
│   └── exceptions/
│       └── app_exceptions.dart
├── features/
│   └── timer/
│       ├── domain/
│       │   └── services/
│       │       └── timer_service.dart
│       └── presentation/
│           ├── screens/
│           │   └── timer_screen.dart
│           └── widgets/
│               └── control_buttons.dart
└── main.dart
```

## 6. Ba trạng thái của giao diện (StreamBuilder)

| Trạng thái Connection | Stream | View hiển thị |
|---|---|---|
| **Waiting** | `ConnectionState.waiting`, chưa có event | Hiển thị mặc định `00:00` |
| **Active / Success** | `snapshot.hasData`, có dữ liệu (ví dụ `25`) | Gọi hàm `_formatTime` hiển thị `00:25` |
| **Error** | `snapshot.hasError` | Biểu tượng lỗi, thông báo chữ đỏ "Lỗi: Không thể đếm giờ" |

## 7. Chứng minh View không chứa logic thời gian

1. **Kiểm tra mã nguồn:** tìm các từ khóa `Timer.periodic`, `StreamController`, `sink.add` trong thư mục `lib/features/timer/presentation/` — kết quả phải rỗng.

   ```powershell
   Select-String -Path lib\features\timer\presentation\*.dart -Pattern "Timer.periodic|StreamController|sink.add"
   ```

   Trong VS Code: `Ctrl+Shift+F`, tìm `Timer.periodic`, giới hạn trong `lib/features/timer/presentation`.

2. Toàn bộ logic đếm và phát sự kiện nằm hoàn toàn ở `TimerService`.

## 8. Unit test

(Giả định) File: `test/services/timer_service_test.dart`

| Trường hợp | Kết quả mong đợi |
|---|---|
| Gọi hàm `start()` | Stream phát ra các số nguyên liên tiếp `1, 2, 3...` |
| Gọi hàm `pause()` | Biến đếm dừng lại, không phát sinh lỗi |
| Gọi `start()` khi Stream đã `close()` | Ném `StreamClosedException`, luồng bắt lỗi hoạt động |

## 9. Hướng dẫn chạy

Yêu cầu: Flutter SDK (Dart `>=3.0.0`).

```bash
git clone <đường-dẫn-repo>
cd <thư-mục-dự-án>
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Có thể chạy trên Android, iOS hoặc Windows.
*Lưu ý để thử nghiệm Memory Leak:* Chạy `flutter run --profile`, mở Flutter DevTools (tab Memory), thử thoát màn hình để xem bộ nhớ có được thu gom (Garbage Collected) đúng cách không.

## 10. Công nghệ sử dụng

| Thư viện | Phiên bản | Vai trò |
|---|---|---|
| `flutter` | SDK | Framework giao diện |
| `dart:async` | Tích hợp sẵn | Cung cấp `Timer`, `Stream`, `StreamController` |
| `flutter_lints` | ^3.0.0 | Quy tắc phân tích tĩnh |

`StreamBuilder` có sẵn trong Flutter nên không cần thư viện quản lý state bên ngoài.

## 11. Hạn chế và hướng phát triển

**Hạn chế:**

- Trạng thái thời gian sẽ bị mất nếu người dùng tắt hoàn toàn ứng dụng (Kill App).
- Chưa có tính năng bấm giờ theo vòng (Lap).
- Chưa áp dụng Dependency Injection (DI) thông qua GetIt/Injectable.

**Hướng phát triển:**

- Thêm tính năng "Lap" để lưu lại các mốc thời gian.
- Sử dụng `SharedPreferences` hoặc `Hive` để lưu timestamp bắt đầu, giúp khôi phục trạng thái ngay cả khi tắt app.
- Tái sử dụng `TimerService` để xây dựng màn hình đếm ngược (Countdown Timer) bằng cách truyền tham số khởi tạo.

## 12. Phân công công việc (WBS)

| Vai trò | Người phụ trách | File chính |
|---|---|---|
| Business Logic (Stream, Timer) | Phạm Viết Duy | `services/timer_service.dart`, `core/exceptions/` |
| UI Design & Layout | Cao Minh Phụng | `screens/timer_screen.dart`, `widgets/control_buttons.dart` |
| Báo cáo, slide | Cả hai | `README.md`, file slide |
| Tích hợp & Kiểm tra Memory Leak | Cả hai | `main.dart`, chạy DevTools kiểm tra `dispose` |

## 13. Tài liệu tham khảo

- Dart, *Asynchronous programming: Streams* — https://dart.dev/tutorials/language/streams
- Flutter, *Handling Memory Leaks with Streams* — https://docs.flutter.dev/perf/memory
- Flutter API: `StreamBuilder`, `StreamController` — https://api.flutter.dev
