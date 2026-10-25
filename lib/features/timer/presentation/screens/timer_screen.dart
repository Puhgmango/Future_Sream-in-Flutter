import 'package:flutter/material.dart';

import '../../domain/services/timer_service.dart';
import '../widgets/control_buttons.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  late final TimerService _timerService;

  @override
  void initState() {
    super.initState();
    _timerService = TimerService();
  }

  @override
  void dispose() {
    _timerService.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark mode background
      appBar: AppBar(
        title: const Text(
          'Đồng Hồ Bấm Giờ',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Thời gian trôi qua',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 20),
            StreamBuilder<int>(
              stream: _timerService.timerStream,
              initialData: 0,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    'Lỗi: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 20,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    _timerService.currentCounter == 0) {
                  return const Text(
                    '00:00',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B8D4),
                      fontFamily: 'monospace',
                    ),
                  );
                }

                final int currentTime = snapshot.data ?? 0;

                return Text(
                  _formatTime(currentTime),
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B8D4),
                    fontFamily: 'monospace',
                  ),
                );
              },
            ),
            const SizedBox(height: 60),
            ControlButtons(
              onStart: () => _timerService.start(),
              onPause: () => _timerService.pause(),
              onReset: () => _timerService.reset(),
            ),
          ],
        ),
      ),
    );
  }
}
