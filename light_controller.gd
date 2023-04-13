extends Node3D

# Path to the config file
const EMISSION_ENERGY = 2
const ARTNET_PORT = 6454

var universes = {}
var udp_server = UDPServer.new()
var current_file_path
var universe0 = {}

var universe_threads = {}
var running = false
var universe_threads_mutex = Mutex.new()

func _ready():
	setup_udp_server()
	start_threads()
	universe0 = {
		1: $"../Lisoborie/fixtures/mh/MH1",
		14: $"../Lisoborie/fixtures/mh/MH2",
		27: $"../Lisoborie/fixtures/mh/MH3",
		40: $"../Lisoborie/fixtures/mh/MH4",
		53: $"../Lisoborie/fixtures/bars/B1",
		58: $"../Lisoborie/fixtures/bars/B2",
		63: $"../Lisoborie/fixtures/bars/B3",
		68: $"../Lisoborie/fixtures/bars/B4",
		73: $"../Lisoborie/fixtures/bars/B5",
		78: $"../Lisoborie/fixtures/bars/B6",
		83: $"../Lisoborie/fixtures/bars/B7",
		88: $"../Lisoborie/fixtures/bars/B8",
		93: $"../Lisoborie/fixtures/pars/P1",
		102: $"../Lisoborie/fixtures/pars/P2",
		111: $"../Lisoborie/fixtures/pars/P3",
		120: $"../Lisoborie/fixtures/pars/P4",
		129: $"../Lisoborie/fixtures/pars/P5",
		138: $"../Lisoborie/fixtures/pars/P6",
		147: $"../Lisoborie/fixtures/pars/P7",
		156: $"../Lisoborie/fixtures/pars/P8"
	}

func setup_udp_server():
	udp_server.listen(ARTNET_PORT)
	
func _exit_tree():
	stop_threads()
	udp_server.stop()

func load_config_and_generate_cubes(path):
	current_file_path = path
	var file = FileAccess.open(path, FileAccess.READ)

	var i = 0
	file.get_line() # skip first line
	
	stop_threads()
	for child in get_children():
		remove_child(child)
	universes = {}
	start_threads()
	
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			var data = line.split(",")
			
			var light = MeshInstance3D.new()
			var universe = int(data[0])
			var channel = int(data[1])
			if not universes.has(universe):
				universes[universe] = {}
			
			universe_threads_mutex.lock()
			if not universe_threads.has(universe):
				var thread_data = {
					"thread": Thread.new(),
					"packet_buffer": [],
					"mutex": Mutex.new(),
					"semaphore": Semaphore.new()
				}
				universe_threads[universe] = thread_data
				thread_data.thread.start(_thread_function.bind(universe))
			universe_threads_mutex.unlock()
			
			var lightMesh = BoxMesh.new()
			var size = float(data[8])
			lightMesh.set_size(Vector3(size,size,size))
			
			var emitter = create_emissive_material()
			universes[universe][channel] = emitter
			lightMesh.set_material(emitter)
			emitter.emission = Color(float(data[5])/255., float(data[6])/255., float(data[7])/255., 1)
			
			light.set_position(Vector3(float(data[2]), float(data[3]), float(data[4])))
			light.set_mesh(lightMesh)
			light.set_name("light.{}".format([i]))

			add_child(light)
			i += 1

	file.close()

func create_emissive_material():
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission_energy = EMISSION_ENERGY
	return material

func decode_u16le(packet, offset):
	var lsb = packet.decode_u8(offset) # Art-Net universe
	var msb = packet.decode_u8(offset+1) # Art-Net universe
	return (msb<<8) + lsb

func start_threads():
	universe_threads_mutex.lock()
	running = true
	var thread_data = {
		"thread": Thread.new(),
		"packet_buffer": [],
		"mutex": Mutex.new(),
		"semaphore": Semaphore.new()
	}
	thread_data.thread.start(_thread_function.bind(0))
	universe_threads[0] = thread_data
	universe_threads_mutex.unlock()

func stop_threads():
	universe_threads_mutex.lock()
	running = false
	for data in universe_threads.values():
		print("posting to semaphore")
		data.semaphore.post()
		data.thread.wait_to_finish()
		print("joined thread")
	universe_threads = {}
	universe_threads_mutex.unlock()

func _thread_function(universe):
	universe_threads_mutex.lock()
	var thread_data = universe_threads[universe]
	universe_threads_mutex.unlock()
	print("Started universe thread: ", universe)
	while running:
		thread_data.semaphore.wait()
		
		thread_data.mutex.lock()
		var packets = []
		if thread_data.packet_buffer.size() == 0:
			thread_data.mutex.unlock()
			continue
		
		var latest_packet = thread_data.packet_buffer.pop_front()
		var latest_sequence = latest_packet.decode_u8(12)
		while thread_data.packet_buffer.size() > 0:
			var packet = thread_data.packet_buffer.pop_front()
			var sequence = packet.decode_u8(12)
			
			if sequence >= latest_sequence or (latest_sequence - sequence) > 128:
				latest_packet = packet
				latest_sequence = sequence
		thread_data.mutex.unlock()
		
		if latest_packet.size()<18:
			continue
		var dmx_data = latest_packet.slice(18) # DMX data
		var dmx_data_size = dmx_data.size()
		if universe == 0:
			for channel in universe0:
				if dmx_data_size >= channel:
					universe0[channel].parse_dmx(dmx_data.slice(channel-1))
		
		if universes.has(universe):
			var universe_data = universes[universe]
			for channel in universe_data:
				if dmx_data_size > channel + 1:
					var R = dmx_data[channel-1]
					var G = dmx_data[channel]
					var B = dmx_data[channel+1]
					
					universe_data[channel].emission = Color(float(R)/255., float(G)/255., float(B)/255., 1)
	print("Finished universe thread: ", universe)

func poll_udp_packets():
	udp_server.poll()
	while udp_server.is_connection_available():
		var peer: PacketPeerUDP = udp_server.take_connection()
		while peer.get_available_packet_count() > 0:
			var packet = peer.get_packet()
			if packet.size() >= 18:
				if packet.get_string_from_ascii() == "Art-Net":
					var universe = decode_u16le(packet, 14)

					universe_threads_mutex.lock()
					if universe_threads.has(universe):
						var thread_data = universe_threads[universe]
						universe_threads_mutex.unlock()
						thread_data.mutex.lock()
						thread_data.packet_buffer.append(packet)
						thread_data.mutex.unlock()
						thread_data.semaphore.post()
						if not thread_data.thread.is_alive():
							print("oops, thread is dead")
					else:
						universe_threads_mutex.unlock()

func _input(event):
	if event is InputEventKey:
		if Input.get_action_strength("open_file"):
			var fd = $"../CanvasLayer/FileDialog"
			if not fd.is_visible():
				fd.popup_centered()
		elif Input.get_action_strength("reload_file"):
			load_config_and_generate_cubes(current_file_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	poll_udp_packets()
