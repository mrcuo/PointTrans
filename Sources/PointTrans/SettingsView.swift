import SwiftUI
import AppKit

// MARK: - Sidebar Button Component
struct SidebarButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    private let champagneGold = Color(red: 197/255, green: 168/255, blue: 128/255)
    private let oxfordNavy = Color(red: 10/255, green: 25/255, blue: 47/255)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isActive ? (colorScheme == .light ? .white : oxfordNavy) : champagneGold)
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundColor(isActive ? (colorScheme == .light ? .white : oxfordNavy) : .primary)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isActive ? champagneGold : Color.clear)
        )
    }
}

// MARK: - Main Settings View (Oxford Legacy Reconstruct)
struct SettingsView: View {
    @State private var activeTab = "general"
    
    @Environment(\.colorScheme) var colorScheme
    
    // Theme Colors
    private let oxfordNavy = Color(red: 10/255, green: 25/255, blue: 47/255)
    private let champagneGold = Color(red: 197/255, green: 168/255, blue: 128/255)
    private let parchment = Color(red: 253/255, green: 251/255, blue: 247/255)
    
    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar Navigation
            VStack(alignment: .leading, spacing: 10) {
                // Header Logo
                HStack(spacing: 8) {
                    Image(systemName: "translate")
                        .foregroundColor(champagneGold)
                        .font(.system(size: 16, weight: .bold))
                    
                    Text(Localization.string(for: "app_name"))
                        .font(.custom("Georgia", size: 16).bold())
                        .foregroundColor(colorScheme == .light ? oxfordNavy : .white)
                }
                .padding(.bottom, 24)
                .padding(.top, 10)
                
                // Tabs selection
                SidebarButton(title: Localization.string(for: "tab_general"), icon: "gearshape", isActive: activeTab == "general") {
                    activeTab = "general"
                }
                SidebarButton(title: Localization.string(for: "tab_ai"), icon: "sparkles", isActive: activeTab == "ai") {
                    activeTab = "ai"
                }
                SidebarButton(title: Localization.string(for: "tab_permissions"), icon: "lock.shield", isActive: activeTab == "permissions") {
                    activeTab = "permissions"
                }
                
                Spacer()
                
                // Thin double line footer
                VStack(spacing: 1.5) {
                    Divider().background(champagneGold.opacity(0.3))
                    Divider().background(champagneGold.opacity(0.1))
                }
                .padding(.top, 10)
                
                Text("Version 1.0")
                    .font(.custom("SFMono-Regular", size: 8))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding(18)
            .frame(width: 175)
            .background(colorScheme == .light ? Color.primary.opacity(0.02) : Color.black.opacity(0.2))
            
            Divider()
                .background(champagneGold.opacity(0.35))
            
            // Right Content Area
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 20) {
                    if activeTab == "general" {
                        GeneralTab()
                    } else if activeTab == "ai" {
                        AITab()
                    } else {
                        PermissionsTab()
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 580, height: 380)
        .background(colorScheme == .light ? parchment : oxfordNavy)
    }
}

// MARK: - General Settings Tab View
struct GeneralTab: View {
    @AppStorage("translationEnabled") private var translationEnabled = true
    @AppStorage("modifierKey") private var modifierKey = "command"
    @AppStorage("hoverDelay") private var hoverDelay = 0.3
    @AppStorage("googleMirrorUrl") private var googleMirrorUrl = ""
    
    @Environment(\.colorScheme) var colorScheme
    private let champagneGold = Color(red: 197/255, green: 168/255, blue: 128/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Trigger Settings Section
            VStack(alignment: .leading, spacing: 10) {
                Text(Localization.string(for: "general_trigger").uppercased())
                    .font(.custom("SFMono-Regular", size: 9))
                    .fontWeight(.bold)
                    .tracking(1.8)
                    .foregroundColor(champagneGold)
                
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(Localization.string(for: "general_enable"), isOn: $translationEnabled)
                        .toggleStyle(.switch)
                        .tint(champagneGold)
                    
                    if translationEnabled {
                        Picker(Localization.string(for: "general_key"), selection: $modifierKey) {
                            Text("Command (⌘)").tag("command")
                            Text("Option (⌥)").tag("option")
                            Text("Control (⌃)").tag("control")
                            Text("Shift (⇧)").tag("shift")
                        }
                        .pickerStyle(.menu)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(Localization.string(for: "general_delay"))
                                Spacer()
                                Text(String(format: "%.1f s", hoverDelay))
                                    .font(.custom("SFMono-Regular", size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $hoverDelay, in: 0.1...1.5, step: 0.1)
                                .tint(champagneGold)
                        }
                    }
                }
                .padding(16)
                .background(colorScheme == .light ? Color.white : Color.black.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(champagneGold.opacity(0.25), lineWidth: 1)
                )
            }
            
            // Google Settings Section
            VStack(alignment: .leading, spacing: 10) {
                Text(Localization.string(for: "google_section").uppercased())
                    .font(.custom("SFMono-Regular", size: 9))
                    .fontWeight(.bold)
                    .tracking(1.8)
                    .foregroundColor(champagneGold)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(Localization.string(for: "google_mirror"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    TextField("https://translate.googleapis.com", text: $googleMirrorUrl)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(16)
                .background(colorScheme == .light ? Color.white : Color.black.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(champagneGold.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - AI Settings Tab View
struct AITab: View {
    @AppStorage("aiEnabled") private var aiEnabled = false
    @AppStorage("aiProvider") private var aiProvider = "gemini"
    
    @AppStorage("geminiApiKey") private var geminiApiKey = ""
    @AppStorage("geminiModel") private var geminiModel = "gemini-1.5-flash"
    
    @AppStorage("openaiApiKey") private var openaiApiKey = ""
    @AppStorage("openaiEndpoint") private var openaiEndpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("openaiModel") private var openaiModel = "gpt-4o-mini"
    
    @Environment(\.colorScheme) var colorScheme
    private let champagneGold = Color(red: 197/255, green: 168/255, blue: 128/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(Localization.string(for: "ai_section").uppercased())
                    .font(.custom("SFMono-Regular", size: 9))
                    .fontWeight(.bold)
                    .tracking(1.8)
                    .foregroundColor(champagneGold)
                
                VStack(alignment: .leading, spacing: 14) {
                    Toggle(Localization.string(for: "ai_enable"), isOn: $aiEnabled)
                        .toggleStyle(.switch)
                        .tint(champagneGold)
                    
                    if aiEnabled {
                        Picker(Localization.string(for: "ai_provider"), selection: $aiProvider) {
                            Text("Google Gemini").tag("gemini")
                            Text("OpenAI").tag("openai")
                        }
                        .pickerStyle(.segmented)
                        .padding(.vertical, 2)
                        
                        if aiProvider == "gemini" {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Gemini API Key")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                SecureField("AIzaSy...", text: $geminiApiKey)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Picker(Localization.string(for: "ai_model"), selection: $geminiModel) {
                                Text("gemini-1.5-flash (Fast)").tag("gemini-1.5-flash")
                                Text("gemini-2.5-flash (New)").tag("gemini-2.5-flash")
                                Text("gemini-1.5-pro (Deep)").tag("gemini-1.5-pro")
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("API Key")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                SecureField("sk-...", text: $openaiApiKey)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Localization.string(for: "ai_endpoint"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                TextField("https://api.openai.com/v1/chat/completions", text: $openaiEndpoint)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(Localization.string(for: "ai_model"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                TextField("gpt-4o-mini", text: $openaiModel)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }
                .padding(16)
                .background(colorScheme == .light ? Color.white : Color.black.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(champagneGold.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Permissions Settings Tab View
struct PermissionsTab: View {
    @State private var hasPermission = false
    
    @Environment(\.colorScheme) var colorScheme
    private let champagneGold = Color(red: 197/255, green: 168/255, blue: 128/255)
    private let oxfordNavy = Color(red: 10/255, green: 25/255, blue: 47/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text(Localization.string(for: "permission_title").uppercased())
                    .font(.custom("SFMono-Regular", size: 9))
                    .fontWeight(.bold)
                    .tracking(1.8)
                    .foregroundColor(champagneGold)
                
                VStack(alignment: .leading, spacing: 14) {
                    Text(Localization.string(for: "permission_desc"))
                        .font(.custom("Georgia", size: 13))
                        .lineSpacing(4)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(hasPermission ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(hasPermission ? Localization.string(for: "permission_granted") : Localization.string(for: "permission_not_granted"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                    
                    if !hasPermission {
                        Button(action: checkAndRequestPermission) {
                            Text(Localization.string(for: "permission_btn_request"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .light ? .white : oxfordNavy)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(champagneGold)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        
                        Text(Localization.string(for: "permission_tip"))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Button(action: checkPermissionStatus) {
                            Text(Localization.string(for: "permission_btn_check"))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(colorScheme == .light ? oxfordNavy : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(champagneGold, lineWidth: 1.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .background(colorScheme == .light ? Color.white : Color.black.opacity(0.15))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(champagneGold.opacity(0.25), lineWidth: 1)
                )
            }
        }
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
        newWindow.setContentSize(NSSize(width: 580, height: 380))
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
