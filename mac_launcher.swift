import Foundation

// Determine the full path of the running launcher binary
let thisBinaryPath = CommandLine.arguments[0]
let launcherURL = URL(fileURLWithPath: thisBinaryPath).deletingLastPathComponent()

// Change working directory to the launcher binary's directory
FileManager.default.changeCurrentDirectoryPath(launcherURL.path)

// Use path relative to the binary's location
let appPath = launcherURL.appendingPathComponent("Applications/Challenge2025_Launcher_macos.app").path
let execPath = appPath + "/Contents/MacOS/Challenge2025-Launcher"

// 1. Remove quarantine attribute
let task1 = Process()
task1.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
task1.arguments = ["-rd", "com.apple.quarantine", appPath]

// 2. Run the actual binary
let task2 = Process()
task2.executableURL = URL(fileURLWithPath: execPath)

// Main functionality
do {
    try task1.run()
    task1.waitUntilExit()

    try task2.run()
    task2.waitUntilExit()
} catch {
    print("Error: \(error)")
}