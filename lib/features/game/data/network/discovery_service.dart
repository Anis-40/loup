import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:udp/udp.dart';

class DiscoveredRoom {
  final String roomName;
  final String hostIp;
  DiscoveredRoom({required this.roomName, required this.hostIp});
}

class DiscoveryService {
  UDP? _sender;
  UDP? _receiver;
  Timer? _timer;

  Future<void> startBroadcasting(String roomName) async {
    stopBroadcasting();
    final myIp = await getLocalIp();
    _sender = await UDP.bind(Endpoint.any());

    final msg = utf8.encode(jsonEncode({
      'type': 'LG_ROOM',
      'roomName': roomName,
      'ip': myIp,
    }));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        await _sender?.send(msg, Endpoint.broadcast(port: Port(9998)));
        if (myIp != '127.0.0.1') {
          final subnet = myIp.substring(0, myIp.lastIndexOf('.'));
          await _sender?.send(
              msg, Endpoint.unicast(InternetAddress('$subnet.255'), port: Port(9998)));
        }
      } catch (_) {}
    });
  }

  void stopBroadcasting() {
    _timer?.cancel();
    _sender?.close();
    _sender = null;
  }

  Stream<DiscoveredRoom> listenForRooms() async* {
    _receiver?.close();
    try {
      _receiver = await UDP.bind(Endpoint.any(port: Port(9998)));
      await for (final dg in _receiver!.asStream()) {
        if (dg == null) continue;
        try {
          final d = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
          if (d['type'] == 'LG_ROOM') {
            yield DiscoveredRoom(
              roomName: d['roomName'] as String,
              hostIp: d['ip'] as String,
            );
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  void stopListening() {
    _receiver?.close();
    _receiver = null;
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
          if (addr.address.startsWith('192.168.') ||
              addr.address.startsWith('10.') ||
              addr.address.startsWith('172.')) {
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
