import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:udp/udp.dart';
import '../../../../core/constants/app_constants.dart';

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
    // Use a more aggressive binding and broadcast approach
    _sender = await UDP.bind(Endpoint.any(port: Port(AppConstants.discoveryPort)));

    final msg  = utf8.encode(jsonEncode({'type': 'LG_ROOM', 'roomName': roomName, 'ip': myIp}));

    _timer = Timer.periodic(
      const Duration(seconds: 1), (_) async { // Increase frequency to 1 second
        try {
          // Send to standard broadcast address
          await _sender?.send(msg, Endpoint.broadcast(port: Port(AppConstants.discoveryPort)));
          // Also try common subnet broadcast as fallback
          if (myIp != '127.0.0.1') {
            final subnet = myIp.substring(0, myIp.lastIndexOf('.'));
            await _sender?.send(msg, Endpoint.unicast(InternetAddress('$subnet.255'), port: Port(AppConstants.discoveryPort)));
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
    _receiver = await UDP.bind(Endpoint.any(port: Port(AppConstants.discoveryPort)));
    await for (final dg in _receiver!.asStream()) {
      if (dg == null) continue;
      try {
        final d = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
        if (d['type'] == 'LG_ROOM') {
          yield DiscoveredRoom(roomName: d['roomName'], hostIp: d['ip']);
        }
      } catch (_) {}
    }
  }

  void stopListening() { _receiver?.close(); _receiver = null; }

  static Future<String> getLocalIp() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);

      // القائمة الموسعة لواجهات الشبكة (واي فاي، نقطة اتصال، إيثرنت، USB)
      final hotspotKeywords = ['wlan', 'ap', 'swlan', 'p2p', 'rndis', 'eth', 'usb'];

      String? fallbackIp;

      for (final i in ifaces) {
        final name = i.name.toLowerCase();
        final isLikelyPrimary = hotspotKeywords.any((k) => name.contains(k));

        for (final a in i.addresses) {
          if (a.isLoopback) continue;

          if (isLikelyPrimary) {
            return a.address;
          }

          if (a.address.startsWith('192.168.')) {
            fallbackIp = a.address;
          } else if (fallbackIp == null) {
            fallbackIp = a.address;
          }
        }
      }
      if (fallbackIp != null) return fallbackIp;
    } catch (_) {}
    return '127.0.0.1';
  }
}
