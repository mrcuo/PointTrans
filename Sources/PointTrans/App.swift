import Cocoa
import SwiftUI

@main
class PointTransApp {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    
    var statusItem: NSStatusItem?
    var enableMenuItem: NSMenuItem?
    var modeEnZhItem: NSMenuItem?
    var modeZhEnItem: NSMenuItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize default settings if not already set
        setupDefaultSettings()
        
        // Build status bar menu
        setupMenuBar()
        
        // Set up mouse and keyboard hotkey monitors
        setupEventMonitors()
        
        print("[App] PointTrans started successfully.")
    }
    
    private func setupDefaultSettings() {
        let preferredLang = Locale.preferredLanguages.first?.lowercased() ?? "en"
        let defaultMode = preferredLang.hasPrefix("zh") ? "en-to-zh" : "zh-to-en"
        
        let defaults: [String: Any] = [
            "translationEnabled": true,
            "modifierKey": "command",
            "hoverDelay": 0.3,
            "translationMode": defaultMode,
            "googleMirrorUrl": "",
            "aiEnabled": false,
            "aiProvider": "gemini",
            "geminiModel": "gemini-1.5-flash",
            "openaiEndpoint": "https://api.openai.com/v1/chat/completions",
            "openaiModel": "gpt-4o-mini"
        ]
        UserDefaults.standard.register(defaults: defaults)
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "translate", accessibilityDescription: Localization.string(for: "app_name"))
        }
        
        let menu = NSMenu()
        menu.delegate = self
        
        // 1. Enable translation toggle
        let enableItem = NSMenuItem(title: Localization.string(for: "menu_enable"), action: #selector(toggleTranslation), keyEquivalent: "")
        enableItem.target = self
        menu.addItem(enableItem)
        self.enableMenuItem = enableItem
        
        menu.addItem(NSMenuItem.separator())
        
        // 2. English -> Chinese translation mode
        let modeEnZh = NSMenuItem(title: Localization.string(for: "menu_mode_en_zh"), action: #selector(setModeEnZh), keyEquivalent: "")
        modeEnZh.target = self
        menu.addItem(modeEnZh)
        self.modeEnZhItem = modeEnZh
        
        // 3. Chinese -> English translation mode
        let modeZhEn = NSMenuItem(title: Localization.string(for: "menu_mode_zh_en"), action: #selector(setModeZhEn), keyEquivalent: "")
        modeZhEn.target = self
        menu.addItem(modeZhEn)
        self.modeZhEnItem = modeZhEn
        
        menu.addItem(NSMenuItem.separator())
        
        // 4. Settings Window
        let settingsItem = NSMenuItem(title: Localization.string(for: "menu_settings"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // 5. Quit App
        let quitItem = NSMenuItem(title: Localization.string(for: "menu_quit"), action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        let isEnabled = UserDefaults.standard.bool(forKey: "translationEnabled")
        enableMenuItem?.state = isEnabled ? .on : .off
        
        let mode = UserDefaults.standard.string(forKey: "translationMode") ?? "en-to-zh"
        modeEnZhItem?.state = mode == "en-to-zh" ? .on : .off
        modeZhEnItem?.state = mode == "zh-to-en" ? .on : .off
    }
    
    @objc private func toggleTranslation() {
        let isEnabled = UserDefaults.standard.bool(forKey: "translationEnabled")
        UserDefaults.standard.set(!isEnabled, forKey: "translationEnabled")
        HotKeyHandler.shared.resetLastTranslationLocation()
        TranslationPanel.shared.dismiss()
    }
    
    @objc private func setModeEnZh() {
        UserDefaults.standard.set("en-to-zh", forKey: "translationMode")
        HotKeyHandler.shared.resetLastTranslationLocation()
        TranslationPanel.shared.dismiss()
    }
    
    @objc private func setModeZhEn() {
        UserDefaults.standard.set("zh-to-en", forKey: "translationMode")
        HotKeyHandler.shared.resetLastTranslationLocation()
        TranslationPanel.shared.dismiss()
    }
    
    @objc private func openSettings() {
        SettingsWindowManager.shared.show()
    }
    
    @objc private func quitApp() {
        TranslationPanel.shared.dismiss()
        HotKeyHandler.shared.stopMonitoring()
        NSApp.terminate(nil)
    }
    
    private func setupEventMonitors() {
        HotKeyHandler.shared.startMonitoring()
        
        // Bind hover activation callback
        HotKeyHandler.shared.onHoverTriggered = { mousePoint in
            DispatchQueue.main.async {
                self.handleHoverTrigger(at: mousePoint)
            }
        }
        
        // Dismiss panel if mouse moves
        HotKeyHandler.shared.onMouseMoved = {
            DispatchQueue.main.async {
                TranslationPanel.shared.dismiss()
            }
        }
        
        // Dismiss panel if modifier key is released
        HotKeyHandler.shared.onModifierReleased = {
            DispatchQueue.main.async {
                TranslationPanel.shared.dismiss()
            }
        }
    }
    
    private func handleHoverTrigger(at mousePoint: NSPoint) {
        let isEnabled = UserDefaults.standard.bool(forKey: "translationEnabled")
        guard isEnabled else { return }
        
        // 1. Check Screen Recording permissions
        if !CGPreflightScreenCaptureAccess() {
            TranslationPanel.shared.show(
                at: mousePoint,
                word: Localization.string(for: "no_permission"),
                context: "",
                googleResult: Localization.string(for: "no_permission_desc"),
                aiResult: nil,
                aiEnabled: false
            )
            return
        }
        
        let activeMode = UserDefaults.standard.string(forKey: "translationMode") ?? "en-to-zh"
        
        // 2. Perform local OCR text extraction
        guard let extracted = TextExtractor.extractWordAtCursor(mode: activeMode) else {
            return
        }
        
        let word = extracted.word
        let context = extracted.context
        let isAiEnabled = UserDefaults.standard.bool(forKey: "aiEnabled")
        
        // 3. Show floating window in loading state
        TranslationPanel.shared.show(
            at: mousePoint,
            word: word,
            context: context,
            googleResult: nil,
            aiResult: nil,
            aiEnabled: isAiEnabled
        )
        
        // 4. Fetch translations asynchronously in background task (runs on MainActor)
        Task {
            // Request Google translation (non-isolated network call)
            let googleTrans = await TranslationService.shared.translateWithGoogle(word: word, direction: activeMode)
            
            // Resumes on MainActor automatically
            if TranslationPanel.shared.isVisible {
                TranslationPanel.shared.update(
                    word: word,
                    context: context,
                    googleResult: googleTrans,
                    aiResult: nil,
                    aiEnabled: isAiEnabled
                )
            }
            
            // Request AI deep context translation (if enabled)
            if isAiEnabled && TranslationPanel.shared.isVisible {
                let aiTrans = await TranslationService.shared.translateWithAI(word: word, context: context, direction: activeMode)
                
                // Resumes on MainActor automatically
                if TranslationPanel.shared.isVisible {
                    TranslationPanel.shared.update(
                        word: word,
                        context: context,
                        googleResult: googleTrans,
                        aiResult: aiTrans,
                        aiEnabled: isAiEnabled
                    )
                }
            }
        }
    }
}
