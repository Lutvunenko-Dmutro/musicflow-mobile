import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:music_flow_mobile/utils/app_logger.dart';

class ServerDiscoveryService {
  static const int discoveryUdpPort = 8088;
  static const String magicPing = 'MUSICFLOW_DISCOVERY_PING';
  static const String responsePrefix = 'MUSICFLOW_SERVER_HERE:';
  static const String beaconPrefix = 'MUSICFLOW_SERVER_BEACON:';

  static Future<String?> discoverLocalServer({
    Duration timeout = const Duration(milliseconds: 1800),
  }) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final completer = Completer<String?>();
      final pingData = utf8.encode(magicPing);

      void handleDatagram(Datagram? datagram) {
        if (datagram == null || completer.isCompleted) return;
        final msg = utf8.decode(datagram.data, allowMalformed: true).trim();
        int? port;
        if (msg.startsWith(responsePrefix)) {
          port = int.tryParse(msg.substring(responsePrefix.length));
        } else if (msg.startsWith(beaconPrefix)) {
          port = int.tryParse(msg.substring(beaconPrefix.length));
        }
        if (port != null) {
          final discoveredUrl = 'http://${datagram.address.address}:$port';
          AppLogger.info('Знайдено сервер MusicFlow через Wi-Fi UDP: $discoveredUrl', 'DISCOVERY');
          completer.complete(discoveredUrl);
        }
      }

      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          handleDatagram(socket?.receive());
        }
      });

      try {
        socket.send(pingData, InternetAddress('255.255.255.255'), discoveryUdpPort);
      } catch (_) {}

      final timer = Timer(timeout, () {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      });

      final result = await completer.future;
      timer.cancel();
      return result;
    } catch (e) {
      AppLogger.warning('Помилка UDP пошуку сервера: $e', 'DISCOVERY');
      return null;
    } finally {
      socket?.close();
    }
  }
}
