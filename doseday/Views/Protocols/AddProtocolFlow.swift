import SwiftUI
import SwiftData

// MARK: - Main Sheet

struct AddProtocolFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var tempProtocol: MedicationProtocol?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $selectedTab) {
                    Text("Single Compound").tag(0)
                    Text("Protocol").tag(1)
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])

                if selectedTab == 0 {
                    SingleCompoundTab()
                } else {
                    ProtocolBuilderTab(tempProtocol: $tempProtocol)
                }
            }
            .navigationTitle(selectedTab == 0 ? "New Compound" : "New Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if let p = tempProtocol { modelContext.delete(p) }
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tab 0: Single Compound

private struct SingleCompoundTab: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var route: DrugRoute = .oral
    @State private var colorHex = "#34C759"
    @State private var doseUnit = "mg"
    @State private var halfLifeHours = 24.0
    @State private var frequencyType: FrequencyType = .daily
    @State private var times: [LocalTime] = [LocalTime(hour: 8, minute: 0)]
    @State private var intervalDays = 7
    @State private var selectedWeekdays: Set<Int> = [2]
    @State private var doseAmount = 10.0
    @State private var reminderEnabled = true
    @State private var minutesBefore = 15
    @State private var soundEnabled = true

    @State private var compoundLibrary = CompoundLibraryService()

    private let palette = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00"]
    private let paletteNames = ["Blue", "Green", "Orange", "Red", "Purple", "Pink", "Light Blue", "Yellow"]
    private let minuteOptions = [0, 5, 10, 15, 30, 60]
    private let weekdayLabels = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        Form {
            Section("Drug Info") {
                TextField("Search or type a name…", text: $name)
                    .onChange(of: name) { _, q in compoundLibrary.search(q) }
                ForEach(compoundLibrary.suggestions, id: \.name) { entry in
                    Button { applySuggestion(entry) } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name).foregroundStyle(.primary)
                            if let hl = entry.defaultHalfLifeHours {
                                Text("t½ \(Int(hl))h · \(entry.route ?? "injection")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(entry.name)
                    .accessibilityHint("Tap to auto-fill drug details")
                }
                if compoundLibrary.isLoading && name.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Loading compound library…").font(.caption).foregroundStyle(.secondary)
                    }
                }
                if let err = compoundLibrary.fetchError, name.count >= 2, compoundLibrary.suggestions.isEmpty {
                    Text(err).font(.footnote).foregroundStyle(.secondary)
                }
                Picker("Route", selection: $route) {
                    ForEach(DrugRoute.allCases, id: \.self) { r in
                        Text(r.displayName).tag(r)
                    }
                }
                HStack {
                    Text("Dose Unit")
                    Spacer()
                    TextField("mg", text: $doseUnit)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
                HStack {
                    Text("Half-life (hours)")
                    Spacer()
                    TextField("24", value: $halfLifeHours, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                }
            }

            Section("Color") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(Array(zip(palette, paletteNames)), id: \.0) { hex, name in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if hex == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture { colorHex = hex }
                            .accessibilityLabel(name)
                            .accessibilityAddTraits(hex == colorHex ? .isSelected : [])
                            .accessibilityHint(hex == colorHex ? "Selected" : "Tap to select")
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Schedule") {
                Picker("Frequency", selection: $frequencyType) {
                    Text("Daily").tag(FrequencyType.daily)
                    Text("Specific Days").tag(FrequencyType.specificDays)
                    Text("Every N Days").tag(FrequencyType.everyNDays)
                }
                .pickerStyle(.segmented)

                if frequencyType == .specificDays {
                    HStack(spacing: 4) {
                        ForEach(1...7, id: \.self) { weekday in
                            let label = weekdayLabels[weekday - 1]
                            let isSelected = selectedWeekdays.contains(weekday)
                            Button {
                                if isSelected { selectedWeekdays.remove(weekday) }
                                else { selectedWeekdays.insert(weekday) }
                            } label: {
                                Text(String(label.prefix(1)))
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(isSelected ? Color.blue : Color.secondary.opacity(0.15))
                                    .foregroundStyle(isSelected ? .white : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                if frequencyType == .everyNDays {
                    Stepper("Every \(intervalDays) days", value: $intervalDays, in: 1...365)
                }

                HStack {
                    Text("Dose Amount")
                    Spacer()
                    TextField("10", value: $doseAmount, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                    Text(doseUnit.isEmpty ? "mg" : doseUnit)
                        .foregroundStyle(.secondary)
                }

                ForEach(times.indices, id: \.self) { i in
                    HStack {
                        Text(times.count == 1 ? "Time" : "Time \(i + 1)")
                        Spacer()
                        APFTimePickerField(time: $times[i])
                    }
                }

                HStack {
                    Button {
                        times.append(LocalTime(hour: 8, minute: 0))
                    } label: {
                        Label("Add Time", systemImage: "plus.circle")
                            .font(.subheadline)
                    }
                    if times.count > 1 {
                        Spacer()
                        Button(role: .destructive) {
                            times.removeLast()
                        } label: {
                            Label("Remove", systemImage: "minus.circle")
                                .font(.subheadline)
                        }
                    }
                }
            }

            Section("Reminder") {
                Toggle("Enable Reminder", isOn: $reminderEnabled)
                if reminderEnabled {
                    Picker("Remind Before", selection: $minutesBefore) {
                        ForEach(minuteOptions, id: \.self) { m in
                            Text(m == 0 ? "At dose time" : "\(m) min before").tag(m)
                        }
                    }
                    Toggle("Sound", isOn: $soundEnabled)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
            }
        }
        .task { await compoundLibrary.load() }
    }

    private func applySuggestion(_ entry: CompoundEntry) {
        name = entry.name
        if let r = entry.route, let parsed = DrugRoute(rawValue: r) { route = parsed }
        if let unit = entry.defaultDoseUnit { doseUnit = unit }
        if let hl = entry.defaultHalfLifeHours { halfLifeHours = hl }
        if let hex = entry.colorHex { colorHex = hex }
        compoundLibrary.clearSuggestions()
    }

    private func save() {
        let schedule = ScheduleDefinition(
            frequencyType: frequencyType,
            times: times.sorted(),
            intervalDays: frequencyType == .everyNDays ? intervalDays : nil,
            weekdays: frequencyType == .specificDays ? Array(selectedWeekdays).sorted() : nil,
            doseAmount: doseAmount,
            doseUnit: doseUnit
        )
        let reminder = ReminderSettings(enabled: reminderEnabled, minutesBefore: minutesBefore, soundEnabled: soundEnabled)
        let schedData = (try? schedule.encoded()) ?? Data()
        let remData = (try? reminder.encoded()) ?? Data()

        let proto = MedicationProtocol(name: name, startDate: Date(), colorHex: colorHex)
        modelContext.insert(proto)

        let drug = Drug(
            name: name,
            route: route,
            colorHex: colorHex,
            doseUnit: doseUnit,
            halfLifeHours: halfLifeHours,
            scheduleData: schedData,
            reminderData: remData
        )
        modelContext.insert(drug)
        drug.protocol = proto

        dismiss()
    }
}

// MARK: - Tab 1: Protocol Builder

private struct ProtocolBuilderTab: View {
    @Binding var tempProtocol: MedicationProtocol?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var protocolName = ""
    @State private var colorHex = "#007AFF"
    @State private var startDate = Date()
    @State private var hasEndDate = false
    @State private var endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var notes = ""
    @State private var showAddDrug = false

    private let palette = ["#007AFF", "#34C759", "#FF9500", "#FF3B30", "#AF52DE", "#FF2D55", "#5AC8FA", "#FFCC00"]
    private let paletteNames = ["Blue", "Green", "Orange", "Red", "Purple", "Pink", "Light Blue", "Yellow"]

    var body: some View {
        Form {
            Section("Protocol Info") {
                TextField("Protocol Name", text: $protocolName)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 8) {
                    ForEach(Array(zip(palette, paletteNames)), id: \.0) { hex, name in
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 30, height: 30)
                            .overlay {
                                if hex == colorHex {
                                    Image(systemName: "checkmark")
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.white)
                                }
                            }
                            .onTapGesture { colorHex = hex }
                            .accessibilityLabel(name)
                            .accessibilityAddTraits(hex == colorHex ? .isSelected : [])
                            .accessibilityHint(hex == colorHex ? "Selected" : "Tap to select")
                    }
                }
                .padding(.vertical, 4)

                DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                Toggle("Has End Date", isOn: $hasEndDate)
                if hasEndDate {
                    DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
                }
                TextField("Notes (optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section("Drugs") {
                if let proto = tempProtocol, !proto.drugs.isEmpty {
                    ForEach(proto.drugs) { drug in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: drug.colorHex))
                                .frame(width: 10, height: 10)
                            Text(drug.name)
                            Spacer()
                            Text(drug.route.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        for i in indexSet { modelContext.delete(proto.drugs[i]) }
                    }
                }

                Button {
                    ensureTempProtocol()
                    showAddDrug = true
                } label: {
                    Label("Add Drug", systemImage: "plus.circle")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save") { save() }
                    .disabled(protocolName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showAddDrug) {
            if let proto = tempProtocol {
                DrugEditorView(protocol: proto)
            }
        }
        .onChange(of: protocolName) { _, _ in syncTempProtocol() }
        .onChange(of: colorHex) { _, _ in syncTempProtocol() }
        .onChange(of: startDate) { _, _ in syncTempProtocol() }
        .onChange(of: hasEndDate) { _, _ in syncTempProtocol() }
        .onChange(of: endDate) { _, _ in syncTempProtocol() }
        .onChange(of: notes) { _, _ in syncTempProtocol() }
    }

    private func ensureTempProtocol() {
        guard tempProtocol == nil else { return }
        let trimmed = protocolName.trimmingCharacters(in: .whitespaces)
        let proto = MedicationProtocol(
            name: trimmed.isEmpty ? "New Protocol" : trimmed,
            notes: notes,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            colorHex: colorHex
        )
        modelContext.insert(proto)
        tempProtocol = proto
    }

    private func syncTempProtocol() {
        guard let proto = tempProtocol else { return }
        let trimmed = protocolName.trimmingCharacters(in: .whitespaces)
        proto.name = trimmed.isEmpty ? "New Protocol" : trimmed
        proto.notes = notes
        proto.startDate = startDate
        proto.endDate = hasEndDate ? endDate : nil
        proto.colorHex = colorHex
        proto.updatedAt = Date()
    }

    private func save() {
        let trimmed = protocolName.trimmingCharacters(in: .whitespaces)
        if let proto = tempProtocol {
            proto.name = trimmed
            proto.notes = notes
            proto.startDate = startDate
            proto.endDate = hasEndDate ? endDate : nil
            proto.colorHex = colorHex
            proto.updatedAt = Date()
        } else {
            let proto = MedicationProtocol(
                name: trimmed,
                notes: notes,
                startDate: startDate,
                endDate: hasEndDate ? endDate : nil,
                colorHex: colorHex
            )
            modelContext.insert(proto)
            tempProtocol = proto
        }
        dismiss()
    }
}

// MARK: - Shared Helper

private struct APFTimePickerField: View {
    @Binding var time: LocalTime

    private var dateBinding: Binding<Date> {
        Binding(
            get: {
                var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                comps.hour = time.hour
                comps.minute = time.minute
                return Calendar.current.date(from: comps) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                time = LocalTime(hour: comps.hour ?? 8, minute: comps.minute ?? 0)
            }
        )
    }

    var body: some View {
        DatePicker("", selection: dateBinding, displayedComponents: .hourAndMinute)
            .labelsHidden()
    }
}
