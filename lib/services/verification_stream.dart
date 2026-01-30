import 'dart:async';

enum VerificationEvent {
  verified,
  rejected,
}

class VerificationStream {
  // Singleton
  static final VerificationStream _instance = VerificationStream._internal();
  factory VerificationStream() => _instance;
  VerificationStream._internal();

  final _controller = StreamController<VerificationEvent>.broadcast();

  Stream<VerificationEvent> get stream => _controller.stream;

  void add(VerificationEvent event) {
    _controller.add(event);
  }

  void dispose() {
    _controller.close();
  }
}
