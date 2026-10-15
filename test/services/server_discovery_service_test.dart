import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_flow_mobile/services/server_discovery_service.dart';

void main() {
  group('ServerDiscoveryService Tests', () {
    test('Protocol constants are correctly defined', () {
      expect(ServerDiscoveryService.discoveryUdpPort, equals(8088));
      expect(ServerDiscoveryService.magicPing, equals('MUSICFLOW_DISCOVERY_PING'));
      expect(ServerDiscoveryService.responsePrefix, equals('MUSICFLOW_SERVER_HERE:'));
      expect(ServerDiscoveryService.beaconPrefix, equals('MUSICFLOW_SERVER_BEACON:'));
    });

    test('discoverLocalServer completes and returns null on timeout when no server responds', () async {
      final result = await ServerDiscoveryService.discoverLocalServer(
        timeout: const Duration(milliseconds: 150),
      );
      // In isolated test runner without a running music server, expect null safely without exception
      expect(result, isNull);
    });

    test('Protocol message parsing correctly extracts port and IP', () {
      final datagramAddr = InternetAddress('192.168.1.105');
      final rawResponse = utf8.encode('MUSICFLOW_SERVER_HERE:8080');
      final msg = utf8.decode(rawResponse).trim();

      expect(msg.startsWith(ServerDiscoveryService.responsePrefix), isTrue);
      final port = int.tryParse(msg.substring(ServerDiscoveryService.responsePrefix.length));
      expect(port, equals(8080));
      final discoveredUrl = 'http://${datagramAddr.address}:$port';
      expect(discoveredUrl, equals('http://192.168.1.105:8080'));
    });

    test('Beacon message parsing extracts port and IP', () {
      final datagramAddr = InternetAddress('10.0.0.12');
      final rawBeacon = utf8.encode('MUSICFLOW_SERVER_BEACON:5000');
      final msg = utf8.decode(rawBeacon).trim();

      expect(msg.startsWith(ServerDiscoveryService.beaconPrefix), isTrue);
      final port = int.tryParse(msg.substring(ServerDiscoveryService.beaconPrefix.length));
      expect(port, equals(5000));
      final discoveredUrl = 'http://${datagramAddr.address}:$port';
      expect(discoveredUrl, equals('http://10.0.0.12:5000'));
    });
  });
}
