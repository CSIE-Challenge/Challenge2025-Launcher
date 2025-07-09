extends Control

const GITHUB_API := "https://api.github.com/repos/HyperSoWeak/test-release/releases/latest"
const SAVE_DIR := "GameBuilds"
const GAME_NAME := "Challenge2025"
const MAX_RETRY := 1

var version: String
var executable_name: String
var executable_path: String
var dots := 0
var launch_retry_count := 0
var asset_url := ""

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
		return "macos.app"
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
		if asset["name"] == executable_name:
			asset_url = asset["browser_download_url"]
			break

	if asset_url == "":
		_message("No matching asset found: " + executable_name)
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

	_message("Download complete")
	_launch_game()


func _launch_game():
	_message("Launching game with version: " + version)

	if not FileAccess.file_exists(executable_path):
		_message("Executable not found at: " + executable_path)
		return

	if OS.has_feature("linux") or OS.has_feature("macos"):
		OS.execute("chmod", ["+x", executable_path])

	var result := OS.execute(executable_path, ["--version"])
	printerr("Executable check result: ", result)

	if result == 0:
		OS.create_process(executable_path, ["--quiet"])
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


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_timer_timeout() -> void:
	dots = (dots + 1) % 6
	dots_label.text = ".".repeat(dots)
