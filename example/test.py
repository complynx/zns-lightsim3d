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


import threading

def send_universe(universe, num_threads, num_fixtures, shift_step, delay, port, barrier):
    shift = 1
    fps = 0
    start = time.time()
    last_fps = 0
    i = 0
    while True:
        fps += 1
        i+=1
        if i % num_threads == universe % num_threads:
            print(f"Universe {universe} fps: {last_fps}        ", end="\r")
        led_data = create_rainbow(num_fixtures * 3, shift)
        send_artnet_packet(led_data, universe, port=port)
        shift = (shift + shift_step) % (num_fixtures * 3)
        time.sleep(delay)
        if time.time()-start > 1:
            start = time.time()
            last_fps = fps
            fps = 0
        barrier.wait()

import argparse

def main():
    parser = argparse.ArgumentParser(description='Test fixtures')
    parser.add_argument('-n','--num_fixtures', type=int, default=int(512/3), help='Number of lighting fixtures')
    parser.add_argument('-S','--universe_start', type=int, default=8, help='DMX universe beginning')
    parser.add_argument('-F','--universe_finish', type=int, default=55, help='DMX universe end')
    parser.add_argument('-s','--shift_step', type=int, default=1, help='Steps to shift')
    parser.add_argument('-p','--port', type=int, default=6454, help='Art-Net port (or starting port if with -m)')
    parser.add_argument('-d','--delay', type=float, default=0.01, help='Delay between each step of the shifting process (in seconds)')
    parser.add_argument('-m','--multiple_ports', action='store_true', help='use multiple ports (each universe port = Art-Net port + universe number)')

    args = parser.parse_args()

    num_fixtures = args.num_fixtures
    universe_start = args.universe_start
    universe_end = args.universe_finish
    shift_step = args.shift_step
    delay = args.delay

    # Your code goes here

    print(f"Sending to Universes {universe_start}-{universe_end} rainbow of {num_fixtures} RGB fixtures with delay of {delay}s")

    NUM_THREADS = universe_end-universe_start+1
    barrier = threading.Barrier(NUM_THREADS)

    threads = []
    for universe in range(universe_start, universe_end+1):
        port = args.port
        if args.multiple_ports:
            port += universe
        t = threading.Thread(
            target=send_universe,
            daemon=True,
            args=(
                universe,
                NUM_THREADS,
                num_fixtures,
                shift_step,
                delay,
                port,
                barrier
            )
        )
        threads.append(t)
        t.start()

    try:
        time.sleep(100000000)
    except Exception as e:
        print(e)

if __name__ == '__main__':
    main()


