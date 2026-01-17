import asyncio
import pytest



@pytest.mark.asyncio
async def test_udp_mbap_map_moves_bytes(bridge_factory):
    bridge = bridge_factory({"mbap_map": [{"mbap_offset": 4, "target_offset": 0, "length": 2}]})

    mbap = b"\xAA\xBB\x00\x00\x00\x03"
    request = mbap + b"\x01\x03\x00"

    # Device echo response (payload only)
    device_resp = b"\x01\x03\x00"
    await bridge.udp_protocol.queue.put((device_resp, (bridge.modbus_host, bridge.modbus_port)))

    await bridge._udp_write_read(request)

    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent_payload, addr = bridge.udp_transport.sent[0]
    # mbap_map should copy MBAP length bytes (offset 4, length 2) into start of udp payload
    assert sent_payload[0:2] == mbap[4:6]


@pytest.mark.asyncio
async def test_udp_preflight_set_client_address(bridge_factory):
    cfg = {
        "modbus": {
            "url": "udp://127.0.0.1:1502",
            "udp": {
                "set_client_address": "010203",
                "set_client_address_response": "OK",
            },
            "timeout": 1,
        },
        "listen": {"bind": ":502"},
    }

    bridge = bridge_factory({"set_client_address": "010203", "set_client_address_response": "OK"})

    # Preflight response must match 'OK' string
    await bridge.udp_protocol.queue.put((b"OK", (bridge.modbus_host, bridge.modbus_port)))

    mbap = b"\x00\x01\x00\x00\x00\x03"
    request = mbap + b"\x11\x03\x00\x01"

    # Should not raise and should return a TCP-style reply
    await bridge._udp_write_read(request)


@pytest.mark.asyncio
async def test_udp_response_strip_routing_after_unit(bridge_factory):
    cfg = {
        "modbus": {
            "url": "udp://127.0.0.1:1502",
            "udp": {"response_strip_routing_after_unit": True},
            "timeout": 1,
        },
        "listen": {"bind": ":502"},
    }

    bridge = bridge_factory({"response_strip_routing_after_unit": True})

    mbap = b"\x00\x01\x00\x00\x00\x03"
    request = mbap + b"\x11\x03\x00\x01"

    # Device returns unit + routing byte + payload
    device_resp = b"\x11\xEE\x03\x02\x00\x2A"
    await bridge.udp_protocol.queue.put((device_resp, (bridge.modbus_host, bridge.modbus_port)))

    tcp_reply = await bridge._udp_write_read(request)

    # After stripping routing byte, reconstructed TCP reply data should start with unit then function
    assert tcp_reply[6] == 0x11
    assert tcp_reply[7] == 0x03


@pytest.mark.asyncio
async def test_udp_udp_payload_hex_override(bridge_factory):
    cfg = {
        "modbus": {
            "url": "udp://127.0.0.1:1502",
            "udp": {"udp_payload_hex": "0A0B0C"},
            "timeout": 1,
        },
        "listen": {"bind": ":502"},
    }

    bridge = bridge_factory({"udp_payload_hex": "0A0B0C"})

    mbap = b"\x00\x01\x00\x00\x00\x03"
    request = mbap + b"\x11\x03\x00\x01"

    device_resp = b"\x11\x03\x02\x00\x2A"
    await bridge.udp_protocol.queue.put((device_resp, (bridge.modbus_host, bridge.modbus_port)))

    await bridge._udp_write_read(request)

    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent_payload, addr = bridge.udp_transport.sent[0]
    assert sent_payload.startswith(b"\x0A\x0B\x0C")


@pytest.mark.asyncio
async def test_udp_strip_mbap_for_udp_disabled_keeps_mbap(bridge_factory):
    cfg = {
        "modbus": {
            "url": "udp://127.0.0.1:1502",
            "udp": {"strip_mbap_for_udp": False},
            "timeout": 1,
        },
        "listen": {"bind": ":502"},
    }

    bridge = bridge_factory({"strip_mbap_for_udp": False}, url="udp://127.0.0.1:1502", bind=":502")

    mbap = b"\xAA\xBB\x00\x00\x00\x03"
    request = mbap + b"\x01\x03\x00"

    device_resp = b"\x01\x03\x00"
    await bridge.udp_protocol.queue.put((device_resp, (bridge.modbus_host, bridge.modbus_port)))

    await bridge._udp_write_read(request)

    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent_payload, addr = bridge.udp_transport.sent[0]
    # If strip_mbap_for_udp is False, the sent payload should contain the MBAP header
    assert sent_payload.startswith(mbap)
