import asyncio
import pytest

from modbus_proxy import ModBus


@pytest.mark.asyncio
async def test_udp_preflight_timeout(bridge_factory):
    # preflight expected but no response -> None returned
    bridge = bridge_factory({"set_client_address": "AA", "set_client_address_response": "OK", "set_client_timeout": 0.01},)
    # no response put into queue
    mbap = b"\x00\x01\x00\x00\x00\x01"
    req = mbap + b"\x01\x03"
    resp = await bridge._udp_write_read(req)
    assert resp is None


@pytest.mark.asyncio
async def test_udp_malformed_prefix_template(bridge_factory):
    # unknown token should be ignored and not crash
    bridge = bridge_factory({"byte_mapping": "{UNKNOWN}{PAYLOAD}{CRC}"})
    await bridge.udp_protocol.queue.put((b"\x01\x03\x02\x00\x2A", (bridge.modbus_host, bridge.modbus_port)))
    mbap = b"\x00\x02\x00\x00\x00\x03"
    req = mbap + b"\x01\x03\x00"
    res = await bridge._udp_write_read(req)
    assert res is not None


@pytest.mark.asyncio
async def test_udp_crc_matches_expected(bridge_factory):
    # Using PAYLOAD+CRC prefix should append crc over payload
    bridge = bridge_factory({"byte_mapping": "{PAYLOAD}{CRC}"})
    bridge.udp_protocol.queue.put_nowait((b"\x01\x03\x02\x00\x2A", (bridge.modbus_host, bridge.modbus_port)))
    mbap = b"\x00\x03\x00\x00\x00\x03"
    req = mbap + b"\x01\x03\x00"
    await bridge._udp_write_read(req)
    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent = bridge.udp_transport.sent[-1][0]
    # last two bytes are CRC (little endian)
    assert len(sent) >= 2
    payload = sent[:-2]
    crc = int.from_bytes(sent[-2:], byteorder='little')
    # Ensure computed crc equals _crc
    assert crc == bridge._crc(payload)


@pytest.mark.asyncio
async def test_udp_gateway_insertion_edge(bridge_factory):
    # If payload is too short, gateway should be inserted safely
    bridge = bridge_factory({})
    bridge.udp_protocol.queue.put_nowait((b"\x01\x03\x02\x00\x2A", (bridge.modbus_host, bridge.modbus_port)))
    mbap = b"\x00\x04\x00\x00\x00\x00"
    req = mbap  # no payload after MBAP
    await bridge._udp_write_read(req)
    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent = bridge.udp_transport.sent[-1][0]
    assert sent is not None
