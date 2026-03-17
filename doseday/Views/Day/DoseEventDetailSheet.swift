import SwiftUI
import SwiftData

struct DoseEventDetailSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var event: DoseEvent

    @State private var customTime: Date = Date()
    @State private var useCustomTime: Bool = false
    @State private var selectedSite: InjectionSite? = nil
    @State private var isCustomSite: Bool = false
    @State private var customSiteText: String = ""
    @State private var noteText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Scheduled") {
                    LabeledContent("Time") {
                        Text(event.scheduledAt, format: .dateTime.hour().minute())
                    }
                }

                Section("Status") {
                    Toggle("Custom time", isOn: $useCustomTime)
                    if useCustomTime {
                        DatePicker("Time taken", selection: $customTime, displayedComponents: [.hourAndMinute])
                    }
                    Button("Mark Taken") {
                        event.status = .taken
                        event.takenAt = useCustomTime ? customTime : Date()
                    }
                    .disabled(event.status == .taken)

                    Button("Skip", role: .destructive) {
                        event.status = .skipped
                    }
                    .disabled(event.status == .skipped)
                }

                if event.drug?.route == .injection {
                    Section("Injection Site") {
                        BodyMapView(
                            selectedSite: $selectedSite,
                            isPickerMode: true,
                            onSiteTapped: { _, pos in
                                event.injectionPositionX = pos.x
                                event.injectionPositionY = pos.y
                                event.injectionPositionZ = pos.z
                            }
                        )
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 8)

                        Toggle("Custom site", isOn: $isCustomSite)
                            .onChange(of: isCustomSite) { _, on in
                                if on { selectedSite = nil }
                            }
                        if isCustomSite {
                            TextField("Site name", text: $customSiteText)
                        }
                        if let site = selectedSite, !isCustomSite {
                            LabeledContent("Selected", value: site.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Notes", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(event)
                        dismiss()
                    }
                }
            }
            .navigationTitle(event.drug?.name ?? "Dose")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAndDismiss() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                noteText = event.notes ?? ""
                if let site = event.resolvedInjectionSite {
                    if case .custom(let text) = site {
                        isCustomSite = true
                        customSiteText = text
                    } else {
                        selectedSite = site
                    }
                }
            }
        }
    }

    private func saveAndDismiss() {
        if isCustomSite {
            event.injectionSite = InjectionSite.custom(customSiteText).rawValue
        } else if let site = selectedSite {
            event.injectionSite = site.rawValue
        }
        // Tapping a site counts as recording the injection — auto-mark taken
        if (selectedSite != nil || isCustomSite) && event.status != .taken {
            event.status = .taken
            event.takenAt = useCustomTime ? customTime : Date()
        }
        event.notes = noteText.isEmpty ? nil : noteText
        dismiss()
    }
}
