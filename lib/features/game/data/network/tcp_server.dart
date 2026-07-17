import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef TcpMessageHandler = void Function(Socket, Map<String, dynamic>);

class LocalGameServer {
  ServerSocket? _serverSocket;
  final List<_ClientConn> _clients = [];
  TcpMessageHandler? onMessage;
  String _roomName = '';

  Future<void> start(String roomName) async {
    _roomName = roomName;
    await stop();

    _serverSocket = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      8082,
      shared: true,
    );

    _serverSocket!.listen(_handleNewClient, onError: (_) {}, onDone: () {});
  }

  void _handleNewClient(Socket socket) {
    socket.setOption(SocketOption.tcpNoDelay, true);
    final conn = _ClientConn(socket);
    _clients.add(conn);

    StringBuffer buffer = StringBuffer();

    // FIX: cast<List<int>>() because Socket is Stream<Uint8List>
    socket.cast<List<int>>().transform(utf8.decoder).listen(
      (data) {
        buffer.write(data);
        final str = buffer.toString();
        final lines = str.split('\n');
        for (int i = 0; i < lines.length - 1; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          if (line == 'PING') {
            _send(socket, 'PONG:$_roomName');
            continue;
          }
          try {
            final decoded = jsonDecode(line) as Map<String, dynamic>;
            onMessage?.call(socket, decoded);
          } catch (_) {}
        }
        buffer = StringBuffer(lines.last);
      },
      onDone: () => _removeSocket(socket),
      onError: (_) => _removeSocket(socket),
      cancelOnError: true,
    );
  }

  void _removeSocket(Socket socket) {
    _clients.removeWhere((c) => c.socket == socket);
    try { socket.destroy(); } catch (_) {}
  }

  void _send(Socket socket, String message) {
    try { socket.write('$message\n'); } catch (_) {}
  }

  void broadcast(Map<String, dynamic> data) {
    final msg = '${jsonEncode(data)}\n';
    for (final c in List.from(_clients)) {
      try { c.socket.write(msg); } catch (_) {}
    }
  }

  void sendToPlayer(String playerId, Map<String, dynamic> data) {
    final msg = '${jsonEncode(data)}\n';
    for (final c in _clients) {
      if (c.playerId == playerId) {
        try { c.socket.write(msg); } catch (_) {}
        break;
      }
    }
  }

  void setPlayerIdForSocket(Socket socket, String playerId) {
    for (final c in _clients) {
      if (c.socket == socket) { c.playerId = playerId; break; }
    }
  }

  void kickPlayer(String playerId) {
    for (final c in List.from(_clients)) {
      if (c.playerId == playerId) {
        try { c.socket.destroy(); } catch (_) {}
        _clients.remove(c);
        break;
      }
    }
  }

  Future<void> stop() async {
    for (final c in _clients) {
      try { c.socket.destroy(); } catch (_) {}
    }
    _clients.clear();
    await _serverSocket?.close();
    _serverSocket = null;
  }
}

class _ClientConn {
  final Socket socket;
  String? playerId;
  _ClientConn(this.socket);
}
