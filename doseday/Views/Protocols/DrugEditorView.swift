import SwiftUI
import SwiftData

struct DrugEditorView: View {
    let `protocol`: MedicationProtocol
    var existingDrug: Drug?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var route: DrugRoute = .oral
    @State private var colorHex = "#34C759"
    @State private var doseUnit = "mg"
    @State private var halfLifeHours = 24.0
    @State private var reconstitutionAmountText = ""
    @State private var reconstitutionDiluentText = ""

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

    var isEditing: Bool { existingDrug != nil }

    var body: some View {
        NavigationStack {
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
                            TimePickerField(time: $times[i])
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

                if route == .injection {
                    Section("Syringe / Reconstitution") {
                        HStack {
                            Text("Compound Amount")
                            Spacer()
                            TextField("Optional", text: $reconstitutionAmountText)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 110)
                            Text(doseUnit.isEmpty ? "mg" : doseUnit)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Diluent")
                            Spacer()
                            TextField("Optional", text: $reconstitutionDiluentText)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .frame(width: 110)
                            Text("mL")
                                .foregroundStyle(.secondary)
                        }

                        Text("Used by the beta syringe view to calculate the U100 draw amount.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
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
            .navigationTitle(isEditing ? "Edit Drug" : "Add Drug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") { saveDrug() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { loadExisting() }
            .task { await compoundLibrary.load() }
        }
    }

    private func applySuggestion(_ entry: CompoundEntry) {
        name = entry.name
        if let r = entry.route, let parsed = DrugRoute(rawValue: r) { route = parsed }
        if let unit = entry.defaultDoseUnit { doseUnit = unit }
        if let hl = entry.defaultHalfLifeHours { halfLifeHours = hl }
        if let hex = entry.colorHex { colorHex = hex }
        compoundLibrary.clearSuggestions()
    }

    private func loadExisting() {
        guard let drug = existingDrug else { return }
        name = drug.name
        route = drug.route
        colorHex = drug.colorHex
        doseUnit = drug.doseUnit
        halfLifeHours = drug.halfLifeHours
        reconstitutionAmountText = formattedOptionalDouble(drug.reconstitutionAmount)
        reconstitutionDiluentText = formattedOptionalDouble(drug.reconstitutionDiluentML)
        if let sched = drug.schedule {
            frequencyType = sched.frequencyType
            times = sched.times
            intervalDays = sched.intervalDays ?? 7
            selectedWeekdays = Set(sched.weekdays ?? [])
            doseAmount = sched.doseAmount
        }
        let rem = drug.reminder
        reminderEnabled = rem.enabled
        minutesBefore = rem.minutesBefore
        soundEnabled = rem.soundEnabled
    }

    private func saveDrug() {
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

        if let drug = existingDrug {
            drug.name = name
            drug.route = route
            drug.colorHex = colorHex
            drug.doseUnit = doseUnit
            drug.halfLifeHours = halfLifeHours
            drug.reconstitutionAmount = route == .injection ? Double(reconstitutionAmountText) : nil
            drug.reconstitutionDiluentML = route == .injection ? Double(reconstitutionDiluentText) : nil
            drug.scheduleData = schedData
            drug.reminderData = remData
            drug.updatedAt = Date()
        } else {
            let drug = Drug(
                name: name,
                route: route,
                colorHex: colorHex,
                doseUnit: doseUnit,
                halfLifeHours: halfLifeHours,
                reconstitutionAmount: route == .injection ? Double(reconstitutionAmountText) : nil,
                reconstitutionDiluentML: route == .injection ? Double(reconstitutionDiluentText) : nil,
                scheduleData: schedData,
                reminderData: remData
            )
            modelContext.insert(drug)
            drug.protocol = `protocol`
        }
        dismiss()
    }

    private func formattedOptionalDouble(_ value: Double?) -> String {
        guard let value else { return "" }
        return value.formatted(.number.precision(.fractionLength(0...2)))
    }
}

private struct TimePickerField: View {
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
