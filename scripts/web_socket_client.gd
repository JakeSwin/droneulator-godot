extends Node

# --- Configuration ---
const WS_URL := "ws://localhost:8000/ws"
const RECONNECT_INTERVAL := 2.0 

# --- Signals ---
# You can emit this signal from other scripts to send data through this node
signal request_send_message(data: Dictionary)

# --- State ---
var socket := WebSocketPeer.new()
var latest_state: Dictionary = {}
var connected := false
var time_since_last_attempt := 0.0
# NEW: Prevent buffer overflow
var image_sent_this_frame := false

@onready var drone = $"../drone"
@onready var status_indicator = get_node("../Ui/HBoxContainer/VBoxContainer2/Panel/ConnectionStatus")

# --- Colors ---
const COLOR_CONNECTED = Color.GREEN
const COLOR_CONNECTING = Color.YELLOW
const COLOR_DISCONNECTED = Color.RED

func _ready():
	# --- NEW: Increase Buffer Sizes for Large Images ---
	# 16777216 bytes = 16 MB buffer
	socket.outbound_buffer_size = 16777216
	socket.inbound_buffer_size = 16777216
	
	# Optional but recommended: increase the queue size so multiple
	# frames don't get dropped if the network blips.
	socket.max_queued_packets = 2048
	# ---------------------------------------------------
	
	if status_indicator:
		status_indicator.color = COLOR_DISCONNECTED
	attempt_connection()

func _process(delta):
	image_sent_this_frame = false
	
	socket.poll()
	var state = socket.get_ready_state()
	_update_ui_state(state)
	
	match state:
		WebSocketPeer.STATE_OPEN:
			if not connected:
				print("Connected!")
				connected = true
				time_since_last_attempt = 0.0
				
				# --- NEW: SEND HANDSHAKE ---
				# This tells the Python server: "I am the Godot Game"s
				var handshake_msg = {
					"type": "handshake", 
					"source": "godot"
				}
				send_message(handshake_msg)
				print("Handshake sent.")
				# ---------------------------
			
			_handle_incoming_packets()
			_update_drone_transform()

		WebSocketPeer.STATE_CLOSED:
			if connected:
				print("Disconnected.")
				connected = false
			
			time_since_last_attempt += delta
			if time_since_last_attempt >= RECONNECT_INTERVAL:
				attempt_connection()
				
		WebSocketPeer.STATE_CONNECTING, WebSocketPeer.STATE_CLOSING:
			pass

# --- 1. The Sending Function ---
# Call this directly: get_node("NetworkController").send_message({...})
# Or via signal: emit_signal("request_send_message", {...})
func send_message(data: Dictionary):
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_warning("Cannot send message: Socket is not open.")
		return
		
	var json_text = JSON.stringify(data)
	socket.send_text(json_text)

# Add more functions here to send UAV camera textures

# --- 2. Connection Logic ---
func attempt_connection():
	time_since_last_attempt = 0.0
	print("Connecting to %s..." % WS_URL)
	if status_indicator: status_indicator.color = COLOR_CONNECTING
	socket.connect_to_url(WS_URL)

func _update_ui_state(state):
	if not status_indicator: return
	match state:
		WebSocketPeer.STATE_OPEN: status_indicator.color = COLOR_CONNECTED
		WebSocketPeer.STATE_CONNECTING: status_indicator.color = COLOR_CONNECTING
		_: status_indicator.color = COLOR_DISCONNECTED

# Differentiate between state packet and request for images
func _handle_incoming_packets():
	while socket.get_available_packet_count() > 0:
		var raw = socket.get_packet().get_string_from_utf8()
		var parsed = JSON.parse_string(raw)
		
		if typeof(parsed) == TYPE_DICTIONARY:
			match parsed.get("type"):
				"state":
					latest_state = parsed.get("data", {})
				"request_image":
					_send_image_frame(parsed.get("camera", "rgb"))
				"restart":
					# If you want Godot to do anything on restart, handle it here
					pass

func _send_image_frame(camera_type: String):
	if image_sent_this_frame:
		return # Silently ignore the duplicate request
	
	image_sent_this_frame = true
	
	var viewport_node_name = ""
	var use_lossless = false
	var is_raw_float = false
	
	match camera_type:
		"rgb":
			viewport_node_name = "RGBViewport"
		"seg":
			viewport_node_name = "SegViewport"
			use_lossless = true # Use PNG for segmentation to avoid artifacting
		"depth":
			viewport_node_name = "DepthSensorViewport"
			is_raw_float = true # Send 32-bit raw bytes
		_:
			push_error("Unknown camera type requested: ", camera_type)
			return

	var viewport = drone.get_node_or_null(viewport_node_name)
	if not viewport:
		push_error("Viewport not found: ", viewport_node_name)
		return

	var img = viewport.get_texture().get_image()
	var data_to_send: PackedByteArray

	if is_raw_float:
		# For robotics depth: convert to 1-channel 32-bit float and send raw bytes
		img.convert(Image.FORMAT_RF)
		data_to_send = img.get_data()
	elif use_lossless:
		# For segmentation: PNG preserves exact pixel IDs
		data_to_send = img.save_png_to_buffer()
	else:
		# For standard RGB: JPEG is fine and fast
		data_to_send = img.save_jpg_to_buffer(0.8)

	#socket.send(data_to_send, WebSocketPeer.WRITE_MODE_BINARY)
	socket.put_packet(data_to_send)

func _update_drone_transform():
	if latest_state.has("x") and latest_state.has("q"):
		var pos := Vector3(latest_state["x"][0], latest_state["x"][2], -latest_state["x"][1])
		var rot := Quaternion(latest_state["q"][0], latest_state["q"][2], latest_state["q"][1], latest_state["q"][3])
		drone.global_position = pos
		drone.quaternion = rot
