import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("translationEnabled") private var translationEnabled = true
    @AppStorage("modifierKey") private var modifierKey = "command"
    @AppStorage("hoverDelay") private var hoverDelay = 0.3
    @AppStorage("translationMode") private var translationMode = "" // Empty means auto-detect based on locale
    
    // Google API Configuration
    @AppStorage("googleMirrorUrl") private var googleMirrorUrl = ""
    
    // AI API Configuration
    @AppStorage("aiEnabled") private var aiEnabled = false
    @AppStorage("aiProvider") private var aiProvider = "gemini"
    
    @AppStorage("geminiApiKey") private var geminiApiKey = ""
    @AppStorage("geminiModel") private var geminiModel = "gemini-1.5-flash"
    
    @AppStorage("openaiApiKey") private var openaiApiKey = ""
    @AppStorage("openaiEndpoint") private var openaiEndpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("openaiModel") private var openaiModel = "gpt-4o-mini"
    
    @State private var hasPermission = false
    
    var body: some View {
        TabView {
            // MARK: - General Settings Tab
            Form {
                Section {
                    Toggle(Localization.string(for: "general_enable"), isOn: $translationEnabled)
                        .toggleStyle(.switch)
                    
                    Picker(Localization.string(for: "general_key"), selection: $modifierKey) {
                        Text("Command (⌘)").tag("command")
                        Text("Option (⌥)").tag("option")
                        Text("Control (⌃)").tag("control")
                        Text("Shift (⇧)").tag("shift")
                    }
                    .disabled(!translationEnabled)
                    .pickerStyle(.menu)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(Localization.string(for: "general_delay"))
                            Spacer()
                            Text(String(format: "%.1f s", hoverDelay))
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $hoverDelay, in: 0.1...1.5, step: 0.1)
                    }
                    .disabled(!translationEnabled)
                    .padding(.vertical, 6)
                } header: {
                    Text(Localization.string(for: "general_trigger"))
                        .font(.headline)
                }
                
                Section {
                    TextField(Localization.string(for: "google_mirror"), text: $googleMirrorUrl)
                        .textFieldStyle(.roundedBorder)
                        .placeholder(when: googleMirrorUrl.isEmpty) {
                            Text("https://translate.googleapis.com").foregroundColor(.secondary)
                        }
                } header: {
                    Text(Localization.string(for: "google_section"))
                        .font(.headline)
                }
            }
            .padding(20)
            .tabItem {
                Label(Localization.string(for: "tab_general"), systemImage: "gearshape")
            }
            
            // MARK: - AI Context Settings Tab
            Form {
                Section {
                    Toggle(Localization.string(for: "ai_enable"), isOn: $aiEnabled)
                        .toggleStyle(.switch)
                    
                    if aiEnabled {
                        Picker(Localization.string(for: "ai_provider"), selection: $aiProvider) {
                            Text("Google Gemini").tag("gemini")
                            Text("OpenAI").tag("openai")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 4)
                        
                        if aiProvider == "gemini" {
                            SecureField("Gemini API Key", text: $geminiApiKey)
                                .textFieldStyle(.roundedBorder)
                            
                            Picker(Localization.string(for: "ai_model"), selection: $geminiModel) {
                                Text("gemini-1.5-flash (Fast)").tag("gemini-1.5-flash")
                                Text("gemini-2.5-flash (New)").tag("gemini-2.5-flash")
                                Text("gemini-1.5-pro (Deep)").tag("gemini-1.5-pro")
                            }
                        } else {
                            SecureField("API Key", text: $openaiApiKey)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField(Localization.string(for: "ai_endpoint"), text: $openaiEndpoint)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField(Localization.string(for: "ai_model"), text: $openaiModel)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                } header: {
                    Text(Localization.string(for: "ai_section"))
                        .font(.headline)
                }
            }
            .padding(20)
            .tabItem {
                Label(Localization.string(for: "tab_ai"), systemImage: "sparkles")
            }
            
            // MARK: - Permission Guide Tab
            VStack(alignment: .leading, spacing: 14) {
                Text(Localization.string(for: "permission_title"))
                    .font(.headline)
                
                Text(Localization.string(for: "permission_desc"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(hasPermission ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(hasPermission ? Localization.string(for: "permission_granted") : Localization.string(for: "permission_not_granted"))
                        .fontWeight(.semibold)
                }
                .padding(.vertical, 6)
                
                if !hasPermission {
                    Button(action: checkAndRequestPermission) {
                        Text(Localization.string(for: "permission_btn_request"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Text(Localization.string(for: "permission_tip"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Button(action: checkPermissionStatus) {
                        Text(Localization.string(for: "permission_btn_check"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
            }
            .padding(20)
            .tabItem {
                Label(Localization.string(for: "tab_permissions"), systemImage: "lock.shield")
            }
        }
        .frame(width: 440, height: 350)
        .onAppear {
            checkPermissionStatus()
        }
    }
    
    private func checkPermissionStatus() {
        hasPermission = CGPreflightScreenCaptureAccess()
    }
    
    private func checkAndRequestPermission() {
        let granted = CGRequestScreenCaptureAccess()
        hasPermission = granted
        if !granted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkPermissionStatus()
            }
        }
    }
}

// Extension to support placeholders in TextFields
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0).padding(.leading, 4)
            self
        }
    }
}

// MARK: - Window Manager helper
class SettingsWindowManager {
    static let shared = SettingsWindowManager()
    
    private var window: NSWindow?
    
    func show() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        let newWindow = NSWindow(
            contentViewController: hostingController
        )
        newWindow.setContentSize(NSSize(width: 440, height: 350))
        newWindow.styleMask = [.titled, .closable, .miniaturizable]
        newWindow.title = Localization.string(for: "settings_title")
        newWindow.isReleasedWhenClosed = false
        
        newWindow.center()
        
        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            self?.window = nil
        }
    }
}
