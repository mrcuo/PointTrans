import Cocoa
import CoreGraphics

class HotKeyHandler {
    static let shared = HotKeyHandler()
    
    private var timer: Timer?
    private var lastMouseLocation: NSPoint = .zero
    private var hoverDuration: Double = 0.0
    private var lastTranslatedLocation: NSPoint = .zero
    
    /// Triggered when the mouse is stationary with modifier key held down for the delay duration.
    var onHoverTriggered: ((NSPoint) -> Void)?
    
    /// Triggered when the mouse moves while modifier key is held.
    var onMouseMoved: (() -> Void)?
    
    /// Triggered when the modifier key is released.
    var onModifierReleased: (() -> Void)?
    
    private init() {}
    
    func startMonitoring() {
        stopMonitoring() // Avoid duplicates
        // Check mouse and key status every 100ms system-wide
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMouseAndKeyStatus()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Queries the global, system-wide hardware state of the modifier keys using CoreGraphics.
    /// This is 100% reliable even when the application is running in the background.
    private func isModifierKeyPressed() -> Bool {
        let modifierName = UserDefaults.standard.string(forKey: "modifierKey") ?? "command"
        
        switch modifierName.lowercased() {
        case "option":
            // Virtual Key Codes for Option: 58 (Left Option), 61 (Right Option)
            return CGEventSource.keyState(.combinedSessionState, key: 58) ||
                   CGEventSource.keyState(.combinedSessionState, key: 61)
        case "control":
            // Virtual Key Codes for Control: 59 (Left Control), 62 (Right Control)
            return CGEventSource.keyState(.combinedSessionState, key: 59) ||
                   CGEventSource.keyState(.combinedSessionState, key: 62)
        case "shift":
            // Virtual Key Codes for Shift: 56 (Left Shift), 60 (Right Shift)
            return CGEventSource.keyState(.combinedSessionState, key: 56) ||
                   CGEventSource.keyState(.combinedSessionState, key: 60)
        default:
            // Default: command
            // Virtual Key Codes for Command: 55 (Left Command), 54 (Right Command)
            return CGEventSource.keyState(.combinedSessionState, key: 55) ||
                   CGEventSource.keyState(.combinedSessionState, key: 54)
        }
    }
    
    private func checkMouseAndKeyStatus() {
        let isEnabled = UserDefaults.standard.bool(forKey: "translationEnabled")
        guard isEnabled else { return }
        
        let isModifierPressed = isModifierKeyPressed()
        let currentMouseLoc = NSEvent.mouseLocation
        
        if isModifierPressed {
            // Check distance moved since last tick
            let distance = abs(currentMouseLoc.x - lastMouseLocation.x) + abs(currentMouseLoc.y - lastMouseLocation.y)
            
            if distance < 3.0 { // Small threshold to ignore micro-movements of hand
                hoverDuration += 0.1
                
                // Get delay setting (default 0.3 seconds)
                var delaySetting = UserDefaults.standard.double(forKey: "hoverDelay")
                if delaySetting <= 0 {
                    delaySetting = 0.3
                }
                
                if hoverDuration >= delaySetting {
                    // Check distance from last translation event to avoid re-triggering on same word
                    let distFromLastTranslation = abs(currentMouseLoc.x - lastTranslatedLocation.x) + abs(currentMouseLoc.y - lastTranslatedLocation.y)
                    
                    if distFromLastTranslation > 15.0 {
                        lastTranslatedLocation = currentMouseLoc
                        onHoverTriggered?(currentMouseLoc)
                    }
                }
            } else {
                // Mouse moved
                hoverDuration = 0.0
                onMouseMoved?()
            }
        } else {
            // Key released
            if hoverDuration > 0 {
                hoverDuration = 0.0
            }
            // Reset translation location on key release so the user can immediately re-translate the same word
            lastTranslatedLocation = .zero
            onModifierReleased?()
        }
        
        lastMouseLocation = currentMouseLoc
    }
    
    func resetLastTranslationLocation() {
        lastTranslatedLocation = .zero
    }
}
