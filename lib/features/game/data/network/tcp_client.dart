import 'dart:async';
import 'dart:convert';
import 'dart:io';

class GameClient {
  Socket? _socket;
  final void Function(Map<String, dynamic>) onMessage;
  final void Function()? onDisconnected;
  bool _disposed = false;
  String? _lastIp;
  StringBuffer _buffer = StringBuffer();

  GameClient({required this.onMessage, this.onDisconnected});

  Future<bool> connect(String ip) async {
    _lastIp = ip;
    try {
      _socket?.destroy();
      _socket = await Socket.connect(
        ip,
        8082,
        timeout: const Duration(seconds: 6),
      );
      _socket!.setOption(SocketOption.tcpNoDelay, true);
      _buffer = StringBuffer();

      // FIX: cast<List<int>>() because Socket is Stream<Uint8List>
      _socket!.cast<List<int>>().transform(utf8.decoder).listen(
        (data) {
          _buffer.write(data);
          final str = _buffer.toString();
          final lines = str.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            final line = lines[i].trim();
            if (line.isEmpty) continue;
            try {
              onMessage(jsonDecode(line) as Map<String, dynamic>);
            } catch (_) {}
          }
          _buffer = StringBuffer(lines.last);
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
    Future.delayed(const Duration(seconds: 3), () {
      if (!_disposed && _lastIp != null) connect(_lastIp!);
    });
  }

  void send(Map<String, dynamic> data) {
    try { _socket?.write('${jsonEncode(data)}\n'); } catch (_) {}
  }

  void dispose() {
    _disposed = true;
    try { _socket?.destroy(); } catch (_) {}
  }
}
