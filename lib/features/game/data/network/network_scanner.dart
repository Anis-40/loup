import 'dart:async';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../../core/constants/app_constants.dart';

class DiscoveredRoom {
  final String roomName;
  final String hostIp;
  DiscoveredRoom({required this.roomName, required this.hostIp});
}

class NetworkScanner {
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  /// يمسح الشبكة المحلية بحثاً عن خوادم اللعبة
  Stream<DiscoveredRoom> scan() async* {
    _cancelled = false;
    final myIp = await getLocalIp();
    if (myIp == '127.0.0.1') return;

    final subnet = myIp.substring(0, myIp.lastIndexOf('.'));

    // نمسح كل الـ IPs في الشبكة الفرعية (1-254) بشكل متوازي
    final controllers = <StreamController<DiscoveredRoom?>>[];
    final futures = <Future>[];

    for (int i = 1; i <= 254; i++) {
      if (_cancelled) break;
      final ip = '$subnet.$i';
      if (ip == myIp) continue; // تخطي IP الجهاز نفسه
      futures.add(_tryConnect(ip));
    }

    // نجمع النتائج
    final results = await Future.wait(futures.map((f) async {
      try { return await f; } catch (_) { return null; }
    }));

    for (final r in results) {
      if (r != null && r is DiscoveredRoom) yield r;
    }
  }

  Future<DiscoveredRoom?> _tryConnect(String ip) async {
    try {
      // نحاول اتصال WebSocket سريع (timeout 500ms)
      final ws = WebSocketChannel.connect(
        Uri.parse('ws://$ip:${AppConstants.wsPort}/ping'),
      );
      await ws.ready.timeout(const Duration(milliseconds: 500));

      // إذا نجح الاتصال، هذا خادم لعبة!
      final completer = Completer<String?>();
      ws.stream.listen(
        (msg) {
          if (!completer.isCompleted) completer.complete(msg.toString());
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(null);
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete(null);
        },
      );

      ws.sink.add('PING');
      final response = await completer.future.timeout(
        const Duration(milliseconds: 800),
        onTimeout: () => null,
      );

      await ws.sink.close();

      if (response != null && response.startsWith('PONG:')) {
        final roomName = response.substring(5);
        return DiscoveredRoom(roomName: roomName, hostIp: ip);
      }
    } catch (_) {}
    return null;
  }

  static Future<String> getLocalIp() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final keywords = ['wlan', 'ap', 'swlan', 'p2p', 'rndis', 'eth', 'usb', 'wi-fi', 'wifi'];
      String? fallback;

      for (final iface in ifaces) {
        final name = iface.name.toLowerCase();
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          if (keywords.any((k) => name.contains(k))) return addr.address;
          if (addr.address.startsWith('192.168.') || addr.address.startsWith('10.')) {
            fallback ??= addr.address;
          }
          fallback ??= addr.address;
        }
      }
      if (fallback != null) return fallback;
    } catch (_) {}
    return '127.0.0.1';
  }
}
