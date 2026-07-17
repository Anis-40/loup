import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';

typedef MessageHandler = void Function(WebSocketChannel, Map<String, dynamic>);

class LocalGameServer {
  final List<_ClientConn> _clients = [];
  MessageHandler? onMessage;
  HttpServer? _server;
  String _roomName = '';

  Future<void> start(String roomName) async {
    _roomName = roomName;
    final handler = webSocketHandler((WebSocketChannel ws) {
      final conn = _ClientConn(ws);
      _clients.add(conn);
      ws.stream.listen(
        (msg) {
          final text = msg.toString();
          // إجابة على طلب الاكتشاف (PING)
          if (text == 'PING') {
            try { ws.sink.add('PONG:$_roomName'); } catch (_) {}
            return;
          }
          try {
            final data = jsonDecode(text) as Map<String, dynamic>;
            onMessage?.call(ws, data);
          } catch (_) {}
        },
        onDone: () => _clients.removeWhere((c) => c.channel == ws),
        onError: (_) => _clients.removeWhere((c) => c.channel == ws),
        cancelOnError: true,
      );
    });
    try {
      _server = await io.serve(handler, '0.0.0.0', AppConstants.wsPort,
          shared: true);
    } catch (e) {
      // إذا كان المنفذ مشغولاً، نحاول إيقافه أولاً
      await stop();
      _server = await io.serve(handler, '0.0.0.0', AppConstants.wsPort,
          shared: true);
    }
  }

  void broadcast(Map<String, dynamic> data) {
    final msg = jsonEncode(data);
    for (final c in List.from(_clients)) {
      try { c.channel.sink.add(msg); } catch (_) {}
    }
  }

  void sendToPlayer(String playerId, Map<String, dynamic> data) {
    final msg = jsonEncode(data);
    for (final c in _clients) {
      if (c.playerId == playerId) {
        try { c.channel.sink.add(msg); } catch (_) {}
        break;
      }
    }
  }

  void setPlayerIdForChannel(WebSocketChannel ws, String playerId) {
    for (final c in _clients) {
      if (c.channel == ws) { c.playerId = playerId; break; }
    }
  }

  void kickPlayer(String playerId) {
    for (final c in List.from(_clients)) {
      if (c.playerId == playerId) {
        try { c.channel.sink.close(); } catch (_) {}
        _clients.remove(c);
        break;
      }
    }
  }

  Future<void> stop() async {
    for (final c in _clients) { try { c.channel.sink.close(); } catch (_) {} }
    _clients.clear();
    await _server?.close(force: true);
    _server = null;
  }
}

class _ClientConn {
  final WebSocketChannel channel;
  String? playerId;
  _ClientConn(this.channel);
}
