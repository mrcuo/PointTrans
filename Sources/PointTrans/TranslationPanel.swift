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

// MARK: - Custom Champagne Gold Loading Spinner
struct GoldSpinner: View {
    @State private var isAnimating = false
    
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color(red: 197/255, green: 168/255, blue: 128/255), lineWidth: 1.5)
            .frame(width: 14, height: 14)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(Animation.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                    self.isAnimating = true
                }
            }
    }
}

// MARK: - SwiftUI Translation View (Oxford Legacy Design)
struct TranslationView: View {
    let word: String
    let contextText: String
    let googleTranslation: String?
    let aiTranslation: String?
    let isAIEnabled: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    // Theme Colors
    private let oxfordNavy = Color(red: 10/255, green: 25/255, blue: 47/255)
    private let champagneGold = Color(red: 197/255, green: 168/255, blue: 128/255)
    private let parchment = Color(red: 253/255, green: 251/255, blue: 247/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Word Title
            HStack(alignment: .lastTextBaseline) {
                Text(word)
                    .font(.custom("Georgia", size: 24))
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .light ? oxfordNavy : .white)
                
                Spacer()
                
                // Academic Badge
                Text(Localization.string(for: "app_name").uppercased())
                    .font(.custom("SFMono-Regular", size: 9))
                    .fontWeight(.bold)
                    .tracking(1.5)
                    .foregroundColor(champagneGold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(champagneGold.opacity(0.12))
                    .cornerRadius(3)
            }
            
            // Double-line Divider (Classic Academic Journal Detail)
            VStack(spacing: 1.5) {
                Divider().background(champagneGold.opacity(0.4))
                Divider().background(champagneGold.opacity(0.15))
            }
            
            // Google Translation Section
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed")
                        .foregroundColor(champagneGold)
                        .font(.system(size: 10, weight: .bold))
                    
                    Text(Localization.string(for: "quick_trans").uppercased())
                        .font(.custom("SFMono-Regular", size: 9))
                        .fontWeight(.bold)
                        .tracking(1.8)
                        .foregroundColor(champagneGold)
                }
                
                if let gTrans = googleTranslation {
                    Text(gTrans)
                        .font(.custom("Georgia", size: 15))
                        .foregroundColor(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    HStack(spacing: 8) {
                        GoldSpinner()
                        Text("Reading...")
                            .font(.custom("Georgia", size: 12).italic())
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            
            // AI Context Analysis Section
            if isAIEnabled {
                VStack(spacing: 1.5) {
                    Divider().background(champagneGold.opacity(0.25))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(champagneGold)
                            .font(.system(size: 10, weight: .bold))
                        
                        Text(Localization.string(for: "ai_trans").uppercased())
                            .font(.custom("SFMono-Regular", size: 9))
                            .fontWeight(.bold)
                            .tracking(1.8)
                            .foregroundColor(champagneGold)
                    }
                    
                    if let aiTrans = aiTranslation {
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(LocalizedStringKey(aiTrans))
                                .font(.system(size: 13, weight: .regular))
                                .lineSpacing(4)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        HStack(spacing: 8) {
                            GoldSpinner()
                            Text(Localization.string(for: "ai_loading"))
                                .font(.custom("Georgia", size: 12).italic())
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .padding(18)
        .frame(width: 350)
        .background(
            Group {
                if colorScheme == .dark {
                    ZStack {
                        VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        oxfordNavy.opacity(0.65)
                    }
                } else {
                    parchment
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(champagneGold.opacity(colorScheme == .light ? 0.7 : 0.45), lineWidth: 1.5)
        )
    }
}

// MARK: - NSPanel Controller for Floating Window
class TranslationPanel: NSPanel {
    
    static let shared = TranslationPanel()
    
    private var hostingView: NSHostingView<TranslationView>?
    
    private init() {
        super.init(
            contentRect: CGRect(x: 0, y: 0, width: 350, height: 280),
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
        let finalWidth: CGFloat = 350
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
            
            currentFrame.origin.y += heightDifference
            currentFrame.size.height = newHeight
            self.setFrame(currentFrame, display: true, animate: true)
        }
    }
}
