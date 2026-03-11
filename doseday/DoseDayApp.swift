//
//  DoseDayApp.swift
//  DoseDay
//
//  Created by Brett on 2026-03-09.
//

import SwiftUI
import SwiftData

@main
struct DoseDayApp: App {
    @AppStorage("symptomTagsSeeded") private var symptomTagsSeeded = false
    @AppStorage("testDataSeeded") private var testDataSeeded = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MedicationProtocol.self,
            Drug.self,
            DoseEvent.self,
            DailyVitals.self,
            DailyNote.self,
            LabResult.self,
            SymptomTag.self,
            DailySymptom.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await seedSystemTagsIfNeeded()
                    await seedTestDataIfNeeded()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func seedSystemTagsIfNeeded() async {
        guard !symptomTagsSeeded else { return }
        let context = sharedModelContainer.mainContext
        for (index, tag) in SymptomTag.systemTags.enumerated() {
            let t = SymptomTag(name: tag.name, colorHex: tag.colorHex, isSystem: true, sortOrder: index)
            context.insert(t)
        }
        try? context.save()
        symptomTagsSeeded = true
    }

    @MainActor
    private func seedTestDataIfNeeded() async {
        guard !testDataSeeded else { return }
        let context = sharedModelContainer.mainContext
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let startDate = cal.date(byAdding: .day, value: -35, to: today) else { return }

        // 1. Protocol
        let proto = MedicationProtocol(name: "Current Protocol", startDate: startDate, colorHex: "#007AFF")
        context.insert(proto)

        // 2. Helper to build a Drug
        func makeDrug(
            name: String,
            route: DrugRoute,
            colorHex: String,
            doseAmount: Double,
            doseUnit: String,
            halfLifeHours: Double,
            schedule: ScheduleDefinition
        ) -> Drug {
            let data = (try? schedule.encoded()) ?? Data()
            let drug = Drug(
                name: name,
                route: route,
                colorHex: colorHex,
                doseUnit: doseUnit,
                halfLifeHours: halfLifeHours,
                scheduleData: data
            )
            drug.protocol = proto
            context.insert(drug)
            return drug
        }

        // 3. Five compounds
        let tirzepatide = makeDrug(
            name: "Tirzepatide",
            route: .injection,
            colorHex: "#34C759",
            doseAmount: 5,
            doseUnit: "mg",
            halfLifeHours: 168,
            schedule: ScheduleDefinition(
                frequencyType: .everyNDays,
                times: [LocalTime(hour: 9, minute: 0)],
                intervalDays: 7,
                weekdays: nil,
                doseAmount: 5,
                doseUnit: "mg"
            )
        )

        let testosterone = makeDrug(
            name: "Testosterone Cypionate",
            route: .injection,
            colorHex: "#007AFF",
            doseAmount: 100,
            doseUnit: "mg",
            halfLifeHours: 192,
            schedule: ScheduleDefinition(
                frequencyType: .specificDays,
                times: [LocalTime(hour: 9, minute: 0)],
                intervalDays: nil,
                weekdays: [2, 5],  // Mon, Thu
                doseAmount: 100,
                doseUnit: "mg"
            )
        )

        let glutathione = makeDrug(
            name: "Glutathione",
            route: .injection,
            colorHex: "#FF9500",
            doseAmount: 600,
            doseUnit: "mg",
            halfLifeHours: 2,
            schedule: ScheduleDefinition(
                frequencyType: .specificDays,
                times: [LocalTime(hour: 9, minute: 0)],
                intervalDays: nil,
                weekdays: [2, 4, 6],  // Mon, Wed, Fri
                doseAmount: 600,
                doseUnit: "mg"
            )
        )

        let cialis = makeDrug(
            name: "Cialis",
            route: .oral,
            colorHex: "#AF52DE",
            doseAmount: 5,
            doseUnit: "mg",
            halfLifeHours: 17,
            schedule: ScheduleDefinition(
                frequencyType: .daily,
                times: [LocalTime(hour: 8, minute: 0)],
                intervalDays: nil,
                weekdays: nil,
                doseAmount: 5,
                doseUnit: "mg"
            )
        )

        let telmisartan = makeDrug(
            name: "Telmisartan",
            route: .oral,
            colorHex: "#FF3B30",
            doseAmount: 40,
            doseUnit: "mg",
            halfLifeHours: 24,
            schedule: ScheduleDefinition(
                frequencyType: .daily,
                times: [LocalTime(hour: 8, minute: 0)],
                intervalDays: nil,
                weekdays: nil,
                doseAmount: 40,
                doseUnit: "mg"
            )
        )

        // 4. Historical dose events (startDate ..< today)
        let pastInterval = DateInterval(start: startDate, end: today)
        let service = SchedulingService()
        srand48(42)
        for drug in [tirzepatide, testosterone, glutathione, cialis, telmisartan] {
            let events = service.generateDoseEvents(for: drug, in: pastInterval, existingEvents: [])
            for event in events {
                let r = drand48()
                if r < 0.85 {
                    event.status = .taken
                    event.takenAt = event.scheduledAt.addingTimeInterval(Double.random(in: 0...1800))
                } else if r < 0.90 {
                    event.status = .skipped
                }
                // else leave as .scheduled (missed)
                event.drug = drug
                context.insert(event)
            }
        }

        // 5. DailyVitals — past 30 days, ~20 of 30 days
        for i in 0..<30 {
            guard i % 3 != 2 else { continue }  // skip every 3rd day
            let daysAgo = 29 - i
            guard let date = cal.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let progress = Double(i) / 29.0
            let v = DailyVitals(date: date)
            v.systolicBP  = Int(138 - progress * 14) + (i % 7) - 3
            v.diastolicBP = Int(88  - progress * 10) + (i % 5) - 2
            v.restingHR   = Int(68  + sin(Double(i)) * 4)
            v.glucoseValue = 92.0 + Double((i * 7) % 17) - 5.0
            v.glucoseUnit  = .mgdL
            context.insert(v)
        }

        try? context.save()
        testDataSeeded = true
    }
}
