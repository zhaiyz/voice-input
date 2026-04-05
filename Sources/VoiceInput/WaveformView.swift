import Cocoa

class WaveformView: NSView {
    private var bars: [NSView] = []
    private let maxHeight: CGFloat = 32
    private let weights: [Double] = [0.5, 0.8, 1.0, 0.75, 0.55]
    private var attackLevel: Double = 0
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        setupBars()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        setupBars()
    }
    
    private func setupBars() {
        let barWidth: CGFloat = 4
        let barSpacing: CGFloat = 3
        let barCount = 5
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * barSpacing
        let startX = (bounds.width - totalWidth) / 2
        
        for i in 0..<barCount {
            let bar = NSView()
            bar.wantsLayer = true
            bar.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.9).cgColor
            bar.layer?.cornerRadius = 2
            
            let x = startX + CGFloat(i) * (barWidth + barSpacing)
            bar.frame = NSRect(x: x, y: (maxHeight - 4) / 2, width: barWidth, height: 4)
            addSubview(bar)
            bars.append(bar)
        }
    }
    
    func setRMS(_ rms: Double) {
        if rms > attackLevel {
            attackLevel = rms * 0.8 + attackLevel * 0.2
        } else {
            attackLevel = rms * 0.15 + attackLevel * 0.85
        }
        
        for i in 0..<bars.count {
            let weight = weights[i]
            let jitter = Double.random(in: -0.04...0.04)
            let value = max(0, min(1, attackLevel * weight + jitter))
            
            let minHeight: CGFloat = 4
            let targetHeight = max(minHeight, CGFloat(value) * maxHeight)
            let y = (maxHeight - targetHeight) / 2
            
            let bar = bars[i]
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.08
                context.allowsImplicitAnimation = true
                bar.animator().frame = NSRect(x: bar.frame.origin.x, y: y, width: bar.frame.width, height: targetHeight)
            }
        }
    }
}