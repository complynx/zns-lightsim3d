extends Node3D

# Path to the config file
@export_range(0,10) var EMISSION_ENERGY = 2
@export var ARTNET_PORT: int = 6454
@onready var tf = get_node("../CanvasLayer/transform_controller")

const USE_THREADS = true

var universes = {}
var udp_server = UDPServer.new()
var current_file_path
var universe0 = []

var universe_threads = {}
var running = false
var universe_threads_mutex = Mutex.new()

func _ready():
	setup_udp_server()
	if USE_THREADS:
		start_threads()
	
	universe0 = [
		$"../Lisoborie/fixtures/mh/MH1",
		$"../Lisoborie/fixtures/mh/MH2",
		$"../Lisoborie/fixtures/mh/MH3",
		$"../Lisoborie/fixtures/mh/MH4",
		$"../Lisoborie/fixtures/bars/B1",
		$"../Lisoborie/fixtures/bars/B2",
		$"../Lisoborie/fixtures/bars/B3",
		$"../Lisoborie/fixtures/bars/B4",
		$"../Lisoborie/fixtures/bars/B5",
		$"../Lisoborie/fixtures/bars/B6",
		$"../Lisoborie/fixtures/bars/B7",
		$"../Lisoborie/fixtures/bars/B8",
		$"../Lisoborie/fixtures/pars/P1",
		$"../Lisoborie/fixtures/pars/P2",
		$"../Lisoborie/fixtures/pars/P3",
		$"../Lisoborie/fixtures/pars/P4",
		$"../Lisoborie/fixtures/pars/P5",
		$"../Lisoborie/fixtures/pars/P6",
		$"../Lisoborie/fixtures/pars/P7",
		$"../Lisoborie/fixtures/pars/P8"
	]
	var zeros = PackedByteArray()
	zeros.resize(512)
	zeros.fill(0)
	for fixture in universe0:
		fixture.parse_full_dmx(zeros)

func setup_udp_server():
	udp_server.listen(ARTNET_PORT)
	
func _exit_tree():
	if USE_THREADS:
		stop_threads()
	udp_server.stop()
	
func create_light_based_on_data(data):
	var xyz = Vector3(float(data[2]), float(data[3]), float(data[4]))
	if tf.for_lights:
		xyz = tf.transform_inversed * xyz
	if data.size() > 11:
		if int(data[11]) == 1:
			return MiniPar.new(float(data[10]), xyz.x, xyz.y, xyz.z, float(data[5]), float(data[6]))
		elif int(data[11]) == 2:
			return DirectionalLed.new(float(data[10]), xyz.x, xyz.y, xyz.z, float(data[5]), float(data[6]))
	return SimpleLed.new(float(data[10]), xyz.x, xyz.y, xyz.z)

func load_config_and_generate_cubes(path):
	current_file_path = path
	var file = FileAccess.open(path, FileAccess.READ)

	var i = 0
	file.get_line() # skip first line
	
	if USE_THREADS:
		stop_threads()
		for child in get_children():
			remove_child(child)
		universes = {}
		start_threads()
	
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			var data = line.split(",")
			
			var universe = int(data[0])
			var channel = int(data[1])
			if not universes.has(universe):
				universes[universe] = []
			
			if USE_THREADS:
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
			
			var light = create_light_based_on_data(data)
			light.set_color(Color(float(data[7])/255., float(data[8])/255., float(data[9])/255., 1))
			light.set_name("light.{}".format([i]))
			light.DMX_Channel = channel
			light.DMX_Universe = universe
			universes[universe].append(light)

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
		
		parse_one_packet(latest_packet, universe)
	print("Finished universe thread: ", universe)

func parse_one_packet(latest_packet, universe):
	if latest_packet.size()<18:
		return
	var dmx_data = latest_packet.slice(18) # DMX data
	if universe == 0:
		for fixture in universe0:
			fixture.parse_full_dmx(dmx_data)
	
	if universes.has(universe):
		var universe_data = universes[universe]
		for fixture in universe_data:
			fixture.parse_full_dmx(dmx_data)

func poll_udp_packets():
	udp_server.poll()
	while udp_server.is_connection_available():
		var peer: PacketPeerUDP = udp_server.take_connection()
		while peer.get_available_packet_count() > 0:
			var packet = peer.get_packet()
			if packet.size() >= 18:
				if packet.get_string_from_ascii() == "Art-Net":
					var universe = decode_u16le(packet, 14)
					if USE_THREADS:
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
					else:
						parse_one_packet(packet, universe)

func _input(event):
	if event is InputEventKey:
		if Input.get_action_strength("open_file"):
			var fd = $"../CanvasLayer/FileDialog"
			if not fd.is_visible():
				fd.popup_centered()
		elif Input.get_action_strength("reload_file"):
			load_config_and_generate_cubes(current_file_path)
		if Input.get_action_strength("open_transform_control"):
			var fd = $"../CanvasLayer/transform_controller"
			if not fd.is_visible():
				fd.popup_centered()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	poll_udp_packets()


func _on_bar_toggled(button_pressed):
	$"../Lisoborie/Bar lights/Lamp 1/light".set_visible(button_pressed)
	$"../Lisoborie/Bar lights/Lamp 2/light".set_visible(button_pressed)
	$"../Lisoborie/Bar lights/Lamp 3/light".set_visible(button_pressed)
	$"../Lisoborie/Bar lights/Lamp 4/light".set_visible(button_pressed)
	$"../Lisoborie/Bar lights/Lamp 5/light".set_visible(button_pressed)

func _on_kitchen_toggled(button_pressed):
	$"../Lisoborie/Kitchen light".set_visible(button_pressed)


func _on_main_toggled(button_pressed):
	$"../Lisoborie/Ceiling lamps/lights".set_visible(button_pressed)
