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
    @AppStorage("testLabDataSeeded") private var testLabDataSeeded = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            MedicationProtocol.self,
            Drug.self,
            DoseEvent.self,
            DailyVitals.self,
            DailyNote.self,
            LabReport.self,
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
                    await seedTestLabDataIfNeeded()
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
            reconstitutionAmount: Double? = nil,
            reconstitutionDiluentML: Double? = nil,
            schedule: ScheduleDefinition
        ) -> Drug {
            let data = (try? schedule.encoded()) ?? Data()
            let drug = Drug(
                name: name,
                route: route,
                colorHex: colorHex,
                doseUnit: doseUnit,
                halfLifeHours: halfLifeHours,
                reconstitutionAmount: reconstitutionAmount,
                reconstitutionDiluentML: reconstitutionDiluentML,
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
            reconstitutionAmount: 30,
            reconstitutionDiluentML: 3,
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
            reconstitutionAmount: 200,
            reconstitutionDiluentML: 1,
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
            reconstitutionAmount: 1200,
            reconstitutionDiluentML: 1,
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

    @MainActor
    private func seedTestLabDataIfNeeded() async {
        guard !testLabDataSeeded else { return }
        let context = sharedModelContainer.mainContext
        let existingReports = (try? context.fetch(FetchDescriptor<LabReport>()))?.count ?? 0
        let existingResults = (try? context.fetch(FetchDescriptor<LabResult>()))?.count ?? 0
        guard existingReports == 0 && existingResults == 0 else {
            testLabDataSeeded = true
            return
        }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        func makeReport(
            daysAgo: Int,
            title: String,
            source: String,
            sourceType: LabSourceType,
            filename: String,
            results: [(name: String, value: Double, unit: String, low: Double?, high: Double?)]
        ) {
            guard let collectedAt = cal.date(byAdding: .day, value: -daysAgo, to: today) else { return }
            let report = LabReport(
                collectedAt: collectedAt,
                sourceName: source,
                sourceType: sourceType,
                reportTitle: title,
                originalFilename: filename,
                importedAt: Date()
            )
            context.insert(report)

            for item in results {
                let result = LabResult(
                    date: collectedAt,
                    testName: item.name,
                    value: item.value,
                    unit: item.unit,
                    referenceRangeLow: item.low,
                    referenceRangeHigh: item.high,
                    report: report
                )
                context.insert(result)
            }
        }

        makeReport(
            daysAgo: 28,
            title: "Hormone Panel",
            source: "Optimize Labs",
            sourceType: .pdfImport,
            filename: "hormone-panel-mar.pdf",
            results: [
                ("Total Testosterone", 912, "ng/dL", 250, 1100),
                ("Free Testosterone", 27.8, "pg/mL", 8.7, 25.1),
                ("Estradiol", 52, "pg/mL", 10, 40),
                ("SHBG", 24, "nmol/L", 10, 57),
            ]
        )

        makeReport(
            daysAgo: 14,
            title: "CBC",
            source: "Dynacare",
            sourceType: .portalImport,
            filename: "cbc-mar.csv",
            results: [
                ("Hematocrit", 51.8, "%", 38.8, 50.0),
                ("Hemoglobin", 17.1, "g/dL", 13.2, 16.6),
                ("PSA", 0.8, "ng/mL", 0, 4.0),
            ]
        )

        makeReport(
            daysAgo: 5,
            title: "Metabolic Panel",
            source: "LifeLabs",
            sourceType: .photoImport,
            filename: "cmp-photo.jpg",
            results: [
                ("TSH", 1.7, "mIU/L", 0.4, 4.0),
                ("Cortisol", 15.2, "mcg/dL", 6.0, 18.4),
            ]
        )

        try? context.save()
        testLabDataSeeded = true
    }
}
