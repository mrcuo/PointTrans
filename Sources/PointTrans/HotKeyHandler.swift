import Cocoa

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
        // Check mouse status every 100ms (0.1s is responsive and light on CPU)
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.checkMouseAndKeyStatus()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkMouseAndKeyStatus() {
        let isEnabled = UserDefaults.standard.bool(forKey: "translationEnabled")
        // Default to enabled if not set
        if UserDefaults.standard.object(forKey: "translationEnabled") == nil {
            UserDefaults.standard.set(true, forKey: "translationEnabled")
        }
        guard isEnabled || UserDefaults.standard.object(forKey: "translationEnabled") == nil else { return }
        
        // Read required modifier key configuration
        let modifierName = UserDefaults.standard.string(forKey: "modifierKey") ?? "command"
        let requiredFlag: NSEvent.ModifierFlags
        
        switch modifierName.lowercased() {
        case "option":
            requiredFlag = .option
        case "control":
            requiredFlag = .control
        case "shift":
            requiredFlag = .shift
        default:
            requiredFlag = .command
        }
        
        // Query system-wide modifier key flags globally
        let currentFlags = NSEvent.modifierFlags
        let isModifierPressed = currentFlags.contains(requiredFlag)
        
        // Query global mouse coordinates
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
            onModifierReleased?()
        }
        
        lastMouseLocation = currentMouseLoc
    }
    
    func resetLastTranslationLocation() {
        lastTranslatedLocation = .zero
    }
}
