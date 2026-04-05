import Cocoa
import AVFoundation

class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var fnKeyMonitor: GlobalEventMonitor!
    private var speechRecorder: SpeechRecorder!
    private var overlayWindow: RecordingOverlayWindow!
    private var textInjector: TextInjector!
    private var llmRefiner: LLMRefiner!
    private var settingsWindowController: NSWindowController?
    
    private var isRecording = false
    private var pendingText = ""
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        checkAccessibilityPermission()
        
        textInjector = TextInjector()
        llmRefiner = LLMRefiner()
        speechRecorder = SpeechRecorder { [weak self] text, isFinal in
            self?.onSpeechResult(text, isFinal: isFinal)
        }
        speechRecorder.onRMSUpdate = { [weak self] rms in
            self?.overlayWindow?.updateWaveform(rms: rms)
        }
        
        overlayWindow = RecordingOverlayWindow()
        
        setupMenuBar()
        startFnKeyMonitor()
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        if !trusted {
            let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        let menu = NSMenu()
        menu.delegate = self
        
        let languages = LanguageManager.shared.availableLanguages
        let currentLang = LanguageManager.shared.currentLanguage
        
        for lang in languages {
            let item = NSMenuItem(title: lang.displayName, action: #selector(languageSelected(_:)), keyEquivalent: "")
            item.representedObject = lang
            if lang.code == currentLang.code {
                item.state = .on
            }
            menu.addItem(item)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        let llmSubmenu = NSMenu(title: "LLM Refinement")
        let llmToggleItem = NSMenuItem(title: "Enable LLM Refinement", action: #selector(toggleLLM(_:)), keyEquivalent: "")
        llmToggleItem.state = UserDefaults.standard.bool(forKey: "llm_enabled") ? .on : .off
        llmSubmenu.addItem(llmToggleItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings(_:)), keyEquivalent: ",")
        llmSubmenu.addItem(settingsItem)
        
        let llmMainItem = NSMenuItem(title: "LLM Refinement", action: nil, keyEquivalent: "")
        llmMainItem.submenu = llmSubmenu
        menu.addItem(llmMainItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit VoiceInput", action: #selector(quitApp(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Voice Input")
        }
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let currentLang = LanguageManager.shared.currentLanguage
        for item in menu.items {
            if let lang = item.representedObject as? Language {
                item.state = lang.code == currentLang.code ? .on : .off
            }
        }
    }
    
    @objc private func languageSelected(_ sender: NSMenuItem) {
        if let lang = sender.representedObject as? Language {
            LanguageManager.shared.currentLanguage = lang
        }
    }
    
    @objc private func toggleLLM(_ sender: NSMenuItem) {
        let enabled = sender.state == .off
        sender.state = enabled ? .on : .off
        UserDefaults.standard.set(enabled, forKey: "llm_enabled")
    }
    
    @objc private func openSettings(_ sender: NSMenuItem) {
        if settingsWindowController == nil {
            let settingsVC = SettingsViewController()
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 200),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Settings"
            window.contentViewController = settingsVC
            window.center()
            settingsWindowController = NSWindowController(window: window)
        }
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
    
    private func startFnKeyMonitor() {
        fnKeyMonitor = GlobalEventMonitor { [weak self] fnPressed in
            self?.handleFnKey(fnPressed: fnPressed)
        }
        fnKeyMonitor.start()
    }
    
    private func handleFnKey(fnPressed: Bool) {
        if fnPressed && !isRecording {
            isRecording = true
            startRecording()
        } else if !fnPressed && isRecording {
            isRecording = false
            stopRecording()
        }
    }
    
    private func startRecording() {
        let currentLang = LanguageManager.shared.currentLanguage
        speechRecorder.startRecording(locale: currentLang.locale)
        overlayWindow?.showWithAnimation()
        pendingText = ""
    }
    
    private func stopRecording() {
        speechRecorder.stopRecording { [weak self] text in
            self?.pendingText = text
            self?.overlayWindow?.hideWithAnimation { [weak self] in
                if let text = self?.pendingText, !text.isEmpty {
                    self?.processAndInjectText(text)
                }
            }
        }
    }
    
    private func onSpeechResult(_ text: String, isFinal: Bool) {
        pendingText = text
        overlayWindow?.updateTranscript(text)
    }
    
    private func processAndInjectText(_ text: String) {
        NSLog("[VoiceInput] processAndInjectText: '\(text)'")
        
        let llmEnabled = UserDefaults.standard.bool(forKey: "llm_enabled")
        let apiKey = UserDefaults.standard.string(forKey: "llm_api_key") ?? ""
        let apiBase = UserDefaults.standard.string(forKey: "llm_api_base") ?? ""
        
        NSLog("[VoiceInput] LLM enabled: \(llmEnabled), apiKey set: \(!apiKey.isEmpty), apiBase set: \(!apiBase.isEmpty)")
        
        if llmEnabled && !apiKey.isEmpty && !apiBase.isEmpty {
            overlayWindow?.updateTranscript("Refining...")
            llmRefiner.refine(text: text) { [weak self] refinedText in
                NSLog("[VoiceInput] LLM callback: refinedText=\(refinedText ?? "(nil)")")
                let finalText = refinedText ?? text
                self?.textInjector.injectText(finalText)
            }
        } else {
            NSLog("[VoiceInput] Injecting text directly (LLM disabled or not configured)")
            textInjector.injectText(text)
        }
    }
}
