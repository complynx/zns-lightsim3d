extends Node3D

# Path to the config file
const EMISSION_ENERGY = 2
const ARTNET_PORT = 6454

var universes = {}
var udp_server = UDPServer.new()
var current_file_path
var universe0 = {}

func _ready():
	setup_udp_server()
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
	udp_server.stop()

func load_config_and_generate_cubes(path):
	current_file_path = path
	var file = FileAccess.open(path, FileAccess.READ)

	var i = 0
	file.get_line() # skip first line
	
	for child in get_children():
		remove_child(child)
	universes = {}
	
	while not file.eof_reached():
		var line = file.get_line()
		if not line.is_empty():
			var data = line.split(",")
			
			var light = MeshInstance3D.new()
			var universe = int(data[0])
			var channel = int(data[1])
			if not universes.has(universe):
				universes[universe] = {}
			
			var lightMesh = BoxMesh.new()
			var size = float(data[8])
			lightMesh.set_size(Vector3(size,size,size))
			
			var emitter = create_emissive_material()
			universes[universe][channel] = emitter
			lightMesh.set_material(emitter)
			set_color(emitter, int(data[5]), int(data[6]), int(data[7]))
			
			light.set_position(Vector3(float(data[2]), float(data[3]), float(data[4])))
			light.set_mesh(lightMesh)
			light.set_name("light.{}".format([i]))

			add_child(light)
			i += 1

	file.close()

func set_color(emitter,R,G,B):
	var color = Color(float(R)/255., float(G)/255., float(B)/255., 1)
	emitter.emission = color

func create_emissive_material():
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission_energy = EMISSION_ENERGY
	return material

func decode_u16le(packet, offset):
	var lsb = packet.decode_u8(offset) # Art-Net universe
	var msb = packet.decode_u8(offset+1) # Art-Net universe
	return (msb<<8) + lsb

func parse_artnet_packet(packet):
	var universe = decode_u16le(packet, 14)
	var dmx_data = packet.slice(18) # DMX data
	var dmx_data_size = dmx_data.size()
	if universe == 0:
		for channel in universe0:
			if dmx_data_size >= channel:
				universe0[channel].parse_dmx(dmx_data.slice(channel-1))
	
	if universes.has(universe):
		for channel in universes[universe]:
			if dmx_data_size > channel + 1:
				var R = dmx_data[channel-1]
				var G = dmx_data[channel]
				var B = dmx_data[channel+1]
				
				set_color(universes[universe][channel],R,G,B)

func poll_udp_packets():
	udp_server.poll() # Important!
	while udp_server.is_connection_available():
		var peer : PacketPeerUDP = udp_server.take_connection()
		while peer.get_available_packet_count()>0:
			var packet = peer.get_packet()
			if packet.size() > 0:
				if packet.get_string_from_ascii() == "Art-Net":
					parse_artnet_packet(packet)

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
