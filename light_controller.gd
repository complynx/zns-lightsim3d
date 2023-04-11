extends Node3D

# Path to the config file
const CONFIG_FILE = "res://lights.csv"
const LIGHT_SIZE = 0.01
const EMISSION_ENERGY = 2
const ARTNET_PORT = 6454

var universes = {}
var udp_server = UDPServer.new()

func _ready():
	load_config_and_generate_cubes(CONFIG_FILE)
	setup_udp_server()

func setup_udp_server():
	udp_server.listen(ARTNET_PORT)
	
func _exit_tree():
	udp_server.stop()

func load_config_and_generate_cubes(path):
	var file = FileAccess.open(path, FileAccess.READ)

	var i = 0
	file.get_line() # skip first line
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
			lightMesh.set_size(Vector3(LIGHT_SIZE,LIGHT_SIZE,LIGHT_SIZE))
			
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

func parse_artnet_packet(packet):
	var universe = packet.decode_u16(14) # Art-Net universe
	var dmx_data = packet.slice(18) # DMX data
	var dmx_data_size = dmx_data.size()

	if universes.has(universe):
		for channel in universes[universe]:
			if dmx_data_size > channel + 2:
				var R = dmx_data[channel]
				var G = dmx_data[channel+1]
				var B = dmx_data[channel+2]
				
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


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	poll_udp_packets()
