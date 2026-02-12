extends Node

var server_pid: int = -1

func _ready():
	start_server()

func start_server():
	if server_pid == -1:
		var path = get_python_binary_path()
		print("Attempting to run server at: ", path)
		
		# Create a pipe to capture stdout/stderr (optional, helps debugging)
		# For production, you might want separate arguments or no output redirection
		server_pid = OS.create_process(path, [])
		
		if server_pid == -1:
			push_error("Failed to start Python server!")
	else:
		print("Server already running")

func _notification(what):
	# Detect when the game is closing (Alt+F4, Close Button, etc.)
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		kill_server()

func _exit_tree():
	# Backup cleanup
	kill_server() 

func kill_server():
	if server_pid != -1:
		print("Killing Python Server (PID: %s)..." % server_pid)
		OS.kill(server_pid)
		server_pid = -1

func get_python_binary_path() -> String:
	var binary_name = "main.exe" if OS.get_name() == "Windows" else "main"
	var dist_path = ""
	
	if OS.has_feature("editor"):
		# In Editor: "res://" maps to the project folder.
		# globalize_path works even if the folder is ignored.
		var project_root = ProjectSettings.globalize_path("res://")
		dist_path = project_root.path_join("dist").path_join("main").path_join(binary_name)
	else:
		# Exported: The "dist" folder will be next to the game executable
		var exe_dir = OS.get_executable_path().get_base_dir()
		dist_path = exe_dir.path_join("dist").path_join("main").path_join(binary_name)
		
	return dist_path
