extends Control

const GITHUB_API := "https://api.github.com/repos/CSIE-Challenge/Challenge2025/releases/latest"
const SAVE_DIR := "GameBuilds"
const AI_PATH := "GameBuilds/ai.zip"
const GAME_NAME := "Challenge2025"
const MAX_RETRY := 1

var version: String
var executable_name: String
var executable_path: String
var dots := 0
var launch_retry_count := 0
var asset_url := ""
var ai_url := ""

@onready var status_label := $CenterContainer/Label
@onready var req := $HTTPRequest
@onready var timer := $Timer
@onready var dots_label := $Dots


func _message(message: String):
	status_label.text = message
	print(message)


func _ready():
	var dir := DirAccess.open(".")
	if not dir.dir_exists(SAVE_DIR):
		dir.make_dir_recursive(SAVE_DIR)
		_message("Created save directory: " + SAVE_DIR)

	_fetch_latest_release()


func _get_platform_suffix() -> String:
	if OS.has_feature("windows"):
		return "windows.exe"
	if OS.has_feature("linux"):
		return "linux.x86_64"
	if OS.has_feature("macos"):
		return "macos.zip"
	return ""


func _get_existing_executable_name() -> String:
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return ""

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(_get_platform_suffix()):
			return file_name
		file_name = dir.get_next()
	dir.list_dir_end()

	return ""


func _delete_existing_executable(file_name: String):
	var full_path = SAVE_DIR + "/" + file_name
	if FileAccess.file_exists(full_path):
		DirAccess.remove_absolute(full_path)
		_message("Deleted old version: " + file_name)


func _get_download_path() -> String:
	return SAVE_DIR + "/" + GAME_NAME + "_" + _get_platform_suffix()


func _fetch_latest_release():
	_message("Checking for updates...")
	req.request_completed.connect(_on_fetch_completed)
	req.request(GITHUB_API)


func _on_fetch_completed(_result, response_code, _headers, body):
	if response_code != 200:
		_message("Failed to fetch release data: " + str(response_code))
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or not data.has("assets") or not data.has("tag_name"):
		_message("Invalid release data")
		return

	var tag = data["tag_name"]
	version = tag
	executable_name = "%s_%s_%s" % [version, GAME_NAME, _get_platform_suffix()]
	executable_path = "%s/%s" % [SAVE_DIR, executable_name]

	for asset in data["assets"]:
		if asset["name"] == "ai.zip":
			ai_url = asset["browser_download_url"]
		elif asset["name"] == executable_name:
			asset_url = asset["browser_download_url"]

	if asset_url == "":
		_message("No matching asset found: " + executable_name)
		return

	if ai_url == "":
		_message("No API found in release assets.")
		return

	var existing = _get_existing_executable_name()
	if existing == executable_name:
		_message("You already have the latest version: " + version)
		_launch_game()
	else:
		if existing != "":
			_delete_existing_executable(existing)
		_download_executable()


func _download_executable():
	_message("Downloading latest version: " + executable_name)
	req.download_file = executable_path
	req.request_completed.disconnect(_on_fetch_completed)
	req.request_completed.connect(_on_download_completed)
	req.request(asset_url)


func _on_download_completed(_result, response_code, _headers, _body):
	if response_code != 200:
		_message("Download failed: " + str(response_code))
		return

	if OS.has_feature("macos"):
		OS.execute("unzip", [executable_path])
		OS.execute("mv", ["Challenge2025.app", SAVE_DIR])

	_message("Download complete")
	_download_ai()


func _download_ai():
	_message("Downloading API...")
	req.download_file = AI_PATH
	req.request_completed.disconnect(_on_download_completed)
	req.request_completed.connect(_on_download_ai_completed)
	req.request(ai_url)


func _on_download_ai_completed(_result, response_code, _headers, _body):
	if response_code != 200:
		_message("API download failed: " + str(response_code))
		return

	_message("API download complete")
	_extract_ai_model()
	_launch_game()


func _extract_ai_model():
	_message("Extracting API from: " + AI_PATH)
	_extract_all_from_zip(AI_PATH, SAVE_DIR)
	DirAccess.remove_absolute(AI_PATH)
	_message("API extracted successfully")


func _extract_all_from_zip(path: String, to: String) -> void:
	var reader = ZIPReader.new()
	reader.open(path)

	var root_dir = DirAccess.open(to)

	var files = reader.get_files()
	for file_path in files:
		if file_path.ends_with("/"):
			root_dir.make_dir_recursive(file_path)
			continue

		root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
		var file = FileAccess.open(
			root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE
		)
		var buffer = reader.read_file(file_path)
		file.store_buffer(buffer)


func _launch_game():
	_message("Launching game with version: " + version)

	if not _check_python_version():
		_message("Python 3.12 or newer is required to run this game.")
		return

	if not FileAccess.file_exists(executable_path):
		_message("Executable not found at: " + executable_path)
		return

	var app_path = executable_path

	if OS.has_feature("macos"):
		app_path = SAVE_DIR + "/Challenge2025.app/Contents/MacOS/Challenge2025"
		OS.execute("xattr", ["-rd", "com.apple.quarantine", app_path])

	if OS.has_feature("linux"):
		OS.execute("chmod", ["+x", app_path])

	var result := OS.execute(app_path, ["--version"])
	print("Executable check result: ", result)

	if result == 0:
		OS.create_process(app_path, ["--quiet"])
		_message("Game launched. Goodbye!")
		get_tree().quit()
	else:
		if launch_retry_count < MAX_RETRY:
			_message("Failed to launch game, will retry by redownloading...")
			launch_retry_count += 1
			_delete_existing_executable(executable_name)
			_download_executable()
		else:
			_message("Failed to launch after retry. Error code: %d" % result)


func _check_python_version() -> bool:
	var out := []
	var result := OS.execute("python3", ["--version"], out)
	if result != 0 or out.is_empty():
		_message("Python3 not found or failed to run.")
		return false

	printerr(out)

	var version_str = out[0].strip_edges()
	print("Detected Python version:", version_str)

	var regex = RegEx.new()
	regex.compile("Python\\s+(\\d+)\\.(\\d+)\\.(\\d+)")
	var match = regex.search(version_str)

	if match:
		var major = int(match.get_string(1))
		var minor = int(match.get_string(2))

		if major > 3 or (major == 3 and minor >= 12):
			_message("Python version is sufficient: " + version_str)
			return true

		_message("Python 3.12 or newer is required.")
		return false

	_message("Could not parse Python version.")
	return false


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_timer_timeout() -> void:
	dots = (dots + 1) % 6
	dots_label.text = ".".repeat(dots)
