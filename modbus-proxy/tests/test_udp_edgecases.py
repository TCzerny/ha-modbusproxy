"""Tests for UDP edge cases in modbus-proxy."""

# pylint: disable=W0212
import struct
import pytest

from modbus_proxy import modbus_crc


@pytest.mark.asyncio
async def test_udp_preflight_timeout(bridge_factory):
    """Test that UDP preflight timeout is handled gracefully."""
    # preflight expected but no response -> None returned
    bridge = bridge_factory(
        {
            "set_client_address": "AA",
            "set_client_address_response": "OK",
            "set_client_timeout": 0.01,
        },
    )
    # no response put into queue
    mbap = b"\x00\x01\x00\x00\x00\x02"
    req = mbap + b"\x01\x03"
    resp = await bridge._udp_write_read(req)
    assert resp is None


@pytest.mark.asyncio
async def test_udp_malformed_prefix_template(bridge_factory):
    """Test that unknown token in prefix template is ignored and does not crash."""
    bridge = bridge_factory()
    payload = b"\x01\x03\x02\x00\x2a"
    plen = len(payload)
    udp_pkt = struct.pack(
        f">HHHB{plen}sH",
        0x0002,
        0x0102,
        plen + 3,
        0xFF,
        payload,
        modbus_crc(payload),
    )
    await bridge.udp_protocol.queue.put(
        (udp_pkt, (bridge.modbus_host, bridge.modbus_port))
    )
    mbap = b"\x00\x02\x00\x00\x00\x03"
    req = mbap + b"\x01\x03\x00"
    res = await bridge._udp_write_read(req)
    assert res is not None


@pytest.mark.asyncio
async def test_udp_gateway_insertion_edge(bridge_factory):
    """Test that gateway ID insertion handles short payloads safely."""
    bridge = bridge_factory({})
    payload = b"\x01\x03\x02\x00\x2a"
    plen = len(payload)
    udp_pkt = struct.pack(
        f">HHHB{plen}sH",
        0x0004,
        0x0102,
        plen + 3,
        0xFF,
        payload,
        modbus_crc(payload),
    )
    bridge.udp_protocol.queue.put_nowait(
        (udp_pkt, (bridge.modbus_host, bridge.modbus_port))
    )
    mbap = b"\x00\x04\x00\x00\x00\x00"
    req = mbap  # no payload after MBAP
    await bridge._udp_write_read(req)
    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent = bridge.udp_transport.sent[-1][0]
    assert sent is not None
