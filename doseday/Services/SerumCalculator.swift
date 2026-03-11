import Foundation

struct SerumDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let level: Double
    let drugId: UUID
    let colorHex: String
}

struct SerumCalculator {
    /// Computes exponential-decay serum level estimates for a drug over a date interval.
    /// Samples every 1 h for ≤30-day ranges, every 3 h for longer ranges.
    func calculate(for drug: Drug, events: [DoseEvent], in interval: DateInterval) -> [SerumDataPoint] {
        guard drug.halfLifeHours > 0 else { return [] }

        let totalHours = interval.duration / 3600
        let sampleHours: Double = totalHours <= 30 * 24 ? 1 : 3
        let sampleSeconds = sampleHours * 3600

        let takenEvents = events.filter { $0.drug?.id == drug.id && $0.status == .taken }
        let doseAmount = drug.schedule?.doseAmount ?? 1.0

        var points: [SerumDataPoint] = []
        var t = interval.start

        while t <= interval.end {
            var level = 0.0
            for event in takenEvents {
                let doseTime = event.takenAt ?? event.scheduledAt
                guard doseTime <= t else { continue }
                let hours = t.timeIntervalSince(doseTime) / 3600
                level += doseAmount * pow(0.5, hours / drug.halfLifeHours)
            }
            if level > 1e-6 {
                points.append(SerumDataPoint(date: t, level: level, drugId: drug.id, colorHex: drug.colorHex))
            }
            guard let next = Calendar.current.date(byAdding: .second, value: Int(sampleSeconds), to: t) else { break }
            t = next
        }

        return points
    }
}
