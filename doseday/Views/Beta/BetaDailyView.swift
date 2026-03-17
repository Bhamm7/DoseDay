import SwiftUI
import SwiftData

struct BetaDailyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allProtocols: [MedicationProtocol]
    @Query private var allEvents: [DoseEvent]
    @Query private var allVitals: [DailyVitals]

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var displayedMonth: Date = {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) ?? Date()
    }()
    @State private var isCalendarExpanded = false

    private let calendar = Calendar.current

    private var allDrugs: [Drug] {
        allProtocols.flatMap(\.drugs)
    }

    private var syncToken: String {
        let monthToken = displayedMonth.timeIntervalSinceReferenceDate.formatted(.number.precision(.fractionLength(0)))
        let drugToken = allDrugs
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { "\($0.id.uuidString)-\($0.updatedAt.timeIntervalSinceReferenceDate)" }
            .joined(separator: "|")
        return "\(monthToken)|\(drugToken)"
    }

    private var dayEvents: [DoseEvent] {
        let now = Date()
        return eventsForDay(selectedDate).sorted { lhs, rhs in
            let lhsRank = eventSortRank(lhs, now: now)
            let rhsRank = eventSortRank(rhs, now: now)
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.scheduledAt < rhs.scheduledAt
        }
    }

    private var dayVitals: DailyVitals? {
        allVitals.first { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var selectedDateTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        }
        return selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    BetaTheme.canvas,
                    BetaTheme.canvas,
                    BetaTheme.sectionTint.opacity(0.75)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    headerSection

                    BetaVitalsGridView(date: selectedDate, vitals: dayVitals, title: "Vitals & Weight")

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Meds")
                                .font(.headline)
                                .foregroundStyle(BetaTheme.textPrimary)
                            Spacer()
                            Text("\(dayEvents.count)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BetaTheme.textSecondary)
                        }

                        if dayEvents.isEmpty {
                            Text(emptyStateCopy)
                                .font(.subheadline)
                                .foregroundStyle(BetaTheme.textSecondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BetaTheme.card)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20)
                                        .strokeBorder(BetaTheme.border, lineWidth: 1)
                                }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(dayEvents) { event in
                                    NavigationLink {
                                        BetaDoseDetailView(event: event)
                                    } label: {
                                        BetaDoseTile(event: event)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(BetaTheme.sectionSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28)
                            .strokeBorder(BetaTheme.sectionStroke, lineWidth: 1)
                    }
                    .shadow(color: BetaTheme.shadow, radius: 18, x: 0, y: 10)
                    .padding(.horizontal)

                    SymptomsEditorView(date: selectedDate, style: .beta)
                        .padding(.vertical, 16)
                        .background(BetaTheme.sectionSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(BetaTheme.sectionStroke, lineWidth: 1)
                        }
                        .shadow(color: BetaTheme.shadow, radius: 18, x: 0, y: 10)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: syncToken) {
            syncDisplayedMonth()
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                BetaHeaderCircleButton(systemName: "chevron.left", action: {
                    moveDay(by: -1)
                })

                Spacer(minLength: 8)

                Button {
                    withAnimation(.snappy) {
                        isCalendarExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(selectedDateTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BetaTheme.textPrimary)
                            .contentTransition(.numericText())

                        Image(systemName: isCalendarExpanded ? "chevron.up.circle.fill" : "calendar.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BetaTheme.sage)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(BetaTheme.card)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(BetaTheme.border, lineWidth: 1)
                    }
                    .shadow(color: BetaTheme.shadow.opacity(0.7), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                BetaHeaderCircleButton(systemName: "chevron.right", action: {
                    moveDay(by: 1)
                })
            }

            if isCalendarExpanded {
                BetaInlineMonthCalendar(
                    displayedMonth: displayedMonth,
                    selectedDate: selectedDate,
                    eventsForDay: eventsForDay,
                    onPrevMonth: moveToPreviousMonth,
                    onNextMonth: moveToNextMonth,
                    onSelectDate: selectDate
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(
                colors: [
                    BetaTheme.sectionTint.opacity(0.92),
                    BetaTheme.canvas.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 30))
        .overlay {
            RoundedRectangle(cornerRadius: 30)
                .strokeBorder(BetaTheme.sectionStroke, lineWidth: 1)
        }
        .shadow(color: BetaTheme.shadow, radius: 18, x: 0, y: 10)
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var emptyStateCopy: String {
        if allDrugs.isEmpty {
            return "No compounds scheduled yet. Add a protocol to populate the daily agenda."
        }
        return "No doses scheduled for the selected day."
    }

    private func eventsForDay(_ date: Date) -> [DoseEvent] {
        allEvents.filter { calendar.isDate($0.scheduledAt, inSameDayAs: date) }
    }

    private func syncDisplayedMonth() {
        guard !allDrugs.isEmpty else { return }
        let monthStart = startOfMonth(for: displayedMonth)
        let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
        SchedulingService().reconcileDoseEvents(
            for: allDrugs,
            in: DateInterval(start: monthStart, end: monthEnd),
            allEvents: allEvents,
            modelContext: modelContext
        )
    }

    private func moveToPreviousMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth(for: displayedMonth)) ?? displayedMonth
    }

    private func moveToNextMonth() {
        displayedMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth(for: displayedMonth)) ?? displayedMonth
    }

    private func moveDay(by offset: Int) {
        guard let newDate = calendar.date(byAdding: .day, value: offset, to: selectedDate) else { return }
        selectedDate = calendar.startOfDay(for: newDate)
        displayedMonth = startOfMonth(for: newDate)
    }

    private func selectDate(_ date: Date) {
        selectedDate = date
        displayedMonth = startOfMonth(for: date)
    }

    private func startOfMonth(for date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func eventSortRank(_ event: DoseEvent, now: Date) -> Int {
        switch event.status {
        case .scheduled:
            return event.scheduledAt < now ? 0 : 1
        case .taken:
            return 2
        case .skipped:
            return 3
        }
    }
}

private enum BetaTheme {
    static let canvas = Color(hex: "#FAF8F2")
    static let sectionTint = Color(hex: "#EEF3EA")
    static let sectionSurface = Color(hex: "#EEF3EA").opacity(0.88)
    static let card = Color(hex: "#FFFEFB")
    static let sage = Color(hex: "#A4B69E")
    static let deepSage = Color(hex: "#6E8C72")
    static let forestAccent = Color(hex: "#4E7056")
    static let chipTint = Color(hex: "#E4EEE1")
    static let textPrimary = Color(hex: "#334237")
    static let textSecondary = Color(hex: "#71806F")
    static let border = Color(hex: "#D9E2D6")
    static let sectionStroke = Color(hex: "#D6E0D3")
    static let shadow = Color.black.opacity(0.06)
}

private struct BetaHeaderCircleButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BetaTheme.deepSage)
                .frame(width: 34, height: 34)
                .background(BetaTheme.card)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(BetaTheme.border, lineWidth: 1)
                }
                .shadow(color: BetaTheme.shadow.opacity(0.75), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct BetaVitalsGridView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @AppStorage("glucoseUnit") private var glucoseUnitRaw = GlucoseUnit.mmolL.rawValue
    @AppStorage("betaVitalsShowWeight") private var showWeight = true
    @AppStorage("betaVitalsShowHeartRate") private var showHeartRate = true
    @AppStorage("betaVitalsShowBloodPressure") private var showBloodPressure = true
    @AppStorage("betaVitalsShowGlucose") private var showGlucose = true
    @AppStorage("betaVitalsShowSleep") private var showSleep = true
    @AppStorage("betaVitalsShowSteps") private var showSteps = true

    let date: Date
    let vitals: DailyVitals?
    var title: String = "Vitals"

    @State private var draft = VitalsDraft()
    @State private var persistedDraft = VitalsDraft()
    @State private var isShowingVitalsConfig = false
    @FocusState private var focusedField: BetaVitalField?

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    private var glucoseUnit: GlucoseUnit {
        GlucoseUnit(rawValue: glucoseUnitRaw) ?? .mmolL
    }

    private var weightUnitSuffix: String {
        weightUnit == "lbs" ? "lbs" : "kg"
    }

    private var hasVisibleTiles: Bool {
        showWeight || showHeartRate || showBloodPressure || showGlucose || showSleep || showSteps
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BetaTheme.textPrimary)

                Spacer()

                Button {
                    focusedField = nil
                    persistDraftIfNeeded()
                    isShowingVitalsConfig.toggle()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BetaTheme.deepSage)
                        .frame(width: 32, height: 32)
                        .background(BetaTheme.card)
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(BetaTheme.border, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .popover(isPresented: $isShowingVitalsConfig, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Show Vitals")
                            .font(.subheadline.weight(.semibold))

                        Toggle("Weight", isOn: visibilityBinding(
                            get: { showWeight },
                            set: { showWeight = $0 }
                        ))
                        Toggle("Heart Rate", isOn: visibilityBinding(
                            get: { showHeartRate },
                            set: { showHeartRate = $0 }
                        ))
                        Toggle("Blood Pressure", isOn: visibilityBinding(
                            get: { showBloodPressure },
                            set: { showBloodPressure = $0 }
                        ))
                        Toggle("Glucose", isOn: visibilityBinding(
                            get: { showGlucose },
                            set: { showGlucose = $0 }
                        ))
                        Toggle("Sleep", isOn: visibilityBinding(
                            get: { showSleep },
                            set: { showSleep = $0 }
                        ))
                        Toggle("Steps", isOn: visibilityBinding(
                            get: { showSteps },
                            set: { showSteps = $0 }
                        ))
                    }
                    .padding()
                    .frame(width: 220, alignment: .leading)
                    .presentationCompactAdaptation(.popover)
                }
            }

            if hasVisibleTiles {
                LazyVGrid(columns: columns, spacing: 8) {
                    if showWeight {
                        BetaVitalTile(title: "Weight", subtitle: weightUnitSuffix, icon: "scalemass.fill", tint: BetaTheme.deepSage) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                TextField("—", text: $draft.weightText)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .focused($focusedField, equals: .weight)

                                Text(weightUnitSuffix)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    if showHeartRate {
                        BetaVitalTile(title: "Heart Rate", subtitle: "bpm", icon: "heart.fill", tint: Color(hex: "#86A186")) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                TextField("—", text: $draft.hr)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .focused($focusedField, equals: .heartRate)

                                Text("bpm")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    if showBloodPressure {
                        BetaVitalTile(title: "Blood Pressure", subtitle: "mmHg", icon: "waveform.path.ecg.rectangle.fill", tint: BetaTheme.deepSage) {
                            HStack(spacing: 6) {
                                TextField("SYS", text: $draft.systolic)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.headline.weight(.semibold))
                                    .focused($focusedField, equals: .systolic)

                                Text("/")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)

                                TextField("DIA", text: $draft.diastolic)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.headline.weight(.semibold))
                                    .focused($focusedField, equals: .diastolic)
                            }
                            .foregroundStyle(.primary)
                        }
                    }

                    if showGlucose {
                        BetaVitalTile(title: "Glucose", subtitle: glucoseUnit.displayName, icon: "drop.fill", tint: Color(hex: "#91AC93")) {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                TextField("—", text: $draft.glucose)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .focused($focusedField, equals: .glucose)

                                Text(glucoseUnit.displayName)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    if showSleep {
                        BetaVitalTile(title: "Sleep", subtitle: "Apple Health", icon: "bed.double.fill", tint: Color(hex: "#ADC0A7")) {
                            Text("N/A")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if showSteps {
                        BetaVitalTile(title: "Steps", subtitle: "Apple Health", icon: "figure.walk", tint: Color(hex: "#88A183")) {
                            Text("N/A")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Text("No vitals selected. Use the menu to choose which tiles appear here.")
                    .font(.subheadline)
                    .foregroundStyle(BetaTheme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(BetaTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(BetaTheme.border, lineWidth: 1)
                    }
            }
        }
        .padding(16)
        .background(BetaTheme.sectionSurface)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(BetaTheme.sectionStroke, lineWidth: 1)
        }
        .shadow(color: BetaTheme.shadow, radius: 18, x: 0, y: 10)
        .padding(.horizontal)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .onAppear {
            reloadDraft()
        }
        .onChange(of: date) { _, _ in
            persistDraftIfNeeded()
            reloadDraft()
        }
        .onChange(of: vitals?.id) { _, _ in
            if focusedField == nil {
                reloadDraft()
            } else {
                persistedDraft = draft
            }
        }
        .onChange(of: weightUnit) { _, _ in
            persistDraftIfNeeded()
            reloadDraft()
        }
        .onChange(of: glucoseUnitRaw) { _, _ in
            persistDraftIfNeeded()
            reloadDraft()
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue != nil && oldValue != newValue {
                persistDraftIfNeeded()
            }
        }
        .onDisappear {
            persistDraftIfNeeded()
        }
    }

    private func reloadDraft() {
        let nextDraft = VitalsDraft(vitals: vitals, weightUnit: weightUnit, glucoseUnit: glucoseUnit)
        draft = nextDraft
        persistedDraft = nextDraft
    }

    private func visibilityBinding(get: @escaping () -> Bool, set: @escaping (Bool) -> Void) -> Binding<Bool> {
        Binding {
            get()
        } set: { newValue in
            focusedField = nil
            persistDraftIfNeeded()
            set(newValue)
        }
    }

    private func persistDraftIfNeeded() {
        guard draft != persistedDraft else { return }
        guard vitals != nil || !draft.isEmpty else {
            persistedDraft = draft
            return
        }

        let target: DailyVitals
        if let vitals {
            target = vitals
        } else {
            target = DailyVitals(date: date)
            modelContext.insert(target)
        }

        target.date = Calendar.current.startOfDay(for: date)
        draft.apply(to: target, weightUnit: weightUnit, glucoseUnit: glucoseUnit)
        persistedDraft = draft
    }
}

private enum BetaVitalField: Hashable {
    case weight
    case systolic
    case diastolic
    case heartRate
    case glucose
}

private struct BetaVitalTile<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let content: Content

    init(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.16))
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 6) {
                Text("\(title) · \(subtitle)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(BetaTheme.textSecondary)

                content
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(BetaTheme.card)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(BetaTheme.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: BetaTheme.shadow.opacity(0.75), radius: 10, x: 0, y: 5)
        .accessibilityElement(children: .contain)
        .accessibilityHint(subtitle)
    }
}

private struct BetaDoseTile: View {
    let event: DoseEvent

    private enum Layout {
        static let doseWidth: CGFloat = 56
        static let timeWidth: CGFloat = 58
        static let statusWidth: CGFloat = 42
        static let injectionWidth: CGFloat = 14
        static let metadataSpacing: CGFloat = 6
        static let metadataWidth: CGFloat = doseWidth + timeWidth + statusWidth + injectionWidth + (metadataSpacing * 3)
    }

    private var drugColor: Color {
        Color(hex: event.drug?.colorHex ?? "#999999")
    }

    private var doseText: String? {
        guard let schedule = event.drug?.schedule else { return nil }
        let amount = schedule.doseAmount.formatted(.number.precision(.fractionLength(0...2)))
        return "\(amount) \(schedule.doseUnit)"
    }

    private var statusLabel: String? {
        switch event.status {
        case .scheduled:
            return nil
        case .taken:
            return "Done"
        case .skipped:
            return "Skip"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(drugColor.opacity(0.78))
                .frame(width: 10, height: 10)

            Text(event.drug?.name ?? "Unknown")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BetaTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: Layout.metadataSpacing) {
                Group {
                    if event.drug?.route == .injection {
                        Image(systemName: "syringe")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(BetaTheme.sage)
                    } else {
                        Color.clear
                    }
                }
                .frame(width: Layout.injectionWidth, alignment: .center)

                Text(doseText ?? "")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BetaTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: Layout.doseWidth, alignment: .trailing)

                Text(event.scheduledAt, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(BetaTheme.textSecondary)
                    .lineLimit(1)
                    .frame(width: Layout.timeWidth, alignment: .trailing)

                BetaDoseStatusTag(label: statusLabel, status: event.status)
                    .frame(width: Layout.statusWidth, alignment: .trailing)
            }
            .frame(width: Layout.metadataWidth, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(BetaTheme.card)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(BetaTheme.border, lineWidth: 1)
        }
        .shadow(color: BetaTheme.shadow.opacity(0.75), radius: 10, x: 0, y: 5)
    }
}

private struct BetaDoseStatusTag: View {
    let label: String?
    let status: DoseStatus

    var body: some View {
        if let label {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(foregroundColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(Capsule())
        } else {
            Color.clear
                .frame(height: 20)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .taken:
            return BetaTheme.deepSage
        case .skipped:
            return BetaTheme.textSecondary
        case .scheduled:
            return .clear
        }
    }

    private var backgroundColor: Color {
        switch status {
        case .taken:
            return BetaTheme.sage.opacity(0.18)
        case .skipped:
            return BetaTheme.sectionTint
        case .scheduled:
            return .clear
        }
    }
}

private struct BetaInlineMonthCalendar: View {
    let displayedMonth: Date
    let selectedDate: Date
    let eventsForDay: (Date) -> [DoseEvent]
    let onPrevMonth: () -> Void
    let onNextMonth: () -> Void
    let onSelectDate: (Date) -> Void

    private let calendar = Calendar.current
    private let weekdaySymbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
    }

    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
    }

    private var firstWeekdayOffset: Int {
        calendar.component(.weekday, from: monthStart) - 1
    }

    var body: some View {
        VStack(spacing: 10) {
            BetaMonthHeaderView(month: monthStart, onPrev: onPrevMonth, onNext: onNextMonth)

            HStack {
                ForEach(weekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(BetaTheme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(0..<firstWeekdayOffset, id: \.self) { _ in
                    Color.clear
                        .aspectRatio(1, contentMode: .fit)
                }

                ForEach(Array(1...daysInMonth), id: \.self) { day in
                    let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
                    Button {
                        onSelectDate(date)
                    } label: {
                        BetaDayCellView(
                            date: date,
                            events: eventsForDay(date),
                            isToday: calendar.isDateInToday(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 2)
        }
        .padding(.vertical, 12)
        .background(BetaTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(BetaTheme.border, lineWidth: 1)
        }
    }
}

private struct BetaMonthHeaderView: View {
    let month: Date
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BetaTheme.deepSage)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(month, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.bold))
                .foregroundStyle(BetaTheme.textPrimary)

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(BetaTheme.deepSage)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }
}

private struct BetaDayCellView: View {
    let date: Date
    let events: [DoseEvent]
    let isToday: Bool
    let isSelected: Bool

    private var uniqueDrugs: [Drug] {
        var seen = Set<UUID>()
        return events.compactMap { event -> Drug? in
            guard let drug = event.drug, seen.insert(drug.id).inserted else { return nil }
            return drug
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 15, weight: isToday || isSelected ? .bold : .regular))
                .foregroundStyle(dayForeground)
                .frame(maxWidth: .infinity)

            if !uniqueDrugs.isEmpty {
                HStack(spacing: 3) {
                    ForEach(Array(uniqueDrugs.prefix(3)), id: \.id) { drug in
                        Circle()
                            .fill(Color(hex: drug.colorHex).opacity(0.8))
                            .frame(width: 5, height: 5)
                    }
                    if uniqueDrugs.count > 3 {
                        Text("+\(uniqueDrugs.count - 3)")
                            .font(.system(size: 8))
                            .foregroundStyle(BetaTheme.textSecondary)
                    }
                }
                .frame(height: 10)
            } else {
                Color.clear.frame(height: 10)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(1)
        .background(dayBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(dayBorder, lineWidth: dayBorderWidth)
        }
    }

    private var dayForeground: Color {
        if isSelected {
            return BetaTheme.forestAccent
        }
        if isToday {
            return BetaTheme.deepSage
        }
        return BetaTheme.textPrimary
    }

    private var dayBackground: Color {
        return .clear
    }

    private var dayBorder: Color {
        if isSelected {
            return BetaTheme.forestAccent
        }
        if isToday {
            return BetaTheme.sage.opacity(0.9)
        }
        return .clear
    }

    private var dayBorderWidth: CGFloat {
        if isSelected {
            return 3
        }
        if isToday {
            return 1.4
        }
        return 0
    }
}

#Preview {
    NavigationStack {
        BetaDailyView()
    }
}
