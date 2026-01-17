import asyncio
import pytest


def hexbytes(s: str) -> bytes:
    return bytes.fromhex(s.replace(" ", ""))


UDP_COMMON_CFG = {
    "set_client_address": "set>server={IP_ADDRESS}:{PORT};",
    "set_client_address_response": "rsp>server=1;",
    "byte_mapping": "{SEQ}0102{LEN+3}FF{ID}{PAYLOAD}{CRC}",
    "reverse_byte_mapping": "{SEQ}0000{LEN-3}{ID}{PAYLOAD}",
}


TEST_VECTORS = [
    (
        {},
        hexbytes("00 01 00 00 00 07 04 05 03 13 89 00 01"),
        hexbytes("00 01 01 02 00 0a ff 04 05 03 13 89 00 01 50 e0"),
        hexbytes("00 01 01 02 00 09 ff 04 05 03 02 00 00 49 84"),
        hexbytes("00 01 00 00 00 06 04 05 03 02 00 00"),
    ),
    (
        {},
        hexbytes("00 02 00 00 00 07 04 05 03 13 8a 00 01"),
        hexbytes("00 02 01 02 00 0a ff 04 05 03 13 8a 00 01 a0 e0"),
        hexbytes("00 02 01 02 00 09 ff 04 05 03 02 00 00 49 84"),
        hexbytes("00 02 00 00 00 06 04 05 03 02 00 00"),
    ),
    (
        {},
        hexbytes("00 04 00 00 00 07 04 05 03 13 8c 00 01"),
        hexbytes("00 04 01 02 00 0a ff 04 05 03 13 8c 00 01 40 e1"),
        hexbytes("00 04 01 02 00 09 ff 04 05 03 02 00 01 88 44"),
        hexbytes("00 04 00 00 00 06 04 05 03 02 00 01"),
    ),
    (
        {},
        hexbytes("00 22 00 00 00 07 04 05 03 13 9e 00 01"),
        hexbytes("00 22 01 02 00 0a ff 04 05 03 13 9e 00 01 e0 e4"),
        hexbytes("00 22 01 02 00 09 ff 04 05 03 02 00 32 c8 51"),
        hexbytes("00 22 00 00 00 06 04 05 03 02 00 32"),
    ),
]


@pytest.mark.asyncio
@pytest.mark.parametrize(
    "udp_cfg,tcp_request,expected_udp_request,udp_response,expected_tcp_response",
    TEST_VECTORS,
)
async def test_udp_translation_with_preflight_and_gateway(
    bridge_factory, udp_cfg, tcp_request, expected_udp_request, udp_response, expected_tcp_response
):
    # Merge common settings into per-vector udp_cfg
    merged_cfg = dict(UDP_COMMON_CFG)
    merged_cfg.update(udp_cfg or {})
    bridge = bridge_factory(merged_cfg)

    # Replace the udp_transport with a mock that captures sendto calls and
    # injects the device response after the actual request is sent.
    class MockTransport:
        def __init__(self):
            self.calls = []

        def sendto(self, data, addr=None):
            # record the send
            self.calls.append((bytes(data), addr))
            # If this is the second send (index 1) — actual request after preflight — inject response
            if len(self.calls) == 2:
                # push the expected device response into the protocol queue
                asyncio.get_event_loop().call_soon_threadsafe(
                    bridge.udp_protocol.queue.put_nowait,
                    (expected_tcp_response[6:], (bridge.modbus_host, bridge.modbus_port)),
                )

    bridge.udp_transport = MockTransport()

    # Provide preflight response that matches set_client_address_response
    await bridge.udp_protocol.queue.put((b"rsp>server=1;", (bridge.modbus_host, bridge.modbus_port)))

    # Start the translation but don't await it yet — it will perform preflight, send UDP, then wait for response
    task = asyncio.create_task(bridge._udp_write_read(tcp_request))

    # Wait until the MockTransport has recorded the preflight and the actual request (2 sends)
    for _ in range(50):
        if len(bridge.udp_transport.calls) >= 2:
            break
        await asyncio.sleep(0.01)
    else:
        task.cancel()
        pytest.fail("UDP request was not sent (preflight/actual send missing)")

    # Inspect the actual sent UDP payload (the second send)
    sent_payload, _addr = bridge.udp_transport.calls[1]

    # Compare the exact UDP bytes that were sent
    assert sent_payload == expected_udp_request, (
        f"sent UDP payload mismatch\nexpected: {expected_udp_request.hex()}\nactual:   {sent_payload.hex()}"
    )

    # Await the translation result (TCP reply reconstructed by the bridge)
    tcp_reply = await asyncio.wait_for(task, timeout=1)

    # The reconstructed TCP reply should match the expected TCP response exactly
    assert tcp_reply == expected_tcp_response, (
        f"tcp reply mismatch\nexpected: {expected_tcp_response.hex()}\nactual:   {tcp_reply.hex()}"
    )

