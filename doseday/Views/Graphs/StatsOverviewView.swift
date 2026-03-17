import SwiftUI
import SwiftData

struct StatsOverviewView: View {
    @Query private var allEvents: [DoseEvent]
    @Query(sort: \DailyVitals.date, order: .reverse) private var allVitals: [DailyVitals]
    @Query(sort: \LabResult.date, order: .reverse) private var allLabResults: [LabResult]
    @Query(sort: \DailySymptom.date, order: .reverse) private var allSymptoms: [DailySymptom]
    @Query private var allDrugs: [Drug]

    let onOpenCompare: () -> Void
    let onOpenLabs: () -> Void

    private var recentDoseEvents: [DoseEvent] {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allEvents.filter { $0.scheduledAt >= start }
    }

    private var recentAbnormalLabs: [LabResult] {
        Array(allLabResults.filter(\.isOutOfRange).prefix(3))
    }

    private var recentSymptoms: [DailySymptom] {
        let start = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return allSymptoms.filter { $0.date >= start }
    }

    private var adherenceText: String {
        let total = recentDoseEvents.count
        guard total > 0 else { return "No recent doses" }
        let taken = recentDoseEvents.filter { $0.status == .taken }.count
        let pct = Int((Double(taken) / Double(total) * 100).rounded())
        return "\(pct)% over 30 days"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                overviewCards

                if let latestVitals = allVitals.first {
                    latestVitalsSection(latestVitals)
                }

                if !recentAbnormalLabs.isEmpty {
                    recentAbnormalLabsSection
                }

                if !recentSymptoms.isEmpty {
                    recentSymptomsSection
                }
            }
            .padding()
        }
    }

    private var overviewCards: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                OverviewCard(
                    title: "Adherence",
                    value: adherenceText,
                    systemImage: "checkmark.circle",
                    tint: .green,
                    action: onOpenCompare
                )
                OverviewCard(
                    title: "Compounds",
                    value: "\(allDrugs.count) tracked",
                    systemImage: "pills",
                    tint: .blue,
                    action: onOpenCompare
                )
                OverviewCard(
                    title: "Abnormal Labs",
                    value: recentAbnormalLabs.isEmpty ? "None recent" : "\(recentAbnormalLabs.count) recent",
                    systemImage: "testtube.2",
                    tint: .orange,
                    action: onOpenLabs
                )
                OverviewCard(
                    title: "Symptoms",
                    value: recentSymptoms.isEmpty ? "Quiet" : "\(recentSymptoms.count) in 14 days",
                    systemImage: "waveform.path.ecg",
                    tint: .pink,
                    action: onOpenCompare
                )
            }
        }
    }

    private func latestVitalsSection(_ vitals: DailyVitals) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Latest Vitals")
                    .font(.headline)
                Spacer()
                Button("Open Compare", action: onOpenCompare)
                    .font(.subheadline.weight(.semibold))
            }

            VStack(alignment: .leading, spacing: 8) {
                if let weightKg = vitals.weightKg {
                    Text("Weight: \(weightKg.formatted(.number.precision(.fractionLength(1)))) kg")
                }
                if let systolicBP = vitals.systolicBP, let diastolicBP = vitals.diastolicBP {
                    Text("Blood Pressure: \(systolicBP)/\(diastolicBP) mmHg")
                }
                if let restingHR = vitals.restingHR {
                    Text("Resting HR: \(restingHR) bpm")
                }
                if let glucoseValue = vitals.glucoseValue {
                    Text("Glucose: \(glucoseValue.formatted(.number.precision(.fractionLength(1)))) \(vitals.glucoseUnit.displayName)")
                }
            }
            .font(.subheadline)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var recentAbnormalLabsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Abnormal Labs")
                    .font(.headline)
                Spacer()
                Button("View Labs", action: onOpenLabs)
                    .font(.subheadline.weight(.semibold))
            }

            ForEach(recentAbnormalLabs) { result in
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.testName)
                        .font(.subheadline.weight(.semibold))
                    Text("\(result.value.formatted(.number.precision(.fractionLength(1)))) \(result.unit)")
                        .font(.subheadline)
                    Text(result.date.formatted(.dateTime.month(.abbreviated).day().year()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private var recentSymptomsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Symptoms")
                    .font(.headline)
                Spacer()
                Button("Open Compare", action: onOpenCompare)
                    .font(.subheadline.weight(.semibold))
            }

            ForEach(recentSymptoms.prefix(5)) { symptom in
                HStack {
                    Circle()
                        .fill(Color(hex: symptom.tag?.colorHex ?? "#8E8E93"))
                        .frame(width: 8, height: 8)
                    Text(symptom.tag?.name ?? "Unknown")
                    Spacer()
                    Text(symptom.date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
            }
        }
    }
}

private struct OverviewCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(value)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
            .padding()
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
