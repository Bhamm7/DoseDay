import SwiftUI
import UserNotifications

struct SettingsView: View {
    @AppStorage("glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mmolL.rawValue
    @AppStorage("weightUnit") private var weightUnit = "kg"

    @State private var authStatus: UNAuthorizationStatus = .notDetermined
    @State private var showTestSentBanner = false

    private let notificationService = NotificationService()

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Status")
                    Spacer()
                    Text(authStatusLabel)
                        .foregroundStyle(authStatus == .authorized ? .green : .secondary)
                }

                if authStatus == .denied {
                    Button("Open iOS Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } else if authStatus == .notDetermined {
                    Button("Enable Notifications") {
                        Task {
                            await notificationService.requestPermission()
                            authStatus = await notificationService.authorizationStatus
                        }
                    }
                }

                Button("Send Test Notification") {
                    notificationService.sendTestNotification()
                    withAnimation { showTestSentBanner = true }
                }
            } header: {
                Text("Notifications")
            } footer: {
                if authStatus == .denied {
                    Text("Notifications are disabled. Enable them in iOS Settings → DoseDay.")
                }
            }

            Section("Units") {
                Picker("Glucose", selection: $glucoseUnitRaw) {
                    ForEach(GlucoseUnit.allCases, id: \.rawValue) { unit in
                        Text(unit.displayName).tag(unit.rawValue)
                    }
                }
                Picker("Weight", selection: $weightUnit) {
                    Text("kg").tag("kg")
                    Text("lbs").tag("lbs")
                }
            }

            Section("Customisation") {
                NavigationLink("Symptom Tags") {
                    SymptomTagManagerView()
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0")

                VStack(alignment: .leading, spacing: 4) {
                    Text("Safety Disclaimer")
                        .font(.caption.weight(.semibold))
                    Text("DoseDay is a personal tracking tool only. It is not a medical device and does not provide medical advice. Always consult a qualified healthcare professional before making any decisions about your medication.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Settings")
        .task { authStatus = await notificationService.authorizationStatus }
        .overlay(alignment: .bottom) {
            if showTestSentBanner {
                Text("Test notification sent — check in 3 seconds.")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(2.5))
                        withAnimation { showTestSentBanner = false }
                    }
            }
        }
    }

    private var authStatusLabel: String {
        switch authStatus {
        case .authorized: return "Enabled"
        case .denied: return "Denied"
        case .provisional: return "Provisional"
        case .ephemeral: return "Ephemeral"
        default: return "Not Set"
        }
    }
}
