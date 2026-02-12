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

@onready var drone = $"../drone"
@onready var status_indicator = get_node("../Ui/HBoxContainer/VBoxContainer2/Panel/ConnectionStatus")

# --- Colors ---
const COLOR_CONNECTED = Color.GREEN
const COLOR_CONNECTING = Color.YELLOW
const COLOR_DISCONNECTED = Color.RED

func _ready():
	# Example: Connect our own signal to our own sender function
	# (Other nodes can connect to this signal, or call 'send_message' directly)
	request_send_message.connect(send_message)
	
	if status_indicator:
		status_indicator.color = COLOR_DISCONNECTED
	attempt_connection()

func _process(delta):
	socket.poll()
	var state = socket.get_ready_state()
	_update_ui_state(state)
	
	match state:
		WebSocketPeer.STATE_OPEN:
			if not connected:
				print("Connected!")
				connected = true
				time_since_last_attempt = 0.0
				
				# Optional: Send a "Hello" packet upon connection
				#send_message({"msg": "Hello from Godot", "type": "handshake"})
			
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

func _handle_incoming_packets():
	while socket.get_available_packet_count() > 0:
		var raw = socket.get_packet().get_string_from_utf8()
		var parsed = JSON.parse_string(raw)
		if typeof(parsed) == TYPE_DICTIONARY:
			latest_state = parsed

func _update_drone_transform():
	if latest_state.has("x") and latest_state.has("q"):
		var pos := Vector3(latest_state["x"][0], latest_state["x"][2], -latest_state["x"][1])
		var rot := Quaternion(latest_state["q"][0], latest_state["q"][2], latest_state["q"][1], latest_state["q"][3])
		drone.global_position = pos
		drone.quaternion = rot
