import SwiftUI
import AppKit

// MARK: - Visual Effect View (Frosted Glass)
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

// MARK: - SwiftUI Translation View
struct TranslationView: View {
    let word: String
    let contextText: String
    let googleTranslation: String?
    let aiTranslation: String?
    let isAIEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Word Title Header
            HStack(alignment: .lastTextBaseline) {
                Text(word)
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(Localization.string(for: "app_name"))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.primary.opacity(0.06))
                    .cornerRadius(4)
            }
            
            Divider()
                .opacity(0.4)
            
            // Google Translation Section
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .foregroundColor(.blue)
                        .font(.footnote)
                    Text(Localization.string(for: "quick_trans"))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
                
                if let gTrans = googleTranslation {
                    Text(gTrans)
                        .font(.system(.body, design: .default))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ProgressView()
                        .controlSize(.small)
                        .scaleEffect(0.8)
                }
            }
            
            // AI Translation Section (conditional)
            if isAIEnabled {
                Divider()
                    .opacity(0.4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                            .font(.footnote)
                        Text(Localization.string(for: "ai_trans"))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                    
                    if let aiTrans = aiTranslation {
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(LocalizedStringKey(aiTrans))
                                .font(.system(.subheadline, design: .default))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .scaleEffect(0.8)
                            Text(Localization.string(for: "ai_loading"))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(16)
        .frame(width: 340)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - NSPanel Controller for Floating Window
class TranslationPanel: NSPanel {
    
    static let shared = TranslationPanel()
    
    private var hostingView: NSHostingView<TranslationView>?
    
    private init() {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 340, height: 260),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .statusBar // Float over menus and full screen apps
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
    }
    
    /// Display the floating window at target screen position
    func show(at screenPoint: NSPoint, word: String, context: String, googleResult: String?, aiResult: String?, aiEnabled: Bool) {
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
        let finalWidth: CGFloat = 340
        let finalHeight = fittingSize.height
        
        // Calculate offset position
        let xPos = screenPoint.x + 12
        let yPos = screenPoint.y - finalHeight - 12
        
        // Adjust bounds so it stays within active screen boundaries
        var finalX = xPos
        var finalY = yPos
        
        if let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(screenPoint, $0.frame, false) }) {
            let screenFrame = activeScreen.frame
            
            if finalX + finalWidth > screenFrame.maxX {
                finalX = screenPoint.x - finalWidth - 12
            }
            if finalY < screenFrame.minY {
                finalY = screenPoint.y + 12
            }
        }
        
        self.setFrame(CGRect(x: finalX, y: finalY, width: finalWidth, height: finalHeight), display: true)
        
        if !self.isVisible {
            self.alphaValue = 0
            self.orderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                self.animator().alphaValue = 1.0
            }
        }
    }
    
    /// Fade out and hide the floating window
    func dismiss() {
        guard self.isVisible && self.alphaValue > 0 else { return }
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
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
            
            // Adjust y coordinate to grow downwards and keep top-left corner stable
            currentFrame.origin.y += heightDifference
            currentFrame.size.height = newHeight
            self.setFrame(currentFrame, display: true, animate: true)
        }
    }
}
