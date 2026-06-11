import SwiftUI
import AppKit

// MARK: - Visual Effect View (Frosted Glass Backdrop)
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - SwiftUI Translation View (Lightweight macOS Look Up Style)
struct TranslationView: View {
    let word: String
    let contextText: String
    let googleTranslation: String?
    let aiTranslation: String?
    let isAIEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Word and badge header
            HStack(alignment: .firstTextBaseline) {
                Text(word)
                    .font(.system(.headline, design: .default))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(Localization.string(for: "app_name"))
                    .font(.system(.caption2, design: .default))
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Merged Translation Content Box
            VStack(alignment: .leading, spacing: 8) {
                if let google = googleTranslation {
                    // Display Google result
                    Text(google)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if isAIEnabled {
                        if let ai = aiTranslation {
                            Divider()
                                .opacity(0.5)
                            
                            ScrollView(.vertical, showsIndicators: true) {
                                Text(LocalizedStringKey(ai))
                                    .font(.system(.subheadline, design: .default))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxHeight: 180) // Constrain scroll height for lightness
                        } else {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                    .scaleEffect(0.7)
                                Text(Localization.string(for: "ai_loading"))
                                    .font(.system(.caption, design: .default))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                } else {
                    // Initial loading state (with spinner)
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.8)
                        Text(isAIEnabled ? Localization.string(for: "loading_ai") : Localization.string(for: "loading_translating"))
                            .font(.system(.caption, design: .default))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(12)
        .frame(width: 300) // Compact lightweight width
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.15), lineWidth: 0.5)
        )
        .textSelection(.enabled) // Enable user text selection and copy
    }
}

// MARK: - NSPanel Controller for Floating Window
class TranslationPanel: NSPanel {
    
    static let shared = TranslationPanel()
    
    private var hostingView: NSHostingView<TranslationView>?
    private var dismissTimer: Timer?
    private var isMouseLocked = false
    private var lockMonitorTimer: Timer?
    
    private init() {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 300, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
    }
    
    /// Display the floating window at target screen position
    func show(at screenPoint: NSPoint, word: String, context: String, googleResult: String?, aiResult: String?, aiEnabled: Bool) {
        cancelDismissRequest()
        isMouseLocked = false
        
        let view = TranslationView(
            word: word,
            contextText: context,
            googleTranslation: googleResult,
            aiTranslation: aiResult,
            isAIEnabled: aiEnabled
        )
        
        if let existing = hostingView {
            existing.removeFromSuperview()
        }
        
        let newHostingView = NSHostingView(rootView: view)
        self.contentView = newHostingView
        self.hostingView = newHostingView
        
        // Dynamically compute layout height using SwiftUI auto layout sizing
        let fittingSize = newHostingView.fittingSize
        let finalWidth: CGFloat = 300
        let finalHeight = fittingSize.height
        
        // Calculate offset position
        let xPos = screenPoint.x + 10
        let yPos = screenPoint.y - finalHeight - 10
        
        // Adjust bounds so it stays within active screen boundaries
        var finalX = xPos
        var finalY = yPos
        
        if let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(screenPoint, $0.frame, false) }) {
            let screenFrame = activeScreen.frame
            
            if finalX + finalWidth > screenFrame.maxX {
                finalX = screenPoint.x - finalWidth - 10
            }
            if finalY < screenFrame.minY {
                finalY = screenPoint.y + 10
            }
        }
        
        self.setFrame(CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight), display: true)
        
        if !self.isVisible {
            self.alphaValue = 0
            self.orderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.12
                self.animator().alphaValue = 1.0
            }
        }
    }
    
    /// Requests dismissal of the panel with a smart delay
    func requestDismiss() {
        guard self.isVisible else { return }
        
        // If the mouse is already inside and locked, keep it visible
        if isMouseLocked {
            let mouseLocation = NSEvent.mouseLocation
            if self.frame.contains(mouseLocation) {
                return
            } else {
                isMouseLocked = false // Mouse left the panel area
            }
        }
        
        dismissTimer?.invalidate()
        
        var ticks = 0
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            if self.isVisible && self.frame.contains(mouseLocation) {
                // Mouse entered the panel! Lock it and cancel dismiss.
                self.isMouseLocked = true
                timer.invalidate()
                self.dismissTimer = nil
                
                self.startLockMonitoring()
                return
            }
            
            ticks += 1
            if ticks >= 6 { // 6 * 0.05s = 0.3s
                timer.invalidate()
                self.dismissTimer = nil
                self.dismiss()
            }
        }
    }
    
    private func startLockMonitoring() {
        lockMonitorTimer?.invalidate()
        lockMonitorTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            let mouseLocation = NSEvent.mouseLocation
            if !self.isVisible || !self.frame.contains(mouseLocation) {
                self.isMouseLocked = false
                timer.invalidate()
                self.lockMonitorTimer = nil
                self.dismiss()
            }
        }
    }
    
    /// Cancels any pending dismiss request
    func cancelDismissRequest() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        lockMonitorTimer?.invalidate()
        lockMonitorTimer = nil
    }
    
    /// Fade out and hide the floating window (Immediate dismissal)
    func dismiss() {
        cancelDismissRequest()
        isMouseLocked = false
        
        guard self.isVisible && self.alphaValue > 0 else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            self.animator().alphaValue = 0.0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
    
    /// Update the SwiftUI content inside the visible window
    func update(word: String, context: String, googleResult: String?, aiResult: String?, aiEnabled: Bool) {
        guard self.isVisible else { return }
        
        let view = TranslationView(
            word: word,
            contextText: context,
            googleTranslation: googleResult,
            aiTranslation: aiResult,
            isAIEnabled: aiEnabled
        )
        self.hostingView?.rootView = view
        
        // Resize panel dynamically in case content size changed
        if let fittingSize = self.hostingView?.fittingSize {
            var currentFrame = self.frame
            let newHeight = fittingSize.height
            let heightDifference = currentFrame.size.height - newHeight
            
            currentFrame.origin.y += heightDifference
            currentFrame.size.height = newHeight
            self.setFrame(currentFrame, display: true, animate: true)
        }
    }
}
