import Cocoa

class GlobalEventMonitor {
    private var handler: (Bool) -> Void
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var checkTimer: Timer?
    private var lastFnState = false
    
    init(handler: @escaping (Bool) -> Void) {
        self.handler = handler
    }
    
    func start() {
        let trusted = AXIsProcessTrusted()
        NSLog("[VoiceInput] AXIsProcessTrusted: \(trusted)")
        
        if !trusted {
            requestAccessibilityPermission()
            return
        }
        
        createEventTap()
    }
    
    private func requestAccessibilityPermission() {
        NSLog("[VoiceInput] Requesting accessibility permission...")
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary
        let result = AXIsProcessTrustedWithOptions(options)
        NSLog("[VoiceInput] AXIsProcessTrustedWithOptions result: \(result)")
        
        if result {
            createEventTap()
        } else {
            startPermissionCheckTimer()
        }
    }
    
    private func startPermissionCheckTimer() {
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            let trusted = AXIsProcessTrusted()
            if trusted {
                timer.invalidate()
                self?.checkTimer = nil
                DispatchQueue.main.async {
                    self?.createEventTap()
                }
            }
        }
    }
    
    private func createEventTap() {
        let eventMask: CGEventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                
                let observer = Unmanaged<GlobalEventMonitor>.fromOpaque(refcon).takeUnretainedValue()
                let flags = event.flags
                let fnPressed = flags.contains(.maskSecondaryFn)
                
                // 只有状态变化时才通知
                if fnPressed != observer.lastFnState {
                    observer.lastFnState = fnPressed
                    NSLog("[VoiceInput] Fn state changed: \(fnPressed)")
                    
                    DispatchQueue.main.async {
                        observer.handler(fnPressed)
                    }
                }
                
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            NSLog("[VoiceInput] ERROR: Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        NSLog("[VoiceInput] Event tap created successfully!")
    }
    
    func stop() {
        checkTimer?.invalidate()
        checkTimer = nil
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
    }
    
    deinit {
        stop()
    }
}