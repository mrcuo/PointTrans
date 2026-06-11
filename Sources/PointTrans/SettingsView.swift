import SwiftUI
import AppKit

// MARK: - Main Settings View
struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "auto"
    @State private var activeTab: String? = "general"

    var body: some View {
        NavigationSplitView {
            List(selection: $activeTab) {
                Label(Localization.string(for: "tab_general"), systemImage: "gearshape")
                    .tag("general")
                Label(Localization.string(for: "tab_ai"), systemImage: "sparkles")
                    .tag("ai")
                Label(Localization.string(for: "tab_permissions"), systemImage: "lock.shield")
                    .tag("permissions")
            }
            .listStyle(.sidebar)
        } detail: {
            switch activeTab {
            case "general":
                GeneralTab()
            case "ai":
                AITab()
            case "permissions":
                PermissionsTab()
            default:
                GeneralTab()
            }
        }
        .frame(width: 580, height: 400)
        .id(appLanguage)
        .onAppear {
            updateWindowTitle()
        }
        .onChange(of: appLanguage) { oldValue, newValue in
            updateWindowTitle()
        }
    }

    private func updateWindowTitle() {
        SettingsWindowManager.shared.window?.title = Localization.string(for: "settings_title")
    }
}

// MARK: - General Settings Tab
struct GeneralTab: View {
    @AppStorage("translationEnabled") private var translationEnabled = true
    @AppStorage("modifierKey") private var modifierKey = "command"
    @AppStorage("hoverDelay") private var hoverDelay = 0.3
    @AppStorage("appLanguage") private var appLanguage = "auto"

    var body: some View {
        Form {
            Section(Localization.string(for: "general_trigger")) {
                Toggle(Localization.string(for: "general_enable"), isOn: $translationEnabled)

                if translationEnabled {
                    Picker(Localization.string(for: "general_key"), selection: $modifierKey) {
                        Text("Command (⌘)").tag("command")
                        Text("Option (⌥)").tag("option")
                        Text("Control (⌃)").tag("control")
                        Text("Shift (⇧)").tag("shift")
                    }

                    HStack {
                        Text(Localization.string(for: "general_delay"))
                        Spacer()
                        Slider(value: $hoverDelay, in: 0.1...1.5, step: 0.1)
                            .frame(width: 120)
                        Text(String(format: "%.1f s", hoverDelay))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(width: 35, alignment: .trailing)
                    }
                }
            }

            Section(Localization.string(for: "general_language")) {
                Picker(Localization.string(for: "general_language"), selection: $appLanguage) {
                    Text(Localization.string(for: "lang_auto")).tag("auto")
                    Text(Localization.string(for: "lang_zh")).tag("zh")
                    Text(Localization.string(for: "lang_en")).tag("en")
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - AI Settings Tab
struct AITab: View {
    @AppStorage("aiEnabled") private var aiEnabled = false
    @AppStorage("aiProvider") private var aiProvider = "gemini"

    @AppStorage("geminiApiKey") private var geminiApiKey = ""
    @AppStorage("geminiModel") private var geminiModel = "gemini-1.5-flash"

    @AppStorage("openaiApiKey") private var openaiApiKey = ""
    @AppStorage("openaiEndpoint") private var openaiEndpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("openaiModel") private var openaiModel = "gpt-4o-mini"

    var body: some View {
        Form {
            Section(Localization.string(for: "ai_section")) {
                Toggle(Localization.string(for: "ai_enable"), isOn: $aiEnabled)

                if aiEnabled {
                    Picker(Localization.string(for: "ai_provider"), selection: $aiProvider) {
                        Text("Google Gemini").tag("gemini")
                        Text("OpenAI").tag("openai")
                    }
                    .pickerStyle(.segmented)
                }
            }

            if aiEnabled {
                if aiProvider == "gemini" {
                    Section("Gemini") {
                        SecureField("Gemini API Key", text: $geminiApiKey)

                        Picker(Localization.string(for: "ai_model"), selection: $geminiModel) {
                            Text("gemini-1.5-flash (Fast)").tag("gemini-1.5-flash")
                            Text("gemini-2.5-flash (New)").tag("gemini-2.5-flash")
                            Text("gemini-1.5-pro (Deep)").tag("gemini-1.5-pro")
                        }
                    }
                } else {
                    Section("OpenAI") {
                        SecureField("OpenAI API Key", text: $openaiApiKey)

                        TextField(Localization.string(for: "ai_endpoint"), text: $openaiEndpoint)

                        TextField(Localization.string(for: "ai_model"), text: $openaiModel)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Permissions Settings Tab
struct PermissionsTab: View {
    @State private var hasPermission = false

    var body: some View {
        Form {
            Section(Localization.string(for: "permission_title")) {
                Text(Localization.string(for: "permission_desc"))
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(3.5)

                HStack(spacing: 8) {
                    Circle()
                        .fill(hasPermission ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(hasPermission
                         ? Localization.string(for: "permission_granted")
                         : Localization.string(for: "permission_not_granted"))
                        .font(.system(size: 13, weight: .semibold))
                }

                if !hasPermission {
                    Button(action: checkAndRequestPermission) {
                        Text(Localization.string(for: "permission_btn_request"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Text(Localization.string(for: "permission_tip"))
                        .font(.system(size: 11))
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
            }
        }
        .formStyle(.grouped)
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

// MARK: - Window Manager
class SettingsWindowManager {
    static let shared = SettingsWindowManager()

    var window: NSWindow?

    func show() {
        if let existingWindow = window {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate()
            return
        }

        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let newWindow = NSWindow(
            contentViewController: hostingController
        )
        newWindow.setContentSize(NSSize(width: 580, height: 400))
        newWindow.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
        newWindow.title = Localization.string(for: "settings_title")
        newWindow.titlebarAppearsTransparent = true
        newWindow.titleVisibility = .hidden
        newWindow.isReleasedWhenClosed = false

        newWindow.center()

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate()

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            self?.window = nil
        }
    }
}
