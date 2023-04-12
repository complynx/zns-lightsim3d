import time
import colorsys
import socket
import struct

def create_rainbow(num_leds, shift, max_value=255):
    leds = [0]
    for i in range(num_leds):
        hue = (i + shift) % num_leds / float(num_leds)
        r, g, b = [int(c * max_value) for c in colorsys.hsv_to_rgb(hue, 1, 1)]
        leds.extend([r, g, b])
    return leds

def send_artnet_packet(data, universe, ip='127.0.0.1', port=6454):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    header = b'Art-Net\x00'
    opcode = 0x5000.to_bytes(2, 'little')
    protocol_version = (14).to_bytes(2, 'big')
    sequence = 0x00.to_bytes(1, 'big')
    physical = 0x00.to_bytes(1, 'big')
    uni = universe.to_bytes(2, 'little')
    # subuni = (universe & 0xFF).to_bytes(1, 'big')
    # net = ((universe >> 8) & 0xFF).to_bytes(1, 'big')
    length = len(data).to_bytes(2, 'big')

    artnet_packet = header + opcode + protocol_version + sequence + physical + uni + length + bytearray(data)
    sock.sendto(artnet_packet, (ip, port))
    sock.close()

def main():
    num_fixtures = 100  # Adjust this value to match the number of fixtures
    universe = 20
    shift_step = 1
    shift = 1
    delay = 0.1

    while True:
        led_data = create_rainbow(num_fixtures * 3, shift)
        send_artnet_packet(led_data, universe)
        time.sleep(delay)
        shift = (shift + shift_step) % (num_fixtures * 3)

if __name__ == '__main__':
    main()