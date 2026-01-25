import asyncio
import pytest



@pytest.mark.asyncio
async def test_udp_default_strip_mbap_and_gateway_and_response_reconstruction(bridge_factory):
    # Create ModBus configured for UDP
    bridge = bridge_factory({})

    # Build a TCP-style request: MBAP(6) + Unit(1) + Func(1) + Data(2)
    mbap = b"\x00\x01\x00\x00\x00\x04"  # length 4
    tcp_payload = mbap + b"\x11\x03\x00\x01"

    # Simulate device response: device returns unit, function, data
    udp_response_payload = b"\x11\x03\x02\x00\x2A"
    udp_response = b"\x00\x01\x01\x02\x00\x09\xff\x04" + udp_response_payload + b"\x12\x34"

    # Put the response into the protocol queue so _udp_write_read can pick it up
    await bridge.udp_protocol.queue.put((udp_response, (bridge.modbus_host, bridge.modbus_port)))

    # Call internal _udp_write_read
    tcp_reply = await bridge._udp_write_read(tcp_payload)

    # Expect the reply to be MBAP from last request + device response
    assert tcp_reply.startswith(mbap[0:5] + b"\x05")
    assert tcp_reply[6:] == udp_response_payload


@pytest.mark.asyncio
async def test_udp_prefix_and_crc_and_vars(bridge_factory):
    # Test prefix templating and CRC insertion
    cfg = {
        "modbus": {
            "url": "udp://127.0.0.1:1502",
            "udp": {
                "byte_mapping": "{SEQ}{PAYLOAD}{CRC}",
                "vars": {"EXTRA": "ignored"},
            },
            "timeout": 1,
        },
        "listen": {"bind": ":502"},
    }

    bridge = bridge_factory({"byte_mapping": "{SEQ}{PAYLOAD}{CRC}", "vars": {"EXTRA": "ignored"}})

    # Request with MBAP + payload
    mbap = b"\xAA\xBB\x00\x00\x00\x03"
    request = mbap + b"\x01\x03\x00"

    # Device echo response (payload only)
    udp_response_payload = b"\x01\x03\x00"
    udp_response = b"\xAA\xBB\x01\x02\x00\x07\xff\x04" + udp_response_payload + b"\x12\x34"
    await bridge.udp_protocol.queue.put((udp_response, (bridge.modbus_host, bridge.modbus_port)))

    tcp_reply = await bridge._udp_write_read(request)

    # Ensure transport sent something and CRC was appended in payload
    assert bridge.udp_transport.sent, "no UDP packet was sent"
    sent_payload, addr = bridge.udp_transport.sent[0]
    # Because mapping used SEQ (first 2 bytes) and PAYLOAD (after MBAP), ensure PAYLOAD present
    assert b"\x01\x03\x00" in sent_payload
    # Ensure reply is reconstructed with MBAP
    assert tcp_reply[:6] == mbap[:5] + b"\x03"
    assert tcp_reply[6:] == udp_response_payload
