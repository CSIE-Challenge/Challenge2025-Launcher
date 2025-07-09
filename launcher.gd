extends Control

const GITHUB_API = "https://api.github.com/repos/HyperSoWeak/test-release/releases/latest"
const SAVE_DIR = "GameBuilds/Challenge2025"
const GAME_NAME = "Challenge2025"

@onready var status_label := $CenterContainer/Label
@onready var req := $HTTPRequest


func _message(message: String):
	status_label.text = message
	print(message)


func _ready():
	_message("Checking for updates...")
	_fetch_latest_release()


func _get_platform_suffix() -> String:
	if OS.has_feature("windows"):
		return "windows.exe"
	if OS.has_feature("linux"):
		return "linux.x86_64"
	if OS.has_feature("macos"):
		return "macos.app"
	return ""


func _get_download_path() -> String:
	return SAVE_DIR + "/" + GAME_NAME + "_" + _get_platform_suffix()


func _fetch_latest_release():
	req.request_completed.connect(_on_request_completed)
	req.request(GITHUB_API)


func _on_request_completed(_result, response_code, _headers, body):
	if response_code != 200:
		_message("Failed to fetch release info: " + str(response_code))
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if data == null or not data.has("assets") or not data.has("tag_name"):
		_message("Invalid release data")
		return

	var tag = data["tag_name"]
	var expected_name = "%s_%s_%s" % [tag, GAME_NAME, _get_platform_suffix()]
	var asset_url = ""

	for asset in data["assets"]:
		if asset["name"] == expected_name:
			asset_url = asset["browser_download_url"]
			break

	if asset_url == "":
		_message("No matching asset found: " + expected_name)
		return

	_download_executable(asset_url)


func _download_executable(url: String):
	_message("Downloading...")
	print("Download URL: " + url)
	print("Save path: " + _get_download_path())
	req.download_file = SAVE_DIR
	req.request_completed.disconnect(_on_request_completed)
	req.request_completed.connect(_on_download_finished)
	req.request(url)


func _on_download_finished(_result, response_code, _headers, _body):
	_message("Download finished with response code: " + str(response_code))

	if response_code != 200:
		_message("Download failed: " + str(response_code))
		return

	_message("Download complete. Launching game...")
	_launch_game()


func _launch_game():
	if not FileAccess.file_exists(SAVE_DIR):
		_message("Executable not found at: " + SAVE_DIR)
		return

	if OS.has_feature("linux") or OS.has_feature("macos"):
		OS.execute("chmod", ["+x", SAVE_DIR])

	OS.create_process(SAVE_DIR, [])
	get_tree().quit()
