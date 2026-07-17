import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';

class GameClient {
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function()? onDisconnected;
  bool _disposed = false;
  String? _lastIp;

  GameClient({required this.onMessage, this.onDisconnected});

  Future<bool> connect(String ip) async {
    _lastIp = ip;
    try {
      _sub?.cancel();
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse('ws://\$ip:\${AppConstants.wsPort}'));
      await _channel!.ready.timeout(const Duration(seconds: 4));
      _sub = _channel!.stream.listen(
        (msg) {
          try { onMessage(jsonDecode(msg.toString())); } catch (_) {}
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
        cancelOnError: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  void _handleDisconnect() {
    if (_disposed) return;
    onDisconnected?.call();
    // Auto-reconnect after delay
    Future.delayed(AppConstants.reconnectDelay, () {
      if (!_disposed && _lastIp != null) connect(_lastIp!);
    });
  }

  void send(Map<String, dynamic> data) {
    try { _channel?.sink.add(jsonEncode(data)); } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    _sub?.cancel();
    _channel?.sink.close();
  }
}

