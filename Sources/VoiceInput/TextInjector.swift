import Cocoa

class TextInjector {
    private var originalInputSourceID: String?
    
    private typealias TISCreateInputSourceListFunc = @convention(c) (CFDictionary?, Bool) -> Unmanaged<CFArray>?
    private typealias TISGetInputSourcePropertyFunc = @convention(c) (UnsafeMutableRawPointer, UnsafeRawPointer) -> UnsafeMutableRawPointer?
    private typealias TISSelectInputSourceFunc = @convention(c) (UnsafeMutableRawPointer) -> OSStatus
    
    private lazy var tisCreateInputSourceList: TISCreateInputSourceListFunc? = {
        guard let sym = dlsym(dlopen("/System/Library/Frameworks/Carbon.framework/Carbon", RTLD_NOW), "TISCreateInputSourceList") else { return nil }
        return unsafeBitCast(sym, to: TISCreateInputSourceListFunc.self)
    }()
    
    private lazy var tisGetInputSourceProperty: TISGetInputSourcePropertyFunc? = {
        guard let sym = dlsym(dlopen("/System/Library/Frameworks/Carbon.framework/Carbon", RTLD_NOW), "TISGetInputSourceProperty") else { return nil }
        return unsafeBitCast(sym, to: TISGetInputSourcePropertyFunc.self)
    }()
    
    private lazy var tisSelectInputSource: TISSelectInputSourceFunc? = {
        guard let sym = dlsym(dlopen("/System/Library/Frameworks/Carbon.framework/Carbon", RTLD_NOW), "TISSelectInputSource") else { return nil }
        return unsafeBitCast(sym, to: TISSelectInputSourceFunc.self)
    }()
    
    private lazy var kTISPropertySelectedKey: CFString? = {
        getTISConstant("kTISPropertySelectedKey")
    }()
    
    private lazy var kTISPropertyInputSourceLanguagesKey: CFString? = {
        getTISConstant("kTISPropertyInputSourceLanguagesKey")
    }()
    
    private lazy var kTISPropertyInputSourceIDKey: CFString? = {
        getTISConstant("kTISPropertyInputSourceIDKey")
    }()
    
    private func getTISConstant(_ name: String) -> CFString? {
        guard let sym = dlsym(dlopen("/System/Library/Frameworks/Carbon.framework/Carbon", RTLD_NOW), name) else { return nil }
        return unsafeBitCast(sym, to: CFString.self)
    }
    
    func injectText(_ text: String) {
        NSLog("[VoiceInput] injectText called with: '\(text)'")
        
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        // 直接设置剪贴板并粘贴，不处理输入法切换
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        NSLog("[VoiceInput] Clipboard set, simulating Cmd+V...")
        
        usleep(100000)
        simulateCmdV()
        usleep(100000)
        
        // 恢复剪贴板
        if let old = oldContents {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.setString(old, forType: .string)
            }
        }
        
        NSLog("[VoiceInput] injectText completed")
    }
    
    private func simulateCmdV() {
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Cmd down
        let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        cmdDown?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
        
        usleep(50000)
        
        // V down
        let vDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        
        usleep(50000)
        
        // V up
        let vUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        vUp?.post(tap: .cghidEventTap)
        
        usleep(50000)
        
        // Cmd up
        let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)
        cmdUp?.post(tap: .cghidEventTap)
    }
}