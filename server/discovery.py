#!/usr/bin/env python3
"""
MusicFlow Local Network UDP Auto-Discovery Service
Дозволяє смартфонам у спільній Wi-Fi мережі миттєво знаходити ПК без ручного введення IP.
"""

import socket
import threading
import time

DISCOVERY_UDP_PORT = 8088
MAGIC_PING = b"MUSICFLOW_DISCOVERY_PING"
RESPONSE_PREFIX = "MUSICFLOW_SERVER_HERE:"
BEACON_PREFIX = "MUSICFLOW_SERVER_BEACON:"


class DiscoveryServer:
    def __init__(self, http_port=8080, udp_port=DISCOVERY_UDP_PORT):
        self.http_port = http_port
        self.udp_port = udp_port
        self.running = False
        self._thread = None
        self._beacon_thread = None

    def start(self):
        if self.running:
            return
        self.running = True
        self._thread = threading.Thread(target=self._listen_loop, daemon=True, name="UDP-Discovery-Listener")
        self._thread.start()
        self._beacon_thread = threading.Thread(target=self._beacon_loop, daemon=True, name="UDP-Discovery-Beacon")
        self._beacon_thread.start()

    def stop(self):
        self.running = False

    def _listen_loop(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("", self.udp_port))
            sock.settimeout(1.0)
            while self.running:
                try:
                    data, addr = sock.recvfrom(1024)
                    if MAGIC_PING in data:
                        reply = f"{RESPONSE_PREFIX}{self.http_port}".encode("utf-8")
                        sock.sendto(reply, addr)
                except socket.timeout:
                    continue
                except Exception:
                    pass
        finally:
            sock.close()

    def _beacon_loop(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        beacon_msg = f"{BEACON_PREFIX}{self.http_port}".encode("utf-8")
        try:
            while self.running:
                try:
                    sock.sendto(beacon_msg, ("255.255.255.255", self.udp_port))
                except Exception:
                    pass
                time.sleep(4.0)
        finally:
            sock.close()


_instance = None


def start_discovery_server(http_port=8080):
    global _instance
    if _instance is None:
        _instance = DiscoveryServer(http_port=http_port)
        _instance.start()
    return _instance
