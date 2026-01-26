"""Fixtures and helpers for modbus-proxy tests."""

import sys
from pathlib import Path
import asyncio
import pytest

# Ensure package module is importable from src
ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
sys.path.insert(0, str(SRC))

from modbus_proxy import ModBus  # pylint: disable=wrong-import-position


class DummyTransport:
    """Dummy UDP transport that records sent data."""

    def __init__(self):
        self.sent = []

    def sendto(self, data, addr):
        """Mock sendto that records sent data."""
        self.sent.append((bytes(data), addr))

    def close(self):
        """Mock close method."""


class DummyProtocol:  # pylint: disable=R0903
    """Dummy UDP protocol that provides a queue for incoming packets."""

    def __init__(self):
        self.queue = asyncio.Queue()


@pytest.fixture
def bridge_factory():
    """Return a factory that creates a ModBus bridge with fresh dummy transport/protocol."""

    def _make(
        udp_cfg=None,
        url="udp://192.168.25.147:1502",
        timeout=1,
        bind="192.168.25.247:8999",
    ):
        mod_conf = {"url": url, "timeout": timeout}
        if udp_cfg:
            mod_conf.update(udp_cfg)
        cfg = {"modbus": mod_conf, "listen": {"bind": bind}}
        bridge = ModBus(cfg)
        bridge.udp_protocol = DummyProtocol()
        bridge.udp_transport = DummyTransport()
        return bridge

    return _make


def put_response(protocol, data, addr=None):
    """Convenience helper to put a response into a DummyProtocol queue."""
    if addr is None:
        addr = ("192.168.25.147", 1502)
    return protocol.queue.put_nowait((data, addr))


def last_sent(transport):
    """Return the last sent payload or None."""
    if not transport.sent:
        return None
    return transport.sent[-1][0]
