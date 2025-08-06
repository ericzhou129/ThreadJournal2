#!/usr/bin/swift

import Foundation

// Reset ThreadJournal settings to defaults
let defaults = UserDefaults.standard
let key = "ThreadJournal.UserSettings"

// Remove the corrupted settings
defaults.removeObject(forKey: key)
defaults.synchronize()

print("Settings have been reset to defaults")
print("Face ID will be OFF on next launch")