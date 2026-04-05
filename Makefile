APP_NAME = VoiceInput
BUILD_DIR = .build
CONFIGURATION = release
APP_BUNDLE = $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME).app

.PHONY: build run install clean

build:
	@echo "Building $(APP_NAME)..."
	swift build -c $(CONFIGURATION) --product $(APP_NAME)
	@echo "Creating app bundle..."
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(BUILD_DIR)/$(CONFIGURATION)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	@printf '<?xml version="1.0" encoding="UTF-8"?>\n<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n<plist version="1.0">\n<dict>\n\t<key>CFBundleName</key>\n\t<string>VoiceInput</string>\n\t<key>CFBundleIdentifier</key>\n\t<string>com.voiceinput.app</string>\n\t<key>CFBundleVersion</key>\n\t<string>1.0</string>\n\t<key>CFBundleShortVersionString</key>\n\t<string>1.0.0</string>\n\t<key>CFBundleExecutable</key>\n\t<string>VoiceInput</string>\n\t<key>CFBundlePackageType</key>\n\t<string>APPL</string>\n\t<key>LSUIElement</key>\n\t<true/>\n\t<key>NSMicrophoneUsageDescription</key>\n\t<string>Voice Input needs access to your microphone to record speech.</string>\n\t<key>NSSpeechRecognitionUsageDescription</key>\n\t<string>Voice Input uses speech recognition to convert your speech to text.</string>\n\t<key>NSAppleEventsUsageDescription</key>\n\t<string>Voice Input needs to simulate keyboard events to paste text.</string>\n</dict>\n</plist>\n' > $(APP_BUNDLE)/Contents/Info.plist
	@echo "App bundle created at $(APP_BUNDLE)"

run: build
	@echo "Running $(APP_NAME)..."
	open $(APP_BUNDLE)

install: build
	@echo "Installing $(APP_NAME) to /Applications..."
	@cp -R $(APP_BUNDLE) /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)
	@echo "Clean complete."
