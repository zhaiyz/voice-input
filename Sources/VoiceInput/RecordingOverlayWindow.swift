import Cocoa

class RecordingOverlayWindow: NSPanel {
    private var visualEffectView: NSVisualEffectView!
    private var waveformView: WaveformView!
    private var transcriptLabel: NSTextField!
    private var transcriptConstraint: NSLayoutConstraint!
    
    private var currentTranscript = ""
    private var isShowing = false
    
    init() {
        let capsuleWidth: CGFloat = 320
        let capsuleHeight: CGFloat = 56
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let x = (screenFrame.width - capsuleWidth) / 2
        let y = screenFrame.height - capsuleHeight - 120
        
        super.init(
            contentRect: NSRect(x: x, y: y, width: capsuleWidth, height: capsuleHeight),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        setupWindow()
        setupContentView()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .statusBar
        isMovableByWindowBackground = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hasShadow = true
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        standardWindowButton(.closeButton)?.isHidden = true
        standardWindowButton(.miniaturizeButton)?.isHidden = true
        standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    private func setupContentView() {
        visualEffectView = NSVisualEffectView()
        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 28
        visualEffectView.layer?.masksToBounds = true
        
        contentView?.addSubview(visualEffectView)
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: contentView!.topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: contentView!.leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: contentView!.trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: contentView!.bottomAnchor)
        ])
        
        waveformView = WaveformView(frame: NSRect(x: 0, y: 0, width: 44, height: 32))
        visualEffectView.addSubview(waveformView)
        waveformView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            waveformView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
            waveformView.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: 44),
            waveformView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        transcriptLabel = NSTextField(labelWithString: "正在聆听...")
        transcriptLabel.font = NSFont.systemFont(ofSize: 14, weight: .regular)
        transcriptLabel.textColor = .white
        transcriptLabel.alignment = .left
        transcriptLabel.isEditable = false
        transcriptLabel.isSelectable = false
        transcriptLabel.isBordered = false
        transcriptLabel.drawsBackground = false
        transcriptLabel.lineBreakMode = .byTruncatingTail
        transcriptLabel.cell?.truncatesLastVisibleLine = true
        
        visualEffectView.addSubview(transcriptLabel)
        transcriptLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let leadingConstraint = transcriptLabel.leadingAnchor.constraint(equalTo: waveformView.trailingAnchor, constant: 12)
        let trailingConstraint = transcriptLabel.trailingAnchor.constraint(lessThanOrEqualTo: visualEffectView.trailingAnchor, constant: -16)
        let centerYConstraint = transcriptLabel.centerYAnchor.constraint(equalTo: visualEffectView.centerYAnchor)
        
        transcriptConstraint = transcriptLabel.widthAnchor.constraint(equalToConstant: 160)
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            centerYConstraint,
            transcriptConstraint
        ])
    }
    
    func showWithAnimation() {
        guard !isShowing else { return }
        isShowing = true
        
        let initialWidth: CGFloat = 220
        let capsuleHeight: CGFloat = 56
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let x = (screenFrame.width - initialWidth) / 2
        let y = screenFrame.height - capsuleHeight - 120
        
        setFrame(NSRect(x: x, y: y, width: initialWidth, height: capsuleHeight), display: true)
        
        // 重置文本
        transcriptLabel.stringValue = "正在聆听..."
        
        // 设置初始状态
        alphaValue = 1.0
        
        // 缩放动画
        contentView?.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1)
        
        // 显示窗口
        orderFrontRegardless()
        makeKey()
        
        // 执行缩放动画
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            self.contentView?.layer?.transform = CATransform3DIdentity
        })
    }
    
    func hideWithAnimation(completion: @escaping () -> Void) {
        guard isShowing else {
            completion()
            return
        }
        isShowing = false
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.allowsImplicitAnimation = true
            self.contentView?.layer?.transform = CATransform3DMakeScale(0.8, 0.8, 1)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
            completion()
        })
    }
    
    func updateWaveform(rms: Double) {
        guard isShowing else { return }
        NSLog("[VoiceInput] updateWaveform: rms=\(String(format: "%.4f", rms)), isShowing=\(isShowing)")
        waveformView.setRMS(rms)
    }
    
    func updateTranscript(_ text: String) {
        guard isShowing else { return }
        currentTranscript = text
        transcriptLabel.stringValue = text.isEmpty ? "正在聆听..." : text
        
        let size = (text as NSString).size(withAttributes: [.font: transcriptLabel.font ?? NSFont.systemFont(ofSize: 14)])
        let newWidth = max(160, min(560, size.width + 20))
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            transcriptConstraint.animator().constant = newWidth
            
            let currentFrame = self.frame
            let targetWidth = max(220, min(780, 220 + newWidth - 160))
            let delta = targetWidth - currentFrame.width
            let newFrame = NSRect(
                x: currentFrame.origin.x - delta / 2,
                y: currentFrame.origin.y,
                width: targetWidth,
                height: currentFrame.height
            )
            self.animator().setFrame(newFrame, display: true)
        }
    }
}